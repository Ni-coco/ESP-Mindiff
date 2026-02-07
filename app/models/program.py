from sqlalchemy import Integer, String
import sqlalchemy.orm as sqlo

from app.db.database import Base
from app.models.exercise import Exercise
from app.core.enum import DifficultyLevel


class Program(Base):
    __tablename__ = "program"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    difficulty: sqlo.Mapped[DifficultyLevel] = sqlo.mapped_column(String, nullable=True)
    calorie_burn: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=True)
    duration: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=True)

    # Relationships
    exercises: sqlo.Relationship[list[Exercise]] = sqlo.relationship(back_populates="exercise")