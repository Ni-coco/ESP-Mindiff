import datetime

from sqlalchemy import Integer, String, Boolean, DateTime, func, Float
import sqlalchemy.orm as sqlo

from app.db.database import Base


class UserMetrics(Base):
    __tablename__ = "user_metrics"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    weight: sqlo.Mapped[float] = sqlo.mapped_column(Float, nullable=False)
    height: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    age: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)


class User(Base):
    __tablename__ = "users"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    email : sqlo.Mapped[str] = sqlo.mapped_column(String, unique=True, index=True, nullable=False)
    username : sqlo.Mapped[str] = sqlo.mapped_column(String, unique=True, index=True, nullable=False)
    hashed_password : sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    is_active : sqlo.Mapped[bool] = sqlo.mapped_column(Boolean, default=True)
    is_superuser : sqlo.Mapped[bool] = sqlo.mapped_column(Boolean, default=False)
    created_at : sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at : sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user_metrics: sqlo.Relationship[list[UserMetrics]] = sqlo.relationship(back_populates="user_metrics")
