from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_active_user
from app.schemas.exercise import ExerciseOut
from app.services import exercise as service

router = APIRouter(
    prefix="/exercise",
    tags=["Exercise"],
    dependencies=[Depends(get_current_active_user)],
)


def _resolve_gif_url(gif_url: Optional[str], request: Request) -> Optional[str]:
    """Transforme un chemin relatif en URL absolue si nécessaire."""
    if not gif_url:
        return gif_url
    if gif_url.startswith("http://") or gif_url.startswith("https://"):
        return gif_url
    # Chemin relatif → on préfixe avec l'origine du serveur
    base = str(request.base_url).rstrip("/")
    path = gif_url if gif_url.startswith("/") else f"/{gif_url}"
    return f"{base}{path}"


def _fix_exercise(ex, request: Request) -> ExerciseOut:
    out = ExerciseOut.model_validate(ex)
    out.gif_url = _resolve_gif_url(out.gif_url, request)
    return out


@router.get("/", response_model=List[ExerciseOut])
def list_exercise(
    request: Request,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None,
    secondary_muscle: Optional[str] = None,
    db: Session = Depends(get_db),
):
    exercises = service.get_exercises(
        db=db,
        skip=skip,
        limit=limit,
        body_part=body_part,
        equipment=equipment,
        target=target,
        secondary_muscle=secondary_muscle,
    )
    return [_fix_exercise(ex, request) for ex in exercises]


@router.get("/count")
def count_exercise(
    body_part: Optional[str] = None,
    equipment: Optional[str] = None,
    target: Optional[str] = None,
    db: Session = Depends(get_db),
):
    return {"count": service.get_exercises_count(db, body_part, equipment, target)}


@router.get("/filter", response_model=List[ExerciseOut])
def filter_exercise(
    request: Request,
    q: str = Query(..., min_length=1),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    exercises = service.filter_exercises(db=db, query=q, skip=skip, limit=limit)
    return [_fix_exercise(ex, request) for ex in exercises]


@router.get("/{exercise_id}", response_model=ExerciseOut)
def get_exercise(request: Request, exercise_id: str, db: Session = Depends(get_db)):
    ex = service.get_exercise(db, exercise_id)
    if not ex:
        raise HTTPException(status_code=404, detail="Exercise not found")
    return _fix_exercise(ex, request)
