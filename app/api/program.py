from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_db
from app.services import program as service
from app.schemas import program as schemas

router = APIRouter(prefix="/programs", tags=["programs"])


@router.get("/", response_model=list[schemas.ProgramResponse])
def list_programs(db: Session = Depends(get_db)):
    """
    Get a list of programs
    """
    return service.list_programs(
        db=db
    )


@router.post("/", response_model=schemas.ProgramResponse)
def create_program(program: schemas.ProgramCreate, db: Session = Depends(get_db)):
    """
    Create a new program
    """
    return service.create_program(
        db=db,
        program=program
    )


@router.get("/{program_id}", response_model=schemas.ProgramResponse)
def get_program(program_id: int, db: Session = Depends(get_db)):
    """
    Get a program by ID
    """
    return service.get_program(
        db=db,
        program_id=program_id
    )