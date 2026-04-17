from pydantic import BaseModel, ConfigDict

from app.core.enum import DifficultyLevel
from app.schemas.exercise import Exercise


class Program(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    description: str
    difficulty: DifficultyLevel
    calorie_burn: int
    duration: int
    exercises: list[Exercise]


class ProgramCreate(Program):
    pass


class ProgramUpdate(Program):
    id: int
    pass


class ProgramResponse(Program):
    id: int