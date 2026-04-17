from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime, date


class UserMetrics(BaseModel):
    weight: float
    actual_weight: Optional[float] = None
    height: int
    age: int


class UserMetricsResponse(BaseModel):
    weight: float
    actual_weight: Optional[float] = None
    height: int
    age: int

    class Config:
        from_attributes = True


class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(UserBase):
    password: Optional[str] = Field(None, min_length=8, max_length=100)
    is_active: Optional[bool] = None
    is_superuser: Optional[bool] = None
    metrics: Optional[UserMetrics] = None
    gender: Optional[str] = None
    sport_objective: Optional[str] = None
    target_weight: Optional[float] = None
    sessions_per_week: Optional[int] = None
    health_considerations: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(UserBase):
    id: int
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    gender: Optional[str] = None
    sport_objective: Optional[str] = None
    target_weight: Optional[float] = None
    sessions_per_week: Optional[int] = None
    health_considerations: Optional[str] = None
    user_metrics: list[UserMetricsResponse] = []

    class Config:
        from_attributes = True


class WeightLogEntry(BaseModel):
    date: date
    weight: float
    source: str

    class Config:
        from_attributes = True


class WeightHistoryResponse(BaseModel):
    entries: list[WeightLogEntry]


class AddWeightRequest(BaseModel):
    weight: float
    source: str = "manual"


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    email: Optional[str] = None

