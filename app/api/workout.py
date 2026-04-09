from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.workout import CustomWorkoutCreate, CustomWorkoutOut, WorkoutWeekOut
from app.services import workout as service

router = APIRouter(prefix="/user", tags=["workout"])


def _check_access(current_user: User, user_id: int) -> None:
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")


@router.get("/{user_id}/workout/current", response_model=WorkoutWeekOut)
def get_current_workout(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Retourne le workout de la semaine (le génère si inexistant)."""
    _check_access(current_user, user_id)
    goal = current_user.sport_objective
    sessions = current_user.sessions_per_week or 3
    return service.get_or_generate_current_week(db, user_id, goal, sessions)


@router.post("/{user_id}/workout/current/pin", response_model=WorkoutWeekOut)
def pin_workout(
    user_id: int,
    workout_week_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Épingle le plan de la semaine pour qu'il ne soit pas écrasé."""
    _check_access(current_user, user_id)
    ww = service.pin_workout_week(db, workout_week_id, user_id)
    if not ww:
        raise HTTPException(status_code=404, detail="Workout introuvable")
    return ww


@router.post("/{user_id}/workout/regenerate", response_model=WorkoutWeekOut)
def regenerate_workout(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Force un nouveau plan pour la semaine (ignoré si le plan est épinglé)."""
    _check_access(current_user, user_id)
    goal = current_user.sport_objective
    sessions = current_user.sessions_per_week or 3
    return service.regenerate_workout_week(db, user_id, goal, sessions)


@router.get("/{user_id}/workout/custom", response_model=list[CustomWorkoutOut])
def list_custom_workouts(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    _check_access(current_user, user_id)
    return service.list_custom_workouts(db, user_id)


@router.post("/{user_id}/workout/custom", response_model=CustomWorkoutOut, status_code=201)
def create_custom_workout(
    user_id: int,
    body: CustomWorkoutCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    _check_access(current_user, user_id)
    return service.create_custom_workout(
        db, user_id, body.name, [e.model_dump() for e in body.exercises]
    )


@router.delete("/{user_id}/workout/custom/{workout_id}", status_code=204)
def delete_custom_workout(
    user_id: int,
    workout_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    _check_access(current_user, user_id)
    if not service.delete_custom_workout(db, workout_id, user_id):
        raise HTTPException(status_code=404, detail="Workout introuvable")
