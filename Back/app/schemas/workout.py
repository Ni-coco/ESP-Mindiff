import datetime
from typing import List, Optional
from pydantic import BaseModel

from app.schemas.exercise import ExerciseShort


class WorkoutExerciseOut(BaseModel):
    id: int
    position: int
    sets: int
    reps_min: int
    reps_max: int
    is_cardio: bool
    exercise: ExerciseShort

    model_config = {"from_attributes": True}


class WorkoutSessionOut(BaseModel):
    id: int
    session_number: int
    split_name: str
    duration_minutes: int
    exercises: List[WorkoutExerciseOut] = []

    model_config = {"from_attributes": True}


class WorkoutWeekOut(BaseModel):
    id: int
    year: int
    week_number: int
    goal: Optional[str] = None
    sessions_per_week: int
    is_pinned: bool
    created_at: datetime.datetime
    sessions: List[WorkoutSessionOut] = []

    model_config = {"from_attributes": True}


class CustomWorkoutExerciseIn(BaseModel):
    exercise_id: str
    position: int
    sets: int
    reps_min: int
    reps_max: int


class CustomWorkoutCreate(BaseModel):
    name: str
    exercises: List[CustomWorkoutExerciseIn] = []


class CustomWorkoutExerciseOut(BaseModel):
    id: int
    position: int
    sets: int
    reps_min: int
    reps_max: int
    exercise: ExerciseShort

    model_config = {"from_attributes": True}


class CustomWorkoutOut(BaseModel):
    id: int
    name: str
    created_at: datetime.datetime
    exercises: List[CustomWorkoutExerciseOut] = []

    model_config = {"from_attributes": True}
