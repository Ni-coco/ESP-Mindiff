from typing import List, Optional
from sqlalchemy.orm import Session

from app.models.exercise import Exercise, SecondaryMuscle


def get_exercise(db: Session, exercise_id: str) -> Optional[Exercise]:
    return db.query(Exercise).filter(Exercise.id == exercise_id).first()


def get_exercises(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None,
    secondary_muscle: Optional[str] = None,
) -> List[Exercise]:
    query = db.query(Exercise)
    if body_part:
        query = query.filter(Exercise.body_part == body_part)
    if equipment:
        query = query.filter(Exercise.equipment == equipment)
    if target:
        query = query.filter(Exercise.target == target)
    if secondary_muscle:
        query = query.join(Exercise.secondary_muscles).filter(
            SecondaryMuscle.name == secondary_muscle
        )
    return query.offset(skip).limit(limit).all()


def get_exercises_count(
    db: Session,
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None,
) -> int:
    query = db.query(Exercise)
    if body_part:
        query = query.filter(Exercise.body_part == body_part)
    if equipment:
        query = query.filter(Exercise.equipment == equipment)
    if target:
        query = query.filter(Exercise.target == target)
    return query.count()


def filter_exercises(
    db: Session, query: str, skip: int = 0, limit: int = 100
) -> list[Exercise]:
    pattern = f"%{query}%"
    return (
        db.query(Exercise)
        .filter(
            Exercise.name.ilike(pattern)
            | Exercise.target.ilike(pattern)
            | Exercise.body_part.ilike(pattern)
        )
        .offset(skip)
        .limit(limit)
        .all()
    )
