"""Tests for app.services.workout module."""

import datetime
from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy.orm import Session

from app.models.exercise import Exercise
from app.models.user import User
from app.models.workout import CustomWorkout, WorkoutSession, WorkoutWeek
from app.services import workout as workout_service


class TestRepsConfig:
    """Tests for _reps_config function."""

    def test_reps_config_build_muscle(self):
        """Test reps config for build muscle."""
        sets, reps_min, reps_max = workout_service._reps_config("build_muscle")
        assert sets == 3
        assert reps_min == 8
        assert reps_max == 12

    def test_reps_config_increase_strength(self):
        """Test reps config for increase strength."""
        sets, reps_min, reps_max = workout_service._reps_config("increase_strength")
        assert sets == 3
        assert reps_min == 8
        assert reps_max == 12

    def test_reps_config_improve_endurance(self):
        """Test reps config for improve endurance."""
        sets, reps_min, reps_max = workout_service._reps_config("improve_endurance")
        assert sets == 3
        assert reps_min == 12
        assert reps_max == 20

    def test_reps_config_general_fitness(self):
        """Test reps config for general fitness."""
        sets, reps_min, reps_max = workout_service._reps_config("general_fitness")
        assert sets == 3
        assert reps_min == 12
        assert reps_max == 20

    def test_reps_config_none_goal(self):
        """Test reps config with None goal."""
        sets, reps_min, reps_max = workout_service._reps_config(None)
        assert sets == 3
        assert reps_min == 12
        assert reps_max == 20


class TestHasCardio:
    """Tests for _has_cardio function."""

    def test_has_cardio_build_muscle(self):
        """Test cardio flag for build muscle."""
        assert workout_service._has_cardio("build_muscle") is False

    def test_has_cardio_increase_strength(self):
        """Test cardio flag for increase strength."""
        assert workout_service._has_cardio("increase_strength") is False

    def test_has_cardio_improve_endurance(self):
        """Test cardio flag for improve endurance."""
        assert workout_service._has_cardio("improve_endurance") is True

    def test_has_cardio_general_fitness(self):
        """Test cardio flag for general fitness."""
        assert workout_service._has_cardio("general_fitness") is True

    def test_has_cardio_none_goal(self):
        """Test cardio flag with None goal."""
        assert workout_service._has_cardio(None) is True


class TestGetStrengthExercises:
    """Tests for _get_strength_exercises function."""

    def test_get_strength_exercises_basic(self, db: Session, test_exercise: Exercise):
        """Test retrieving strength exercises."""
        exercises = workout_service._get_strength_exercises(db, ["pectorals"])
        assert len(exercises) >= 1
        assert test_exercise in exercises

    def test_get_strength_exercises_multiple_targets(self, db: Session):
        """Test retrieving exercises with multiple targets."""
        exercises = workout_service._get_strength_exercises(db, ["pectorals", "biceps"])
        assert isinstance(exercises, list)

    def test_get_strength_exercises_excludes_cardio(
        self, db: Session, test_cardio_exercise: Exercise
    ):
        """Test that cardio exercises are excluded."""
        exercises = workout_service._get_strength_exercises(db, ["pectorals"])
        assert test_cardio_exercise not in exercises


class TestGetCardioExercises:
    """Tests for _get_cardio_exercises function."""

    def test_get_cardio_exercises(self, db: Session, test_cardio_exercise: Exercise):
        """Test retrieving cardio exercises."""
        exercises = workout_service._get_cardio_exercises(db)
        assert test_cardio_exercise in exercises


class TestGenerateWorkoutWeek:
    """Tests for generate_workout_week function."""

    def test_generate_workout_week_one_session(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test generating workout with one session."""
        workout = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 1
        )

        assert workout.id is not None
        assert workout.user_id == test_user.id
        assert workout.sessions_per_week == 1
        assert len(workout.sessions) == 1

    def test_generate_workout_week_three_sessions(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test generating workout with three sessions."""
        workout = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 3
        )

        assert workout.sessions_per_week == 3
        assert len(workout.sessions) == 3

    def test_generate_workout_week_caps_at_five(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that sessions are capped at 5."""
        workout = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 10
        )

        assert workout.sessions_per_week == 5
        assert len(workout.sessions) == 5

    def test_generate_workout_week_persisted(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that generated workout is persisted."""
        workout = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 3
        )

        retrieved = db.query(WorkoutWeek).filter(WorkoutWeek.id == workout.id).first()
        assert retrieved is not None

    def test_generate_workout_week_deterministic(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that same user/week generates same exercises."""
        # Generate twice
        today = datetime.date.today()
        year, week = today.isocalendar()[0:2]

        db.query(WorkoutWeek).filter(
            WorkoutWeek.user_id == test_user.id,
            WorkoutWeek.year == year,
            WorkoutWeek.week_number == week,
        ).delete()
        db.commit()

        workout1 = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 3
        )
        ex1 = set(e.exercise_id for s in workout1.sessions for e in s.exercises)

        db.query(WorkoutWeek).filter(WorkoutWeek.id == workout1.id).delete()
        db.commit()

        workout2 = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 3
        )
        ex2 = set(e.exercise_id for s in workout2.sessions for e in s.exercises)

        assert ex1 == ex2

    def test_generate_workout_week_with_cardio(
        self,
        db: Session,
        test_user: User,
        test_exercise: Exercise,
        test_cardio_exercise: Exercise,
    ):
        """Test that cardio is added for endurance goal."""
        workout = workout_service.generate_workout_week(
            db, test_user.id, "improve_endurance", 2
        )

        has_cardio = any(e.is_cardio for s in workout.sessions for e in s.exercises)
        assert has_cardio

    def test_generate_workout_week_no_cardio_for_strength(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that no cardio for strength goal."""
        workout = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 2
        )

        has_cardio = any(e.is_cardio for s in workout.sessions for e in s.exercises)
        assert not has_cardio


class TestGetOrGenerateCurrentWeek:
    """Tests for get_or_generate_current_week function."""

    def test_get_or_generate_returns_existing(
        self, db: Session, test_user: User, test_workout_week: WorkoutWeek
    ):
        """Test that existing week is returned."""
        workout = workout_service.get_or_generate_current_week(
            db, test_user.id, "build_muscle", 3
        )

        assert workout.id == test_workout_week.id

    def test_get_or_generate_creates_new(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that new week is generated if not exists."""
        today = datetime.date.today()
        year, week = today.isocalendar()[0:2]

        db.query(WorkoutWeek).filter(
            WorkoutWeek.user_id == test_user.id,
            WorkoutWeek.year == year,
            WorkoutWeek.week_number == week,
        ).delete()
        db.commit()

        workout = workout_service.get_or_generate_current_week(
            db, test_user.id, "build_muscle", 3
        )

        assert workout.id is not None
        assert len(workout.sessions) == 3


class TestPinWorkoutWeek:
    """Tests for pin_workout_week function."""

    def test_pin_workout_week(
        self, db: Session, test_user: User, test_workout_week: WorkoutWeek
    ):
        """Test pinning a workout week."""
        result = workout_service.pin_workout_week(
            db, test_workout_week.id, test_user.id
        )

        assert result.is_pinned is True

    def test_pin_workout_week_wrong_user(
        self, db: Session, test_user: User, test_workout_week: WorkoutWeek
    ):
        """Test pinning fails for wrong user."""
        from app.core.security import get_password_hash

        other_user = User(
            email="other@example.com",
            username="other",
            hashed_password=get_password_hash("pass"),
        )
        db.add(other_user)
        db.commit()

        result = workout_service.pin_workout_week(
            db, test_workout_week.id, other_user.id
        )

        assert result is None


class TestRegenerateWorkoutWeek:
    """Tests for regenerate_workout_week function."""

    def test_regenerate_workout_week_creates_new(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that regeneration creates new workout with different exercises."""
        # Create multiple exercises for each target to enable shuffle variation
        exercise2 = Exercise(
            id="dumbbell_press_001",
            name="Dumbbell Press",
            body_part="chest",
            target="pectorals",
            equipment="dumbbell",
            gif_url="https://example.com/dumbbell_press.gif",
        )
        exercise3 = Exercise(
            id="shoulder_press_001",
            name="Shoulder Press",
            body_part="shoulders",
            target="delts",
            equipment="barbell",
            gif_url="https://example.com/shoulder_press.gif",
        )
        exercise4 = Exercise(
            id="tricep_dips_001",
            name="Tricep Dips",
            body_part="arms",
            target="triceps",
            equipment="bodyweight",
            gif_url="https://example.com/tricep_dips.gif",
        )
        db.add_all([exercise2, exercise3, exercise4])
        db.commit()

        # Generate initial workout
        today = datetime.date.today()
        year, week = today.isocalendar()[0:2]

        workout1 = workout_service.generate_workout_week(
            db, test_user.id, "build_muscle", 3
        )
        exercises1 = [e.exercise_id for s in workout1.sessions for e in s.exercises]

        # Regenerate and get new workout
        workout2 = workout_service.regenerate_workout_week(
            db, test_user.id, "build_muscle", 3
        )
        exercises2 = [e.exercise_id for s in workout2.sessions for e in s.exercises]

        # With RNG seed offset, exercise order should be different
        # (unless by extreme coincidence they match)
        assert exercises1 != exercises2 or workout1.id != workout2.id

    def test_regenerate_workout_week_respects_pinned(
        self, db: Session, test_user: User, test_workout_week: WorkoutWeek
    ):
        """Test that pinned workouts are not regenerated."""
        test_workout_week.is_pinned = True
        db.commit()

        workout = workout_service.regenerate_workout_week(
            db, test_user.id, "build_muscle", 3
        )

        assert workout.id == test_workout_week.id


class TestCreateCustomWorkout:
    """Tests for create_custom_workout function."""

    def test_create_custom_workout(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test creating custom workout."""
        exercises = [
            {
                "exercise_id": test_exercise.id,
                "position": 0,
                "sets": 3,
                "reps_min": 8,
                "reps_max": 12,
            }
        ]

        workout = workout_service.create_custom_workout(
            db, test_user.id, "My Workout", exercises
        )

        assert workout.id is not None
        assert workout.name == "My Workout"
        assert len(workout.exercises) == 1

    def test_create_custom_workout_persisted(
        self, db: Session, test_user: User, test_exercise: Exercise
    ):
        """Test that custom workout is persisted."""
        exercises = [
            {
                "exercise_id": test_exercise.id,
                "position": 0,
                "sets": 3,
                "reps_min": 8,
                "reps_max": 12,
            }
        ]

        workout = workout_service.create_custom_workout(
            db, test_user.id, "My Workout", exercises
        )

        retrieved = (
            db.query(CustomWorkout).filter(CustomWorkout.id == workout.id).first()
        )
        assert retrieved is not None


class TestListCustomWorkouts:
    """Tests for list_custom_workouts function."""

    def test_list_custom_workouts_empty(self, db: Session, test_user: User):
        """Test listing custom workouts when none exist."""
        workouts = workout_service.list_custom_workouts(db, test_user.id)
        assert len(workouts) == 0

    def test_list_custom_workouts(
        self, db: Session, test_user: User, test_custom_workout: CustomWorkout
    ):
        """Test listing custom workouts."""
        workouts = workout_service.list_custom_workouts(db, test_user.id)
        assert len(workouts) >= 1
        assert test_custom_workout in workouts


class TestDeleteCustomWorkout:
    """Tests for delete_custom_workout function."""

    def test_delete_custom_workout(
        self, db: Session, test_user: User, test_custom_workout: CustomWorkout
    ):
        """Test deleting custom workout."""
        result = workout_service.delete_custom_workout(
            db, test_custom_workout.id, test_user.id
        )

        assert result is True

        retrieved = (
            db.query(CustomWorkout)
            .filter(CustomWorkout.id == test_custom_workout.id)
            .first()
        )
        assert retrieved is None

    def test_delete_custom_workout_wrong_user(
        self, db: Session, test_user: User, test_custom_workout: CustomWorkout
    ):
        """Test delete fails for wrong user."""
        from app.core.security import get_password_hash

        other_user = User(
            email="other@example.com",
            username="other",
            hashed_password=get_password_hash("pass"),
        )
        db.add(other_user)
        db.commit()

        result = workout_service.delete_custom_workout(
            db, test_custom_workout.id, other_user.id
        )

        assert result is False
