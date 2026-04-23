import datetime

import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.meal import AddMealRequest, DailyMealsResponse, MealResponse
from app.services import edamam
from app.services import meal_log as service

router = APIRouter(prefix="/user", tags=["meals"])


@router.post("/{user_id}/meals", response_model=MealResponse)
def add_meal(
    user_id: int,
    body: AddMealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")

    if body.calories is not None:
        nutrition = {
            "calories": body.calories,
            "protein_g": body.protein_g or 0.0,
            "fat_g": body.fat_g or 0.0,
            "carbs_g": body.carbs_g or 0.0,
            "fiber_g": body.fiber_g or 0.0,
        }
    else:
        try:
            nutrition = edamam.analyze_nutrition(body.description)
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=503, detail=f"Erreur Edamam : {e.response.text}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=503, detail=f"Erreur interne : {type(e).__name__}: {e}"
            )

    entry = service.add_meal(
        db=db,
        user_id=user_id,
        date=body.date or datetime.date.today(),
        meal_type=body.meal_type,
        description=body.description,
        **nutrition,
    )
    return entry


@router.get("/{user_id}/meals", response_model=DailyMealsResponse)
def get_meals(
    user_id: int,
    date: datetime.date | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")

    target_date = date or datetime.date.today()
    meals = service.get_meals_by_date(db, user_id, target_date)

    return DailyMealsResponse(
        date=target_date,
        meals=meals,
        total_calories=round(sum(m.calories for m in meals), 1),
        total_protein_g=round(sum(m.protein_g for m in meals), 1),
        total_fat_g=round(sum(m.fat_g for m in meals), 1),
        total_carbs_g=round(sum(m.carbs_g for m in meals), 1),
        total_fiber_g=round(sum(m.fiber_g for m in meals), 1),
    )


@router.delete("/{user_id}/meals/{meal_id}", status_code=204)
def delete_meal(
    user_id: int,
    meal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")

    if not service.delete_meal(db, meal_id, user_id):
        raise HTTPException(status_code=404, detail="Repas introuvable")
