import datetime
import sqlalchemy.orm as sqlo
from sqlalchemy import Integer, String, DateTime, func

from app.db.database import Base


class Program(Base):
    __tablename__ = "programs"

    id: sqlo.Mapped[int] = sqlo.mapped_column(Integer, primary_key=True, index=True)
    name: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    description: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    difficulty: sqlo.Mapped[str] = sqlo.mapped_column(String, nullable=False)
    calorie_burn: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    duration: sqlo.Mapped[int] = sqlo.mapped_column(Integer, nullable=False)
    created_at: sqlo.Mapped[datetime.datetime] = sqlo.mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
