from typing import Optional

from pydantic import EmailStr
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models.user import User, UserMetrics
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

    if user.password:
        db_user.hashed_password = get_password_hash(user.password)

    if user.is_active is not None:
        db_user.is_active = user.is_active
    if user.is_superuser is not None:
        db_user.is_superuser = user.is_superuser

    # Champs profil optionnels
    if user.gender is not None:
        db_user.gender = user.gender
    if user.sport_objective is not None:
        db_user.sport_objective = user.sport_objective
    if user.target_weight is not None:
        db_user.target_weight = user.target_weight
    if user.sessions_per_week is not None:
        db_user.sessions_per_week = user.sessions_per_week
    if user.health_considerations is not None:
        db_user.health_considerations = user.health_considerations

    # Métriques (crée ou met à jour la ligne dans user_metrics)
    if user.metrics is not None:
        existing_metrics = (
            db.query(UserMetrics).filter(UserMetrics.user_id == user_id).first()
        )
        if existing_metrics:
            existing_metrics.weight = user.metrics.weight
            existing_metrics.actual_weight = (
                user.metrics.actual_weight or user.metrics.weight
            )
            existing_metrics.height = user.metrics.height
            existing_metrics.age = user.metrics.age
        else:
            db_metrics = UserMetrics(
                user_id=user_id,
                weight=user.metrics.weight,
                actual_weight=user.metrics.actual_weight or user.metrics.weight,
                height=user.metrics.height,
                age=user.metrics.age,
            )
            db.add(db_metrics)

        # Première entrée dans weight_log au jour de l'inscription
        from app.services.weight_log import add_weight_entry
        import datetime

        add_weight_entry(
            db,
            user_id,
            user.metrics.weight,
            source="registration",
            date=datetime.date.today(),
        )

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
