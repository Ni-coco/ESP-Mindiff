"""
Service de génération et gestion des workouts hebdomadaires.

Logique de split :
  1 séance  → Full Body (2h / 120 min)
  2 séances → Upper Body + Lower Body (1h / 60 min)
  3 séances → Push + Pull + Legs (1h / 60 min)
  4 séances → Upper + Lower + Upper + Lower (1h / 60 min)
  5 séances → Chest + Shoulders + Arms + Legs + Back (45 min)

Reps :
  build_muscle / increase_strength / lose_weight → 3 × 8-12
  improve_endurance / general_fitness / maintain  → 3 × 12-20

Cardio : toujours sauf build_muscle / increase_strength
"""

import datetime
import random
from typing import Optional

from sqlalchemy.orm import Session

from app.models.exercise import Exercise
from app.models.workout import (
    CustomWorkout,
    CustomWorkoutExercise,
    WorkoutSession,
    WorkoutSessionExercise,
    WorkoutWeek,
)

# ── Mapping split → targets musculaires ───────────────────────────────────────

_UPPER_TARGETS = [
    "pectorals",
    "delts",
    "lats",
    "upper back",
    "biceps",
    "triceps",
    "traps",
    "forearms",
]
_LOWER_TARGETS = [
    "quads",
    "hamstrings",
    "glutes",
    "calves",
    "adductors",
    "abductors",
    "abs",
]
_ALL_TARGETS = _UPPER_TARGETS + _LOWER_TARGETS

SPLITS: dict[int, list[tuple[str, list[str]]]] = {
    1: [("Full Body", _ALL_TARGETS)],
    2: [
        ("Upper Body", _UPPER_TARGETS),
        ("Lower Body", _LOWER_TARGETS),
    ],
    3: [
        ("Push", ["pectorals", "delts", "triceps"]),
        ("Pull", ["lats", "upper back", "biceps", "traps"]),
        ("Legs", ["quads", "hamstrings", "glutes", "calves", "adductors", "abductors"]),
    ],
    4: [
        ("Upper Body", _UPPER_TARGETS),
        ("Lower Body", _LOWER_TARGETS),
        ("Upper Body", _UPPER_TARGETS),
        ("Lower Body", _LOWER_TARGETS),
    ],
    5: [
        ("Chest", ["pectorals"]),
        ("Shoulders", ["delts", "traps"]),
        ("Arms", ["biceps", "triceps", "forearms"]),
        ("Legs", ["quads", "hamstrings", "glutes", "calves", "adductors", "abductors"]),
        ("Back", ["lats", "upper back"]),
    ],
}

# ── Durée et nombre d'exercices par session ────────────────────────────────────


def _session_config(sessions: int) -> tuple[int, int]:
    """Retourne (duration_minutes, nb_strength_exercises)."""
    if sessions == 1:
        return 120, 14
    if sessions <= 4:
        return 60, 7
    return 45, 4


# ── Sets / reps selon objectif ────────────────────────────────────────────────


def _reps_config(goal: Optional[str]) -> tuple[int, int, int]:
    """Retourne (sets, reps_min, reps_max)."""
    if goal in ("improve_endurance", "general_fitness", "maintain", None):
        return 3, 12, 20
    return 3, 8, 12


def _has_cardio(goal: Optional[str]) -> bool:
    return goal not in ("build_muscle", "increase_strength")


# ── Requêtes DB ───────────────────────────────────────────────────────────────


def _get_strength_exercises(db: Session, targets: list[str]) -> list[Exercise]:
    return (
        db.query(Exercise)
        .filter(Exercise.target.in_(targets))
        .filter(Exercise.body_part != "cardio")
        .all()
    )


def _get_cardio_exercises(db: Session) -> list[Exercise]:
    return db.query(Exercise).filter(Exercise.body_part == "cardio").all()


# ── Génération ────────────────────────────────────────────────────────────────


def _iso_week(date: datetime.date) -> tuple[int, int]:
    iso = date.isocalendar()
    return iso.year, iso.week


def generate_workout_week(
    db: Session,
    user_id: int,
    goal: Optional[str],
    sessions_per_week: int,
    rng_seed_offset: int = 0,
) -> WorkoutWeek:
    """Génère et persiste un workout pour la semaine courante."""
    today = datetime.date.today()
    year, week_number = _iso_week(today)

    # Seed déterministe : même résultat pour user + semaine, avec offset optionnel pour la régénération
    rng_seed = user_id * 100_000 + year * 100 + week_number + rng_seed_offset
    rng = random.Random(rng_seed)

    sessions_count = max(1, min(sessions_per_week, 5))
    split = SPLITS[sessions_count]
    duration_min, nb_strength = _session_config(sessions_count)
    sets, reps_min, reps_max = _reps_config(goal)
    add_cardio = _has_cardio(goal)

    cardio_pool = _get_cardio_exercises(db) if add_cardio else []

    workout = WorkoutWeek(
        user_id=user_id,
        year=year,
        week_number=week_number,
        goal=goal,
        sessions_per_week=sessions_count,
        is_pinned=False,
    )
    db.add(workout)
    db.flush()

    for session_idx, (split_name, targets) in enumerate(split):
        strength_pool = _get_strength_exercises(db, targets)
        rng.shuffle(strength_pool)
        chosen = strength_pool[:nb_strength]

        session = WorkoutSession(
            workout_week_id=workout.id,
            session_number=session_idx + 1,
            split_name=split_name,
            duration_minutes=duration_min,
        )
        db.add(session)

        for pos, ex in enumerate(chosen):
            db.add(
                WorkoutSessionExercise(
                    session=session,
                    exercise_id=ex.id,
                    position=pos,
                    sets=sets,
                    reps_min=reps_min,
                    reps_max=reps_max,
                    is_cardio=False,
                )
            )

        if add_cardio and cardio_pool:
            rng.shuffle(cardio_pool)
            cardio_ex = cardio_pool[0]
            db.add(
                WorkoutSessionExercise(
                    session=session,
                    exercise_id=cardio_ex.id,
                    position=len(chosen),
                    sets=1,
                    reps_min=20,
                    reps_max=30,
                    is_cardio=True,
                )
            )

    db.commit()
    db.refresh(workout)
    return workout


def get_or_generate_current_week(
    db: Session, user_id: int, goal: Optional[str], sessions_per_week: int
) -> WorkoutWeek:
    today = datetime.date.today()
    year, week_number = _iso_week(today)

    existing = (
        db.query(WorkoutWeek)
        .filter(WorkoutWeek.user_id == user_id)
        .filter(WorkoutWeek.year == year)
        .filter(WorkoutWeek.week_number == week_number)
        .first()
    )
    if existing:
        return existing

    return generate_workout_week(db, user_id, goal, sessions_per_week)


def pin_workout_week(
    db: Session, workout_week_id: int, user_id: int
) -> Optional[WorkoutWeek]:
    ww = (
        db.query(WorkoutWeek)
        .filter(WorkoutWeek.id == workout_week_id, WorkoutWeek.user_id == user_id)
        .first()
    )
    if not ww:
        return None
    ww.is_pinned = True
    db.commit()
    db.refresh(ww)
    return ww


def regenerate_workout_week(
    db: Session, user_id: int, goal: Optional[str], sessions_per_week: int
) -> WorkoutWeek:
    """Force un nouveau plan pour la semaine (ignore le plan existant non épinglé)."""
    today = datetime.date.today()
    year, week_number = _iso_week(today)

    existing = (
        db.query(WorkoutWeek)
        .filter(WorkoutWeek.user_id == user_id)
        .filter(WorkoutWeek.year == year)
        .filter(WorkoutWeek.week_number == week_number)
        .first()
    )
    if existing and existing.is_pinned:
        return existing
    if existing:
        db.delete(existing)
        db.commit()

    # Décale le seed pour obtenir un résultat différent
    today_offset = datetime.date.today().toordinal()
    rng_offset = today_offset % 97
    return generate_workout_week(
        db, user_id, goal, sessions_per_week, rng_seed_offset=rng_offset * 999_983
    )


# ── Custom workouts ───────────────────────────────────────────────────────────


def create_custom_workout(
    db: Session, user_id: int, name: str, exercises: list[dict]
) -> CustomWorkout:
    cw = CustomWorkout(user_id=user_id, name=name)
    db.add(cw)
    db.flush()
    for ex in exercises:
        db.add(
            CustomWorkoutExercise(
                custom_workout_id=cw.id,
                exercise_id=ex["exercise_id"],
                position=ex["position"],
                sets=ex["sets"],
                reps_min=ex["reps_min"],
                reps_max=ex["reps_max"],
            )
        )
    db.commit()
    db.refresh(cw)
    return cw


def list_custom_workouts(db: Session, user_id: int) -> list[CustomWorkout]:
    return db.query(CustomWorkout).filter(CustomWorkout.user_id == user_id).all()


def delete_custom_workout(db: Session, workout_id: int, user_id: int) -> bool:
    cw = (
        db.query(CustomWorkout)
        .filter(CustomWorkout.id == workout_id, CustomWorkout.user_id == user_id)
        .first()
    )
    if not cw:
        return False
    db.delete(cw)
    db.commit()
    return True
