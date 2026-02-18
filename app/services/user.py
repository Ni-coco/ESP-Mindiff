from typing import Optional

from pydantic import EmailStr
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate


def get_users(db: Session) -> list[User]:
    """Get all users."""
    return db.query(User).all()


def get_user_by_email(db: Session, email: EmailStr) -> Optional[type[User]]:
    """Get a user by their email."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[type[User]]:
    """Get a user by their username."""
    return db.query(User).filter(User.username == username).first()


def get_user(db: Session, user_id: int) -> Optional[type[User]]:
    """Get a user by their ID."""
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, user: UserCreate) -> User:
    """Create a new user."""
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email, username=user.username, hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user_id: int, user: UserUpdate) -> Optional[User]:
    """Update a user by their ID."""
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    db_user.email = user.email
    db_user.username = user.username
    db_user.hashed_password = get_password_hash(user.password)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, email: EmailStr, password: str) -> Optional[User]:
    """Authenticate a user by their email and password."""
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def delete_user(db: Session, user_id: int) -> Optional[User]:
    """Delete a user by their ID."""
    user = get_user(db, user_id)
    if not user:
        return None
    db.delete(user)
    db.commit()
    return user
