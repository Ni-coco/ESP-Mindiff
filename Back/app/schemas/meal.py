import datetime

from pydantic import BaseModel, ConfigDict


class AddMealRequest(BaseModel):
    meal_type: str  # breakfast, lunch, dinner, snack
    description: str
    date: datetime.date | None = None  # défaut = aujourd'hui
    # Macros manuelles (optionnelles) — si fournies, Edamam est ignoré
    calories: float | None = None
    protein_g: float | None = None
    fat_g: float | None = None
    carbs_g: float | None = None
    fiber_g: float | None = None


class MealResponse(BaseModel):
    id: int
    date: datetime.date
    meal_type: str
    description: str
    calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    fiber_g: float

    model_config = ConfigDict(from_attributes=True)


class DailyMealsResponse(BaseModel):
    date: datetime.date
    meals: list[MealResponse]
    total_calories: float
    total_protein_g: float
    total_fat_g: float
    total_carbs_g: float
    total_fiber_g: float
