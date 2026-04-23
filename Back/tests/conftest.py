"""
Pytest configuration and fixtures for testing the Mindiff backend.
"""

import datetime
import os
import tempfile
from typing import Generator
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

# Create a temporary directory for test database
_test_db_dir = tempfile.mkdtemp()

# Mock before any imports
with patch("app.main.command.upgrade"):
    with patch("app.core.config.VaultConfig") as mock_vault:
        mock_instance = MagicMock()
        mock_instance.is_authenticated.return_value = True
        mock_instance.get_secrets.return_value = {
            "POSTGRES_USER": "test_user",
            "POSTGRES_PASSWORD": "test_pass",
            "POSTGRES_DB": "test_db",
            "SECRET_KEY": "test_secret_key_12345",
            "EDAMAM_APP_ID": "test_app_id",
            "EDAMAM_APP_KEY": "test_app_key",
            "EDAMAM_MEAL_APP_ID": "test_meal_id",
            "EDAMAM_MEAL_APP_KEY": "test_meal_key",
        }
        mock_vault.return_value = mock_instance

        # Now import app
        from app.core.security import get_password_hash
        from app.db.database import Base, get_db
        from app.main import app
        from app.models.exercise import Exercise, Instruction, SecondaryMuscle
        from app.models.program import Program
        from app.models.user import MealLog, User, UserMetrics, WeightLog
        from app.models.workout import (
            CustomWorkout,
            CustomWorkoutExercise,
            WorkoutSession,
            WorkoutSessionExercise,
            WorkoutWeek,
        )

# Use file-based SQLite instead of :memory: for better threading support
_db_file = os.path.join(_test_db_dir, "test.db")
SQLALCHEMY_DATABASE_URL = f"sqlite:///{_db_file}"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_conn, connection_record):
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create tables once at startup
Base.metadata.create_all(bind=engine)


def override_get_db() -> Generator:
    """Override get_db to provide a fresh session for each request."""
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def cleanup_db():
    """Clean up database before each test."""
    session = TestingSessionLocal()
    try:
        # Delete all data from all tables (in reverse order for foreign keys)
        for table in reversed(Base.metadata.sorted_tables):
            session.execute(table.delete())
        session.commit()
    finally:
        session.close()

    yield


@pytest.fixture
def db() -> Generator[Session, None, None]:
    """Provide a clean database session for each test."""
    session = TestingSessionLocal()
    try:
        yield session
        # Commit to persist fixture data
        session.commit()
    finally:
        try:
            session.close()
        except Exception:
            pass


@pytest.fixture
def client() -> TestClient:
    """Provide a test client."""
    return TestClient(app)


@pytest.fixture
def user_data():
    """Sample user data."""
    return {
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpass123",
        "gender": "male",
        "sport_objective": "build_muscle",
        "sessions_per_week": 4,
    }


@pytest.fixture
def user_metrics_data():
    """Sample user metrics data."""
    return {
        "weight": 75.0,
        "actual_weight": 75.0,
        "height": 180,
        "age": 30,
    }


@pytest.fixture
def test_user(db: Session, user_data: dict, user_metrics_data: dict) -> User:
    """Create a test user with metrics."""
    hashed_password = get_password_hash(user_data["password"])
    user = User(
        email=user_data["email"],
        username=user_data["username"],
        hashed_password=hashed_password,
        is_active=True,
        is_superuser=False,
        gender=user_data["gender"],
        sport_objective=user_data["sport_objective"],
        sessions_per_week=user_data["sessions_per_week"],
    )
    db.add(user)
    db.flush()

    metrics = UserMetrics(
        user_id=user.id,
        **user_metrics_data,
    )
    db.add(metrics)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def test_superuser(db: Session) -> User:
    """Create a test superuser."""
    hashed_password = get_password_hash("superpass123")
    user = User(
        email="admin@example.com",
        username="admin",
        hashed_password=hashed_password,
        is_active=True,
        is_superuser=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def test_inactive_user(db: Session) -> User:
    """Create a test inactive user."""
    hashed_password = get_password_hash("inactivepass123")
    user = User(
        email="inactive@example.com",
        username="inactiveuser",
        hashed_password=hashed_password,
        is_active=False,
        is_superuser=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def test_exercise(db: Session) -> Exercise:
    """Create a test exercise."""
    exercise = Exercise(
        id="bench_press_001",
        name="Bench Press",
        body_part="chest",
        target="pectorals",
        equipment="barbell",
        gif_url="https://example.com/bench_press.gif",
    )
    db.add(exercise)
    db.flush()

    instr1 = Instruction(exercise_id=exercise.id, step_order=1, text="Lie on bench")
    instr2 = Instruction(exercise_id=exercise.id, step_order=2, text="Press bar up")
    db.add_all([instr1, instr2])
    db.flush()

    sec_muscle = SecondaryMuscle(exercise_id=exercise.id, name="triceps")
    db.add(sec_muscle)
    db.commit()
    db.refresh(exercise)
    return exercise


@pytest.fixture
def test_leg_exercise(db: Session) -> Exercise:
    """Create a test leg exercise."""
    exercise = Exercise(
        id="squat_001",
        name="Squat",
        body_part="legs",
        target="quads",
        equipment="barbell",
        gif_url="https://example.com/squat.gif",
    )
    db.add(exercise)
    db.commit()
    db.refresh(exercise)
    return exercise


@pytest.fixture
def test_cardio_exercise(db: Session) -> Exercise:
    """Create a test cardio exercise."""
    exercise = Exercise(
        id="treadmill_001",
        name="Treadmill",
        body_part="cardio",
        target=None,
        equipment="treadmill",
        gif_url=None,
    )
    db.add(exercise)
    db.commit()
    db.refresh(exercise)
    return exercise


@pytest.fixture
def test_meal_log(db: Session, test_user: User) -> MealLog:
    """Create a test meal log entry."""
    meal = MealLog(
        user_id=test_user.id,
        date=datetime.date.today(),
        meal_type="lunch",
        description="Chicken with rice",
        calories=650.0,
        protein_g=45.0,
        fat_g=15.0,
        carbs_g=65.0,
        fiber_g=3.0,
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)
    return meal


@pytest.fixture
def test_weight_log(db: Session, test_user: User) -> WeightLog:
    """Create a test weight log entry."""
    weight = WeightLog(
        user_id=test_user.id,
        date=datetime.date.today(),
        weight=75.5,
        source="manual",
    )
    db.add(weight)
    db.commit()
    db.refresh(weight)
    return weight


@pytest.fixture
def test_program(db: Session) -> Program:
    """Create a test program."""
    program = Program(
        name="Beginner Strength",
        description="A beginner-friendly strength program",
        difficulty="easy",
        calorie_burn=200,
        duration=45,
    )
    db.add(program)
    db.commit()
    db.refresh(program)
    return program


@pytest.fixture
def test_workout_week(
    db: Session, test_user: User, test_exercise: Exercise
) -> WorkoutWeek:
    """Create a test workout week."""
    today = datetime.date.today()
    iso = today.isocalendar()

    workout = WorkoutWeek(
        user_id=test_user.id,
        year=iso.year,
        week_number=iso.week,
        goal="build_muscle",
        sessions_per_week=3,
        is_pinned=False,
    )
    db.add(workout)
    db.flush()

    session = WorkoutSession(
        workout_week_id=workout.id,
        session_number=1,
        split_name="Push",
        duration_minutes=60,
    )
    db.add(session)
    db.flush()

    exercise_entry = WorkoutSessionExercise(
        session_id=session.id,
        exercise_id=test_exercise.id,
        position=0,
        sets=3,
        reps_min=8,
        reps_max=12,
        is_cardio=False,
    )
    db.add(exercise_entry)
    db.commit()
    db.refresh(workout)
    return workout


@pytest.fixture
def test_custom_workout(
    db: Session, test_user: User, test_exercise: Exercise
) -> CustomWorkout:
    """Create a test custom workout."""
    custom = CustomWorkout(
        user_id=test_user.id,
        name="My Custom Workout",
    )
    db.add(custom)
    db.flush()

    exercise_entry = CustomWorkoutExercise(
        custom_workout_id=custom.id,
        exercise_id=test_exercise.id,
        position=0,
        sets=3,
        reps_min=8,
        reps_max=12,
    )
    db.add(exercise_entry)
    db.commit()
    db.refresh(custom)
    return custom


@pytest.fixture
def auth_headers(client: TestClient, test_user: User) -> dict:
    """Get authorization headers with a valid token."""
    response = client.post(
        "/api/auth/login",
        json={
            "email": "test@example.com",
            "password": "testpass123",
        },
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def superuser_auth_headers(client: TestClient, test_superuser: User) -> dict:
    """Get authorization headers for superuser."""
    response = client.post(
        "/api/auth/login",
        json={
            "email": "admin@example.com",
            "password": "superpass123",
        },
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
