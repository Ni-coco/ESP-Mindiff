from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from app.db.database import Base

class Instruction(Base):
    __tablename__ = "instruction"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, nullable=True)
    exercise_id = Column(Integer, ForeignKey("exercise.id"), nullable=False)


class SecondaryMuscle(Base):
    __tablename__ = "secondary_muscle"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=True)
    exercise_id = Column(Integer, ForeignKey("exercise.id"), nullable=False)


class Exercise(Base):
    __tablename__ = "exercise"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    equipment = Column(String, nullable=True)
    gif = Column(String, nullable=True)
    body_part = Column(String, nullable=False)
    secondary_muscles = relationship("SecondaryMuscle", backref="exercise", cascade="all, delete-orphan")
    instructions = relationship("Instruction", backref="exercise", cascade="all, delete-orphan")
    target = Column(String, nullable=True)