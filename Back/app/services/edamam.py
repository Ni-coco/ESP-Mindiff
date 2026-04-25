import httpx
from app.core.config import settings


def analyze_nutrition(text: str) -> dict:
    """
    Envoie le texte libre à l'API Edamam Nutrition Analysis.
    Chaque ligne est traitée comme un ingrédient distinct.
    Retourne calories, protein_g, fat_g, carbs_g, fiber_g.
    """
    ingredients = [line.strip() for line in text.splitlines() if line.strip()]
    if not ingredients:
        return {"calories": 0, "protein_g": 0, "fat_g": 0, "carbs_g": 0, "fiber_g": 0}

    response = httpx.post(
        settings.EDAMAM_NUTRITION_URL,
        params={"app_id": settings.EDAMAM_APP_ID, "app_key": settings.EDAMAM_APP_KEY},
        json={"title": "meal", "ingr": ingredients},
        timeout=15,
    )

    # 555 = low_quality : Edamam a quand même des données partielles, on les accepte
    if response.status_code not in (200, 555):
        response.raise_for_status()

    data = response.json()
    if "ingredients" not in data:
        raise ValueError(f"Réponse Edamam inattendue : {data}")

    # Agrège les nutriments depuis ingredients[].parsed[].nutrients
    totals: dict[str, float] = {
        "ENERC_KCAL": 0,
        "PROCNT": 0,
        "FAT": 0,
        "CHOCDF": 0,
        "FIBTG": 0,
    }
    for ingredient in data.get("ingredients", []):
        for parsed in ingredient.get("parsed", []):
            for key in totals:
                totals[key] += (
                    parsed.get("nutrients", {}).get(key, {}).get("quantity", 0)
                )

    return {
        "calories": round(totals["ENERC_KCAL"], 1),
        "protein_g": round(totals["PROCNT"], 1),
        "fat_g": round(totals["FAT"], 1),
        "carbs_g": round(totals["CHOCDF"], 1),
        "fiber_g": round(totals["FIBTG"], 1),
    }
