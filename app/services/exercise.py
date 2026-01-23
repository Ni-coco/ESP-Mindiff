from typing import List, Optional, Any
from sqlalchemy.orm import Session

from app.models.exercise import Exercise, Instruction, SecondaryMuscle
from app.schemas.exercise import ExerciseCreate, ExerciseUpdate


def get_exercise(db: Session, exercise_id: int) -> Optional[Exercise]:
    """
    Get an exercise by ID
    """
    return db.query(Exercise).filter(Exercise.id == exercise_id).first()


def get_exercises(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None
) -> List[Exercise]:
    """
    Get a list of exercises with pagination and filters
    """
    query = db.query(Exercise)

    if body_part:
        query = query.filter(Exercise.body_part == body_part)
    if equipment:
        query = query.filter(Exercise.equipment == equipment)
    if target:
        query = query.filter(Exercise.target == target)

    return query.offset(skip).limit(limit).all()


def get_exercises_count(
    db: Session,
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None
) -> int:
    """
    Count exercises with filters
    """
    query = db.query(Exercise)

    if body_part:
        query = query.filter(Exercise.body_part == body_part)
    if equipment:
        query = query.filter(Exercise.equipment == equipment)
    if target:
        query = query.filter(Exercise.target == target)

    return query.count()


def create_exercise(db: Session, exercise: ExerciseCreate) -> Exercise:
    """
    Create a new exercise
    """
    db_exercise = Exercise(
        title=exercise.title,
        description=exercise.description,
        equipment=exercise.equipment,
        gif=exercise.gif,
        body_part=exercise.body_part,
        target=exercise.target
    )

    # Add instructions
    for instruction_data in exercise.instructions:
        instruction = Instruction(description=instruction_data.description)
        db_exercise.instructions.append(instruction)

    # Add secondary muscles
    for muscle_data in exercise.secondary_muscles:
        muscle = SecondaryMuscle(name=muscle_data.name)
        db_exercise.secondary_muscles.append(muscle)

    db.add(db_exercise)
    db.commit()
    db.refresh(db_exercise)
    return db_exercise


def update_exercise(
    db: Session,
    exercise_id: int,
    exercise_update: ExerciseUpdate
) -> Optional[Exercise]:
    """
    Update an exercise
    """
    db_exercise = get_exercise(db, exercise_id)
    if not db_exercise:
        return None

    update_data = exercise_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_exercise, field, value)

    db.commit()
    db.refresh(db_exercise)
    return db_exercise


def delete_exercise(db: Session, exercise_id: int) -> bool:
    """
    Delete an exercise
    """
    db_exercise = get_exercise(db, exercise_id)
    if not db_exercise:
        return False

    db.delete(db_exercise)
    db.commit()
    return True


def filter_exercises(
    db: Session,
    query: str,
    skip: int = 0,
    limit: int = 100
) -> list[type[Exercise]]:
    """
    Filter exercises by search query
    """
    search_pattern = f"%{query}%"
    return db.query(Exercise).filter(
        (Exercise.title.ilike(search_pattern)) |
        (Exercise.description.ilike(search_pattern)) |
        (Exercise.equipment.ilike(search_pattern)) |
        (Exercise.body_part.ilike(search_pattern)) |
        (Exercise.target.ilike(search_pattern))
    ).offset(skip).limit(limit).all()


