import datetime
from sqlalchemy.orm import Session
from app.models.user import MealLog


def add_meal(
    db: Session,
    user_id: int,
    date: datetime.date,
    meal_type: str,
    description: str,
    calories: float,
    protein_g: float,
    fat_g: float,
    carbs_g: float,
    fiber_g: float,
) -> MealLog:
    entry = MealLog(
        user_id=user_id,
        date=date,
        meal_type=meal_type,
        description=description,
        calories=calories,
        protein_g=protein_g,
        fat_g=fat_g,
        carbs_g=carbs_g,
        fiber_g=fiber_g,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def get_meals_by_date(db: Session, user_id: int, date: datetime.date) -> list[MealLog]:
    return (
        db.query(MealLog)
        .filter(MealLog.user_id == user_id, MealLog.date == date)
        .order_by(MealLog.created_at)
        .all()
    )


def delete_meal(db: Session, meal_id: int, user_id: int) -> bool:
    entry = db.query(MealLog).filter(MealLog.id == meal_id, MealLog.user_id == user_id).first()
    if not entry:
        return False
    db.delete(entry)
    db.commit()
    return True
