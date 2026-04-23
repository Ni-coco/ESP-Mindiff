from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.services import meal_suggestions as service

router = APIRouter(prefix="/user", tags=["dashboard"])


@router.get("/{user_id}/dashboard/meal-suggestions")
def get_meal_suggestions(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Retourne les suggestions de repas pour combler l'objectif calorique journalier.
    Calcule le TDEE, soustrait les calories déjà consommées aujourd'hui,
    et appelle Edamam Recipe Search pour les slots repas restants.
    """
    # Check if user exists first
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")
    try:
        return service.get_meal_suggestions(db, user_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
