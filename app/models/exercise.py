from __future__ import annotations

from typing import TYPE_CHECKING

import sqlalchemy.orm as sqlo
from sqlalchemy import Column, ForeignKey, Integer, String, Table

from app.db.database import Base

if TYPE_CHECKING:
    from app.models.program import Program


class Instruction(Base):
    __tablename__ = "instruction"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    exercise_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("exercise.id"), nullable=False
    )

    exercise: sqlo.Mapped[Exercise] = sqlo.relationship(back_populates="instructions")


class SecondaryMuscle(Base):
    __tablename__ = "secondary_muscle"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    exercise_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("exercise.id"), nullable=False
    )

    exercise: sqlo.Mapped[Exercise] = sqlo.relationship(
        back_populates="secondary_muscles"
    )


class Exercise(Base):
    __tablename__ = "exercise"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    title: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    equipment: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    gif: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    body_part: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    target: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)

    # Relationships
    instructions: sqlo.Mapped[list[Instruction]] = sqlo.relationship(
        back_populates="exercise", cascade="all, delete-orphan"
    )
    secondary_muscles: sqlo.Mapped[list[SecondaryMuscle]] = sqlo.relationship(
        back_populates="exercise", cascade="all, delete-orphan"
    )
    programs: sqlo.Mapped[list[Program]] = sqlo.relationship(
        "Program",
        secondary="program_exercise",
        back_populates="exercises",
    )


# Defined after Exercise so that the 'exercice' table is already registered
# in Base.metadata before the ForeignKey to it is resolved.
program_exercise = Table(
    "program_exercise",
    Base.metadata,
    Column("program_id", Integer, ForeignKey("program.id"), primary_key=True),
    Column("exercise_id", Integer, ForeignKey("exercise.id"), primary_key=True),
)
