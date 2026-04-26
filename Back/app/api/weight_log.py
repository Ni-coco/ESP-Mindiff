from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user, get_device_or_user, get_db
from app.models.user import User
from app.schemas.user import AddWeightRequest, WeightHistoryResponse, WeightLogEntry
from app.services import weight_log as service

router = APIRouter(prefix="/user", tags=["weight"])


@router.get("/{user_id}/weight-history", response_model=WeightHistoryResponse)
def get_weight_history(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")

    entries = service.get_weight_history(db, user_id)
    return WeightHistoryResponse(entries=[WeightLogEntry(**e) for e in entries])


@router.post("/{user_id}/weight", response_model=WeightLogEntry)
def add_weight(
    user_id: int,
    body: AddWeightRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_device_or_user),
):
    if current_user.id != user_id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Accès refusé")

    entry = service.add_weight_entry(db, user_id, body.weight, body.source)
    return entry
