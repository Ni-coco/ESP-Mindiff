from __future__ import annotations

import sqlalchemy.orm as sqlo
from sqlalchemy import Boolean, ForeignKey, Integer, String

from app.db.database import Base


class Instruction(Base):
    __tablename__ = "instruction"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, autoincrement=True)
    exercise_id: sqlo.Mapped[str] = sqlo.mapped_column(String, ForeignKey("exercise.id", ondelete="CASCADE"), nullable=False)
    step_order: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    text: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)

    exercise: sqlo.Mapped[Exercise] = sqlo.relationship(back_populates="instructions")


class SecondaryMuscle(Base):
    __tablename__ = "secondary_muscle"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, autoincrement=True)
    exercise_id: sqlo.Mapped[str] = sqlo.mapped_column(String, ForeignKey("exercise.id", ondelete="CASCADE"), nullable=False)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)

    exercise: sqlo.Mapped[Exercise] = sqlo.relationship(back_populates="secondary_muscles")


class Exercise(Base):
    __tablename__ = "exercise"

    id: sqlo.Mapped[str] = sqlo.mapped_column(String, primary_key=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    body_part: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True, index=True)
    equipment: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    gif_url: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    target: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True, index=True)
    analyzer_key: sqlo.Mapped[str | None] = sqlo.mapped_column(String(32), nullable=True)

    instructions: sqlo.Mapped[list[Instruction]] = sqlo.relationship(
        back_populates="exercise", cascade="all, delete-orphan", order_by="Instruction.step_order"
    )
    secondary_muscles: sqlo.Mapped[list[SecondaryMuscle]] = sqlo.relationship(
        back_populates="exercise", cascade="all, delete-orphan"
    )
