from sqlalchemy import Integer, String
import sqlalchemy.orm as sqlo

from app.db.database import Base

class Instruction(Base):
    __tablename__ = "instruction"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)


class SecondaryMuscle(Base):
    __tablename__ = "secondary_muscle"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)


class BodyPart(Base):
    __tablename__ = "body_part"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)


class Exercise(Base):
    __tablename__ = "exercise"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    title: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    equipment: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    gif: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)
    target: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=True)

    # Relationships
    instructions: sqlo.Relationship[list[Instruction]] = sqlo.relationship(back_populates="exercise")
    secondary_muscles: sqlo.Relationship[list[SecondaryMuscle]] = sqlo.relationship(back_populates="exercise")
    body_part: sqlo.Relationship[BodyPart] = sqlo.relationship(back_populates="exercise")