from __future__ import annotations

from typing import TYPE_CHECKING

import sqlalchemy.orm as sqlo
from sqlalchemy import Integer, String

from app.core.enum import DifficultyLevel
from app.db.database import Base
from app.models.exercise import program_exercise

if TYPE_CHECKING:
    from app.models.exercise import Exercise


class Program(Base):
    __tablename__ = "program"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    difficulty: sqlo.Mapped[DifficultyLevel] = sqlo.mapped_column(String, nullable=True)
    calorie_burn: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=True)
    duration: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=True)

    # Relationships
    exercises: sqlo.Mapped[list[Exercise]] = sqlo.relationship(
        "Exercise",
        secondary=program_exercise,
        back_populates="programs",
    )
