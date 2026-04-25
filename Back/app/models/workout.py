from __future__ import annotations

import datetime
from typing import TYPE_CHECKING

import sqlalchemy.orm as sqlo
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint

from app.db.database import Base

if TYPE_CHECKING:
    from app.models.exercise import Exercise


class WorkoutWeek(Base):
    __tablename__ = "workout_week"

    id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    user_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    year: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    week_number: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    goal: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    sessions_per_week: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    is_pinned: sqlo.Mapped[bool] = sqlo.mapped_column(
        Boolean, nullable=False, default=False
    )
    created_at: sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(
        DateTime,
        nullable=False,
        default=lambda: datetime.datetime.now(datetime.UTC),
    )

    __table_args__ = (
        UniqueConstraint("user_id", "year", "week_number", name="uq_workout_week_user"),
    )

    sessions: sqlo.Mapped[list[WorkoutSession]] = sqlo.relationship(
        back_populates="workout_week",
        cascade="all, delete-orphan",
        order_by="WorkoutSession.session_number",
    )


class WorkoutSession(Base):
    __tablename__ = "workout_session"

    id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    workout_week_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("workout_week.id", ondelete="CASCADE"), nullable=False
    )
    session_number: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    split_name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    duration_minutes: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)

    workout_week: sqlo.Mapped[WorkoutWeek] = sqlo.relationship(
        back_populates="sessions"
    )
    exercises: sqlo.Mapped[list[WorkoutSessionExercise]] = sqlo.relationship(
        back_populates="session",
        cascade="all, delete-orphan",
        order_by="WorkoutSessionExercise.position",
    )


class WorkoutSessionExercise(Base):
    __tablename__ = "workout_session_exercise"

    id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    session_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("workout_session.id", ondelete="CASCADE"), nullable=False
    )
    exercise_id: sqlo.Mapped[str] = sqlo.mapped_column(
        String, ForeignKey("exercise.id"), nullable=False
    )
    position: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    sets: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    reps_min: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    reps_max: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    is_cardio: sqlo.Mapped[bool] = sqlo.mapped_column(
        Boolean, nullable=False, default=False
    )

    session: sqlo.Mapped[WorkoutSession] = sqlo.relationship(back_populates="exercises")
    exercise: sqlo.Mapped["Exercise"] = sqlo.relationship()  # type: ignore[name-defined]


class CustomWorkout(Base):
    __tablename__ = "custom_workout"

    id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    user_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    created_at: sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(
        DateTime,
        nullable=False,
        default=lambda: datetime.datetime.now(datetime.UTC),
    )

    exercises: sqlo.Mapped[list[CustomWorkoutExercise]] = sqlo.relationship(
        back_populates="custom_workout",
        cascade="all, delete-orphan",
        order_by="CustomWorkoutExercise.position",
    )


class CustomWorkoutExercise(Base):
    __tablename__ = "custom_workout_exercise"

    id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    custom_workout_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("custom_workout.id", ondelete="CASCADE"), nullable=False
    )
    exercise_id: sqlo.Mapped[str] = sqlo.mapped_column(
        String, ForeignKey("exercise.id"), nullable=False
    )
    position: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    sets: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    reps_min: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    reps_max: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)

    custom_workout: sqlo.Mapped[CustomWorkout] = sqlo.relationship(
        back_populates="exercises"
    )
    exercise: sqlo.Mapped["Exercise"] = sqlo.relationship()  # type: ignore[name-defined]
