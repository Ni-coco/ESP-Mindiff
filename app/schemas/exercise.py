from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class InstructionBase(BaseModel):
    description: Optional[str] = None


class InstructionCreate(InstructionBase):
    pass


class Instruction(InstructionBase):
    id: int
    exercise_id: int

    class Config:
        from_attributes = True


class SecondaryMuscleBase(BaseModel):
    name: Optional[str] = None


class SecondaryMuscleCreate(SecondaryMuscleBase):
    pass


class SecondaryMuscle(SecondaryMuscleBase):
    id: int
    exercise_id: int

    class Config:
        from_attributes = True


class ExerciseBase(BaseModel):
    title: str
    description: Optional[str] = None
    equipment: Optional[str] = None
    gif: Optional[str] = None
    body_part: str
    target: Optional[str] = None


class ExerciseResponse(ExerciseBase):
    id: int


class ExerciseCreate(ExerciseBase):
    instructions: List[InstructionCreate] = []
    secondary_muscles: List[SecondaryMuscleCreate] = []


class ExerciseUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    equipment: Optional[str] = None
    gif: Optional[str] = None
    body_part: Optional[str] = None
    target: Optional[str] = None


class Exercise(ExerciseBase):
    id: int
    instructions: List[Instruction] = []
    secondary_muscles: List[SecondaryMuscle] = []

    class Config:
        from_attributes = True


class ExerciseFilter(BaseModel):
    body_part: List[str] = None
    equipment: List[str] = None
    target: List[str] = None