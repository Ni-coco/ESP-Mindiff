from http import HTTPStatus
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_active_user
from app.schemas import exercise as schemas
from app.services import exercise as service

router = APIRouter(
    prefix="/exercise",
    tags=["Exercise"],
    dependencies=[Depends(get_current_active_user)],
)


@router.get("/", response_model=List[schemas.Exercise])
def list_exercise(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get a list of exercises
    """
    exercises = service.get_exercises(
        db=db,
        skip=skip,
        limit=limit,
        body_part=body_part,
        equipment=equipment,
        target=target
    )
    return exercises


@router.get("/count")
def count_exercise(
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get the number of exercises
    """
    count = service.get_exercises_count(
        db=db,
        body_part=body_part,
        equipment=equipment,
        target=target
    )
    return {"count": count}


@router.get("/filter", response_model=List[schemas.Exercise])
def filter_exercise(
    q: str = Query(..., min_length=1),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db)
):
    """
    Filter exercises by search query
    """
    exercises = service.filter_exercises(
        db=db,
        query=q,
        skip=skip,
        limit=limit
    )
    return exercises

@router.get("/{exercise_id}", response_model=schemas.Exercise)
def get_exercise(exercise_id: int, db: Session = Depends(get_db)):
    """
    Get an exercise by ID
    """
    exercise = service.get_exercise(db, exercise_id)
    if not exercise:
        raise HTTPException(status_code=HTTPStatus.NOT_FOUND, detail="Exercise not found")
    return exercise


@router.post("/", response_model=schemas.Exercise, status_code=HTTPStatus.CREATED)
def create_exercise(
    exercise: schemas.ExerciseCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new exercise
    """
    return service.create_exercise(db=db, exercise=exercise)


@router.patch("/{exercise_id}", response_model=schemas.Exercise)
def update_exercise(
    exercise_id: int,
    exercise_update: schemas.ExerciseUpdate,
    db: Session = Depends(get_db)
):
    """
    Update an existing exercise
    """
    exercise = service.update_exercise(db, exercise_id, exercise_update)
    if not exercise:
        raise HTTPException(status_code=HTTPStatus.NOT_FOUND, detail="Exercise not found")
    return exercise


@router.delete("/{exercise_id}", status_code=HTTPStatus.NO_CONTENT)
def delete_exercise(exercise_id: int, db: Session = Depends(get_db)):
    """
    Delete an exercise
    """
    success = service.delete_exercise(db, exercise_id)
    if not success:
        raise HTTPException(status_code=HTTPStatus.NOT_FOUND, detail="Exercise not found")
    return None

