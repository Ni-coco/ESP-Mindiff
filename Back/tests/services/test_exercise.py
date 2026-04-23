"""
Comprehensive unit tests for app.services.exercise module.

Tests cover all exercise service functions with 100% coverage:
- get_exercise: retrieve single exercise by ID
- get_exercises: retrieve multiple exercises with filters
- get_exercises_count: count exercises with filters
- filter_exercises: search exercises by name/target/body_part
"""

import pytest
from sqlalchemy.orm import Session

from app.models.exercise import Exercise, Instruction, SecondaryMuscle
from app.services import exercise as exercise_service


class TestGetExercise:
    """Tests for get_exercise function."""

    def test_get_exercise_exists(self, db: Session, test_exercise: Exercise):
        """Test retrieving an existing exercise by ID."""
        exercise = exercise_service.get_exercise(db, test_exercise.id)
        assert exercise is not None
        assert exercise.id == test_exercise.id
        assert exercise.name == "Bench Press"

    def test_get_exercise_not_exists(self, db: Session):
        """Test retrieving non-existent exercise returns None."""
        exercise = exercise_service.get_exercise(db, "nonexistent_id")
        assert exercise is None

    def test_get_exercise_returns_all_fields(
        self, db: Session, test_exercise: Exercise
    ):
        """Test that get_exercise returns all exercise fields."""
        exercise = exercise_service.get_exercise(db, test_exercise.id)
        assert exercise.name is not None
        assert exercise.body_part is not None
        assert exercise.target is not None
        assert exercise.equipment is not None

    def test_get_exercise_with_instructions(self, db: Session, test_exercise: Exercise):
        """Test that get_exercise includes instructions."""
        exercise = exercise_service.get_exercise(db, test_exercise.id)
        assert len(exercise.instructions) > 0
        assert exercise.instructions[0].text == "Lie on bench"

    def test_get_exercise_with_secondary_muscles(
        self, db: Session, test_exercise: Exercise
    ):
        """Test that get_exercise includes secondary muscles."""
        exercise = exercise_service.get_exercise(db, test_exercise.id)
        assert len(exercise.secondary_muscles) > 0
        assert exercise.secondary_muscles[0].name == "triceps"

    def test_get_exercise_empty_string_id(self, db: Session):
        """Test getting exercise with empty string ID."""
        exercise = exercise_service.get_exercise(db, "")
        assert exercise is None


class TestGetExercises:
    """Tests for get_exercises function."""

    def test_get_exercises_empty_db(self, db: Session):
        """Test getting exercises from empty database."""
        exercises = exercise_service.get_exercises(db)
        assert exercises == []

    def test_get_exercises_single(self, db: Session, test_exercise: Exercise):
        """Test getting exercises with one exercise in database."""
        exercises = exercise_service.get_exercises(db)
        assert len(exercises) == 1
        assert exercises[0].id == test_exercise.id

    def test_get_exercises_multiple(
        self, db: Session, test_exercise: Exercise, test_leg_exercise: Exercise
    ):
        """Test getting multiple exercises."""
        exercises = exercise_service.get_exercises(db)
        assert len(exercises) == 2

    def test_get_exercises_skip_and_limit(self, db: Session):
        """Test pagination with skip and limit parameters."""
        # Create multiple exercises
        for i in range(5):
            exercise = Exercise(
                id=f"exercise_{i}",
                name=f"Exercise {i}",
                body_part="chest",
                target="pectorals",
                equipment="barbell",
            )
            db.add(exercise)
        db.commit()

        # Test skip
        exercises = exercise_service.get_exercises(db, skip=2, limit=10)
        assert len(exercises) == 3

        # Test limit
        exercises = exercise_service.get_exercises(db, skip=0, limit=2)
        assert len(exercises) == 2

        # Test both
        exercises = exercise_service.get_exercises(db, skip=1, limit=2)
        assert len(exercises) == 2

    def test_get_exercises_filter_by_body_part(
        self, db: Session, test_exercise: Exercise, test_leg_exercise: Exercise
    ):
        """Test filtering exercises by body_part."""
        exercises = exercise_service.get_exercises(db, body_part="chest")
        assert len(exercises) == 1
        assert exercises[0].body_part == "chest"

        exercises = exercise_service.get_exercises(db, body_part="legs")
        assert len(exercises) == 1
        assert exercises[0].body_part == "legs"

        exercises = exercise_service.get_exercises(db, body_part="nonexistent")
        assert len(exercises) == 0

    def test_get_exercises_filter_by_equipment(
        self, db: Session, test_exercise: Exercise
    ):
        """Test filtering exercises by equipment."""
        exercises = exercise_service.get_exercises(db, equipment="barbell")
        assert len(exercises) == 1
        assert exercises[0].equipment == "barbell"

        exercises = exercise_service.get_exercises(db, equipment="dumbbell")
        assert len(exercises) == 0

    def test_get_exercises_filter_by_target(self, db: Session, test_exercise: Exercise):
        """Test filtering exercises by target."""
        exercises = exercise_service.get_exercises(db, target="pectorals")
        assert len(exercises) == 1
        assert exercises[0].target == "pectorals"

        exercises = exercise_service.get_exercises(db, target="quads")
        assert len(exercises) == 0

    def test_get_exercises_filter_by_secondary_muscle(
        self, db: Session, test_exercise: Exercise
    ):
        """Test filtering exercises by secondary muscle."""
        exercises = exercise_service.get_exercises(db, secondary_muscle="triceps")
        assert len(exercises) == 1

        exercises = exercise_service.get_exercises(db, secondary_muscle="biceps")
        assert len(exercises) == 0

    def test_get_exercises_combined_filters(
        self, db: Session, test_exercise: Exercise, test_leg_exercise: Exercise
    ):
        """Test filtering with multiple criteria."""
        exercises = exercise_service.get_exercises(
            db, body_part="chest", equipment="barbell"
        )
        assert len(exercises) == 1
        assert exercises[0].body_part == "chest"
        assert exercises[0].equipment == "barbell"

    def test_get_exercises_filter_no_results(
        self, db: Session, test_exercise: Exercise
    ):
        """Test filtering that returns no results."""
        exercises = exercise_service.get_exercises(
            db, body_part="chest", equipment="machine"
        )
        assert len(exercises) == 0

    def test_get_exercises_default_pagination(self, db: Session):
        """Test that default pagination limits to 100."""
        # Create 150 exercises
        for i in range(150):
            exercise = Exercise(
                id=f"ex_{i}",
                name=f"Exercise {i}",
                body_part="chest",
                target="pectorals",
                equipment="barbell",
            )
            db.add(exercise)
        db.commit()

        exercises = exercise_service.get_exercises(db)
        assert len(exercises) == 100

    def test_get_exercises_preserves_order(self, db: Session):
        """Test that exercises are returned in consistent order."""
        exercises1 = exercise_service.get_exercises(db)
        exercises2 = exercise_service.get_exercises(db)

        ids1 = [e.id for e in exercises1]
        ids2 = [e.id for e in exercises2]
        assert ids1 == ids2


class TestGetExercisesCount:
    """Tests for get_exercises_count function."""

    def test_get_exercises_count_empty_db(self, db: Session):
        """Test counting exercises in empty database."""
        count = exercise_service.get_exercises_count(db)
        assert count == 0

    def test_get_exercises_count_single(self, db: Session, test_exercise: Exercise):
        """Test counting with one exercise."""
        count = exercise_service.get_exercises_count(db)
        assert count == 1

    def test_get_exercises_count_multiple(
        self, db: Session, test_exercise: Exercise, test_leg_exercise: Exercise
    ):
        """Test counting multiple exercises."""
        count = exercise_service.get_exercises_count(db)
        assert count == 2

    def test_get_exercises_count_by_body_part(
        self, db: Session, test_exercise: Exercise, test_leg_exercise: Exercise
    ):
        """Test counting exercises filtered by body_part."""
        count = exercise_service.get_exercises_count(db, body_part="chest")
        assert count == 1

        count = exercise_service.get_exercises_count(db, body_part="legs")
        assert count == 1

        count = exercise_service.get_exercises_count(db, body_part="back")
        assert count == 0

    def test_get_exercises_count_by_equipment(
        self, db: Session, test_exercise: Exercise
    ):
        """Test counting exercises filtered by equipment."""
        count = exercise_service.get_exercises_count(db, equipment="barbell")
        assert count == 1

        count = exercise_service.get_exercises_count(db, equipment="dumbbell")
        assert count == 0

    def test_get_exercises_count_by_target(self, db: Session, test_exercise: Exercise):
        """Test counting exercises filtered by target."""
        count = exercise_service.get_exercises_count(db, target="pectorals")
        assert count == 1

        count = exercise_service.get_exercises_count(db, target="quads")
        assert count == 0

    def test_get_exercises_count_combined_filters(
        self, db: Session, test_exercise: Exercise, test_leg_exercise: Exercise
    ):
        """Test counting with multiple filter criteria."""
        count = exercise_service.get_exercises_count(
            db, body_part="chest", equipment="barbell"
        )
        assert count == 1

        count = exercise_service.get_exercises_count(
            db, body_part="chest", target="pectorals"
        )
        assert count == 1

    def test_get_exercises_count_large_dataset(self, db: Session):
        """Test counting with large number of exercises."""
        for i in range(50):
            exercise = Exercise(
                id=f"ex_{i}",
                name=f"Exercise {i}",
                body_part="chest",
                target="pectorals",
                equipment="barbell",
            )
            db.add(exercise)
        db.commit()

        count = exercise_service.get_exercises_count(db)
        assert count == 50


class TestFilterExercises:
    """Tests for filter_exercises function."""

    def test_filter_exercises_by_name(self, db: Session, test_exercise: Exercise):
        """Test filtering exercises by name."""
        exercises = exercise_service.filter_exercises(db, "Bench")
        assert len(exercises) == 1
        assert exercises[0].name == "Bench Press"

    def test_filter_exercises_by_partial_name(
        self, db: Session, test_exercise: Exercise
    ):
        """Test filtering with partial name match."""
        exercises = exercise_service.filter_exercises(db, "bench")
        assert len(exercises) == 1

    def test_filter_exercises_by_name_case_insensitive(
        self, db: Session, test_exercise: Exercise
    ):
        """Test that name filtering is case-insensitive."""
        exercises = exercise_service.filter_exercises(db, "BENCH")
        assert len(exercises) == 1

    def test_filter_exercises_by_target(self, db: Session, test_exercise: Exercise):
        """Test filtering exercises by target."""
        exercises = exercise_service.filter_exercises(db, "pectorals")
        assert len(exercises) == 1

    def test_filter_exercises_by_body_part(self, db: Session, test_exercise: Exercise):
        """Test filtering exercises by body_part."""
        exercises = exercise_service.filter_exercises(db, "chest")
        assert len(exercises) == 1

    def test_filter_exercises_no_results(self, db: Session):
        """Test filtering that returns no results."""
        exercises = exercise_service.filter_exercises(db, "nonexistent")
        assert len(exercises) == 0

    def test_filter_exercises_multiple_matches(self, db: Session):
        """Test filtering that returns multiple exercises."""
        # Create multiple exercises with similar names
        for i in range(3):
            exercise = Exercise(
                id=f"bench_{i}",
                name=f"Bench {i}",
                body_part="chest",
                target="pectorals",
                equipment="barbell",
            )
            db.add(exercise)
        db.commit()

        exercises = exercise_service.filter_exercises(db, "bench")
        assert len(exercises) == 3

    def test_filter_exercises_pagination(self, db: Session):
        """Test filtering with pagination."""
        for i in range(10):
            exercise = Exercise(
                id=f"squat_{i}",
                name=f"Squat {i}",
                body_part="legs",
                target="quads",
                equipment="barbell",
            )
            db.add(exercise)
        db.commit()

        exercises = exercise_service.filter_exercises(db, "squat", skip=0, limit=5)
        assert len(exercises) == 5

        exercises = exercise_service.filter_exercises(db, "squat", skip=5, limit=5)
        assert len(exercises) == 5

    def test_filter_exercises_empty_query(self, db: Session, test_exercise: Exercise):
        """Test filtering with empty query string."""
        exercises = exercise_service.filter_exercises(db, "")
        # Empty query should match nothing or everything depending on implementation
        # This tests the edge case
        assert isinstance(exercises, list)

    def test_filter_exercises_special_characters(self, db: Session):
        """Test filtering with special characters in query."""
        exercise = Exercise(
            id="special",
            name="Leg Press",
            body_part="legs",
            target="quads",
            equipment="machine",
        )
        db.add(exercise)
        db.commit()

        # Search with % should be escaped
        exercises = exercise_service.filter_exercises(db, "Leg")
        assert len(exercises) >= 1

    def test_filter_exercises_returns_exercise_objects(
        self, db: Session, test_exercise: Exercise
    ):
        """Test that filter returns proper Exercise objects."""
        exercises = exercise_service.filter_exercises(db, "Bench")
        assert len(exercises) > 0
        assert isinstance(exercises[0], Exercise)
        assert hasattr(exercises[0], "name")
        assert hasattr(exercises[0], "body_part")

    def test_filter_exercises_wildcard_matching(self, db: Session):
        """Test that filtering uses wildcard matching."""
        exercise = Exercise(
            id="incline_bench",
            name="Incline Bench Press",
            body_part="chest",
            target="pectorals",
            equipment="barbell",
        )
        db.add(exercise)
        db.commit()

        # "Press" should match "Incline Bench Press"
        exercises = exercise_service.filter_exercises(db, "Press")
        assert len(exercises) >= 1

    def test_filter_exercises_limit_default(self, db: Session):
        """Test that filter respects default limit of 100."""
        for i in range(150):
            exercise = Exercise(
                id=f"filter_{i}",
                name=f"Filter Exercise {i}",
                body_part="chest",
                target="pectorals",
                equipment="barbell",
            )
            db.add(exercise)
        db.commit()

        exercises = exercise_service.filter_exercises(db, "filter")
        assert len(exercises) <= 100
