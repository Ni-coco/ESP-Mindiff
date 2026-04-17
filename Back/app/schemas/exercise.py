from typing import List, Optional
from pydantic import BaseModel


class InstructionOut(BaseModel):
    id: int
    step_order: int
    text: str

    model_config = {"from_attributes": True}


class SecondaryMuscleOut(BaseModel):
    id: int
    name: str

    model_config = {"from_attributes": True}


class ExerciseOut(BaseModel):
    id: str
    name: str
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    gif_url: Optional[str] = None
    target: Optional[str] = None
    instructions: List[InstructionOut] = []
    secondary_muscles: List[SecondaryMuscleOut] = []

    model_config = {"from_attributes": True}


class ExerciseShort(BaseModel):
    """Version allégée pour les listes et les workouts."""
    id: str
    name: str
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    gif_url: Optional[str] = None
    target: Optional[str] = None

    model_config = {"from_attributes": True}


# Aliases pour compatibilité avec l'API existante
Exercise = ExerciseOut
ExerciseCreate = ExerciseOut
ExerciseUpdate = ExerciseOut
ExerciseFilter = ExerciseOut
