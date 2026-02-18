from typing import Optional

from sqlalchemy.orm import Session

from app.models.program import Program
from app.schemas.program import ProgramCreate, ProgramUpdate


def list_programs(db: Session) -> list[type[Program]]:
    """Get all programs."""
    return db.query(Program).all()


def get_program(db: Session, program_id: int) -> Optional[type[Program]]:
    """Get a program by its ID."""
    return db.query(Program).filter(Program.id == program_id).first()


def create_program(db: Session, program: ProgramCreate) -> Program:
    """Create a new program."""
    db_program = Program(
        name=program.name,
        description=program.description,
        difficulty=program.difficulty,
        calorie_burn=program.calorie_burn,
        duration=program.duration
    )
    db.add(db_program)
    db.commit()
    db.refresh(db_program)
    return db_program


def update_program(db: Session, program_id: int, program: ProgramUpdate) -> Optional[type[Program]]:
    """Update an existing program."""
    db_program = get_program(db, program_id)
    if not db_program:
        return None
    db_program.name = program.name
    db_program.description = program.description
    db_program.difficulty = program.difficulty
    db_program.calorie_burn = program.calorie_burn
    db_program.duration = program.duration
    db.commit()
    db.refresh(db_program)
    return db_program


def delete_program(db: Session, program_id: int) -> bool:
    """Delete a program by its ID."""
    db_program = get_program(db, program_id)
    if not db_program:
        return False
    db.delete(db_program)
    db.commit()
    return True