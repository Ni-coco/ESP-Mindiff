import datetime
import enum

import sqlalchemy.orm as sqlo
from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)

from app.db.database import Base


class UserMetrics(Base):
    __tablename__ = "user_metrics"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    user_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("users.id"), nullable=False
    )
    weight: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False)
    actual_weight: sqlo.Mapped[float | None] = sqlo.mapped_column(Float, nullable=True)
    height: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    age: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)

    # Relationship back to User
    user: sqlo.Mapped["User"] = sqlo.relationship(back_populates="user_metrics")


class User(Base):
    __tablename__ = "users"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    email: sqlo.Mapped[str] = sqlo.mapped_column(
        String, unique=True, index=True, nullable=False
    )
    username: sqlo.Mapped[str] = sqlo.mapped_column(
        String, unique=True, index=True, nullable=False
    )
    hashed_password: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    is_active: sqlo.Mapped[bool] = sqlo.mapped_column(Boolean, default=True)
    is_superuser: sqlo.Mapped[bool] = sqlo.mapped_column(Boolean, default=False)
    created_at: sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: sqlo.Mapped[datetime.datetime | None] = sqlo.mapped_column(
        DateTime(timezone=True), nullable=True, onupdate=func.now()
    )
    gender: sqlo.Mapped[str | None] = sqlo.mapped_column(String, nullable=True)
    sport_objective: sqlo.Mapped[str | None] = sqlo.mapped_column(String, nullable=True)
    target_weight: sqlo.Mapped[float | None] = sqlo.mapped_column(Float, nullable=True)
    sessions_per_week: sqlo.Mapped[int | None] = sqlo.mapped_column(
        Integer, nullable=True
    )
    health_considerations: sqlo.Mapped[str | None] = sqlo.mapped_column(
        String, nullable=True
    )

    # Relationships
    user_metrics: sqlo.Relationship[list[UserMetrics]] = sqlo.relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    weight_logs: sqlo.Relationship[list["WeightLog"]] = sqlo.relationship(
        back_populates="user", cascade="all, delete-orphan", order_by="WeightLog.date"
    )
    meal_logs: sqlo.Relationship[list["MealLog"]] = sqlo.relationship(
        back_populates="user", cascade="all, delete-orphan", order_by="MealLog.date"
    )


class WeightLog(Base):
    __tablename__ = "weight_log"
    __table_args__ = (
        UniqueConstraint("user_id", "date", name="uq_weight_log_user_date"),
        Index("ix_weight_log_user_date", "user_id", "date"),
    )

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True)
    user_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    date: sqlo.Mapped[datetime.date] = sqlo.mapped_column(Date, nullable=False)
    weight: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False)
    source: sqlo.Mapped[str] = sqlo.mapped_column(
        String, nullable=False, default="manual"
    )

    user: sqlo.Mapped["User"] = sqlo.relationship(back_populates="weight_logs")


class MealLog(Base):
    __tablename__ = "meal_log"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True)
    user_id: sqlo.Mapped[int] = sqlo.mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    date: sqlo.Mapped[datetime.date] = sqlo.mapped_column(Date, nullable=False)
    meal_type: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    description: sqlo.Mapped[str] = sqlo.mapped_column(Text, nullable=False)
    calories: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False, default=0)
    protein_g: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False, default=0)
    fat_g: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False, default=0)
    carbs_g: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False, default=0)
    fiber_g: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False, default=0)
    created_at: sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: sqlo.Mapped["User"] = sqlo.relationship(back_populates="meal_logs")
