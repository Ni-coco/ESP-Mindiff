from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_db
from app.schemas import user as schemas
from app.services import user as service
from app.core.dependencies import get_current_active_user

router = APIRouter(
    prefix="/user",
    tags=["User"],
    dependencies=[Depends(get_current_active_user)]
)


@router.get("/", response_model=List[schemas.UserResponse])
def list_users(db: Session = Depends(get_db)):
    """
    Get a list of users
    """
    return service.get_users(
        db=db
    )


@router.post("/", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """
    Create a new user
    """
    return service.create_user(
        db=db,
        user=user
    )


@router.get("/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    """
    Get a user by ID
    """
    return service.get_user(
        db=db,
        user_id=user_id
    )


@router.put("/{user_id}", response_model=schemas.UserResponse)
def update_user(user_id: int, user: schemas.UserUpdate, db: Session = Depends(get_db)):
    """
    Update a user by ID
    """
    return service.update_user(
        db=db,
        user_id=user_id,
        user=user
    )


@router.delete("/{user_id}", response_model=schemas.UserResponse)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    """
    Delete a user by ID
    """
    return service.delete_user(
        db=db,
        user_id=user_id
    )