from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user, get_db
from app.schemas import program as schemas
from app.services import program as service

router = APIRouter(
    prefix="/program", tags=["Program"], dependencies=[Depends(get_current_active_user)]
)


@router.get("/", response_model=list[schemas.ProgramResponse])
def list_programs(db: Session = Depends(get_db)):
    """
    Get a list of programs
    """
    return service.list_programs(db=db)


@router.post("/", response_model=schemas.ProgramResponse)
def create_program(program: schemas.ProgramCreate, db: Session = Depends(get_db)):
    """
    Create a new program
    """
    return service.create_program(db=db, program=program)


@router.get("/{program_id}", response_model=schemas.ProgramResponse | None)
def get_program(program_id: int, db: Session = Depends(get_db)):
    """
    Get a program by ID
    """
    return service.get_program(db=db, program_id=program_id)


@router.put("/{program_id}", response_model=schemas.ProgramResponse | None)
def update_program(
    program_id: int, program: schemas.ProgramUpdate, db: Session = Depends(get_db)
):
    """
    Update a program by ID
    """
    return service.update_program(db=db, program_id=program_id, program=program)


@router.delete("/{program_id}", response_model=dict)
def delete_program(program_id: int, db: Session = Depends(get_db)):
    """
    Delete a program by ID
    """
    success = service.delete_program(db=db, program_id=program_id)
    if not success:
        return {"error": "Program not found"}
    return {"message": "Program deleted successfully"}
