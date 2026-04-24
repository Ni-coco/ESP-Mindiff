"""
Service de suggestions de repas basé sur l'objectif calorique journalier du user.

Logique :
  1. Calcul du TDEE via Mifflin-St Jeor × multiplicateur d'activité
  2. Fetch des repas déjà enregistrés aujourd'hui → calories consommées
  3. Calcul des calories restantes et des types de repas non encore loggés
  4. Appel Edamam Recipe Search API par slot repas (petit-déj / déj / dîner / collation)
  5. Retourne les suggestions avec macros
"""

import datetime
import random

import httpx
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user import MealLog, User

# Distribution calorique par slot
MEAL_DISTRIBUTION: dict[str, float] = {
    "breakfast": 0.25,
    "lunch": 0.35,
    "dinner": 0.30,
    "snack": 0.10,
}

# Requêtes Edamam par objectif
_QUERIES: dict[str, list[str]] = {
    "lose_weight": ["chicken salad", "vegetable soup", "grilled fish"],
    "build_muscle": ["chicken rice", "beef steak", "salmon"],
    "increase_strength": ["steak", "tuna pasta", "chicken potato"],
    "improve_endurance": ["pasta", "oatmeal", "rice chicken"],
    "general_fitness": ["chicken", "fish vegetables", "turkey"],
    "maintain": ["chicken", "fish", "pasta"],
}
_DEFAULT_QUERIES = ["chicken", "fish", "pasta"]

# Diet labels Edamam par objectif
_DIET_LABELS: dict[str, str] = {
    "lose_weight": "low-fat",
    "build_muscle": "high-protein",
    "increase_strength": "high-protein",
    "improve_endurance": "balanced",
    "general_fitness": "balanced",
    "maintain": "balanced",
}

# ── TDEE ─────────────────────────────────────────────────────────────────────


def _calculate_tdee(user: User) -> float:
    metrics = user.user_metrics[0] if user.user_metrics else None
    if not metrics:
        return 0.0

    weight = metrics.actual_weight or metrics.weight
    height = float(metrics.height)
    age = float(metrics.age)
    gender = (user.gender or "male").lower()
    sessions = user.sessions_per_week if user.sessions_per_week is not None else 3

    bmr = 10 * weight + 6.25 * height - 5 * age
    bmr += 5 if gender == "male" else -161

    if sessions == 0:
        multiplier = 1.2
    elif sessions <= 2:
        multiplier = 1.375
    elif sessions <= 4:
        multiplier = 1.55
    else:
        multiplier = 1.725

    return round(bmr * multiplier)


# ── Edamam ────────────────────────────────────────────────────────────────────


def _fetch_recipe(query: str, user_id: int, target_cal: int) -> dict | None:
    """
    Appelle Edamam Recipe Search API.
    Filtre par calories totales (target × 2 à target × 6 pour couvrir 2-6 portions).
    Retourne les valeurs PAR PORTION (calories totales ÷ yield).
    """
    cal_min = target_cal * 2
    cal_max = target_cal * 6

    try:
        response = httpx.get(
            settings.EDAMAM_RECIPE_URL,
            params=[
                ("type", "public"),
                ("q", query),
                ("calories", f"{cal_min}-{cal_max}"),
                ("app_id", settings.EDAMAM_MEAL_APP_ID),
                ("app_key", settings.EDAMAM_MEAL_APP_KEY),
                ("field", "label"),
                ("field", "calories"),
                ("field", "yield"),
                ("field", "image"),
                ("field", "url"),
                ("field", "source"),
                ("field", "ingredientLines"),
                ("field", "totalNutrients"),
            ],
            headers={"Edamam-Account-User": str(user_id)},
            timeout=10,
        )

        if response.status_code != 200:
            return None

        hits = response.json().get("hits", [])
        if not hits:
            return None

        # Prend un résultat aléatoire parmi les 5 premiers pour varier
        pick = random.choice(hits[: min(5, len(hits))])
        recipe = pick["recipe"]
        nutrients = recipe.get("totalNutrients", {})
        servings = max(1, recipe.get("yield", 4))

        return {
            "label": recipe.get("label", "Recette"),
            "calories": round(recipe.get("calories", 0) / servings),
            "protein_g": round(
                nutrients.get("PROCNT", {}).get("quantity", 0) / servings, 1
            ),
            "fat_g": round(nutrients.get("FAT", {}).get("quantity", 0) / servings, 1),
            "carbs_g": round(
                nutrients.get("CHOCDF", {}).get("quantity", 0) / servings, 1
            ),
            "fiber_g": round(
                nutrients.get("FIBTG", {}).get("quantity", 0) / servings, 1
            ),
            "servings": servings,
            "image_url": recipe.get("image"),
            "recipe_url": recipe.get("url", ""),
            "source": recipe.get("source", ""),
            "ingredient_lines": recipe.get("ingredientLines", []),
        }
    except Exception:
        return None


# ── Point d'entrée ────────────────────────────────────────────────────────────


def get_meal_suggestions(db: Session, user_id: int) -> dict:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise ValueError("User introuvable")

    tdee = int(_calculate_tdee(user))
    if tdee == 0:
        return {"tdee": 0, "consumed_today": 0, "remaining": 0, "suggestions": []}

    # Calories déjà consommées aujourd'hui
    today = datetime.date.today()
    today_meals = (
        db.query(MealLog)
        .filter(MealLog.user_id == user_id, MealLog.date == today)
        .all()
    )
    consumed = round(sum(m.calories for m in today_meals))
    remaining = max(0, tdee - consumed)

    # Slots pas encore loggés
    logged_types = {m.meal_type for m in today_meals}
    pending_slots = [slot for slot in MEAL_DISTRIBUTION if slot not in logged_types]

    if not pending_slots or remaining <= 0:
        return {
            "tdee": tdee,
            "consumed_today": consumed,
            "remaining": remaining,
            "suggestions": [],
        }

    # Redistribue les proportions sur les slots restants
    total_proportion = sum(MEAL_DISTRIBUTION[s] for s in pending_slots)
    goal = user.sport_objective
    queries = _QUERIES.get(goal or "", _DEFAULT_QUERIES)

    suggestions = []
    for i, slot in enumerate(pending_slots):
        proportion = MEAL_DISTRIBUTION[slot] / total_proportion
        target_cal = max(100, round(remaining * proportion))
        query = queries[i % len(queries)]
        recipe = _fetch_recipe(query, user_id, target_cal)
        if recipe:
            suggestions.append({"meal_type": slot, **recipe})

    return {
        "tdee": tdee,
        "consumed_today": consumed,
        "remaining": remaining,
        "suggestions": suggestions,
    }
