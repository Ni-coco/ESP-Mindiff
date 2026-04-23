"""
Tests for workout endpoints (app/api/workout.py).

Tests cover:
- Getting current week workout
- Pinning workouts
- Regenerating workouts
- Custom workout CRUD operations
- Authorization checks
"""

import datetime
from http import HTTPStatus

import pytest
from fastapi.testclient import TestClient


class TestGetCurrentWorkout:
    """Tests for GET /user/{user_id}/workout/current endpoint."""

    def test_get_current_workout_success(
        self,
        client: TestClient,
        auth_headers: dict,
        test_user,
        test_exercise,
        test_leg_exercise,
        db,
    ):
        """Test getting current week workout."""
        response = client.get(
            f"/api/user/{test_user.id}/workout/current",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "id" in data
        assert "sessions" in data
        assert "year" in data
        assert "week_number" in data

    def test_get_current_workout_requires_auth(self, client: TestClient, test_user):
        """Test getting current workout requires authentication."""
        response = client.get(f"/api/user/{test_user.id}/workout/current")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_workout_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot get other user's workout."""
        from app.core.security import get_password_hash
        from app.models.user import User

        other_user = User(
            email="other@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
        )
        db.add(other_user)
        db.commit()

        response = client.get(
            f"/api/user/{other_user.id}/workout/current",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_get_current_workout_superuser_can_access_other(
        self,
        client: TestClient,
        superuser_auth_headers: dict,
        test_user,
        test_exercise,
        test_leg_exercise,
    ):
        """Test that superuser can get other user's workout."""
        response = client.get(
            f"/api/user/{test_user.id}/workout/current",
            headers=superuser_auth_headers,
        )
        assert response.status_code == HTTPStatus.OK

    def test_get_current_workout_generates_if_not_exists(
        self,
        client: TestClient,
        auth_headers: dict,
        test_user,
        test_exercise,
        test_leg_exercise,
        db,
    ):
        """Test that workout is generated if it doesn't exist."""
        from app.models.workout import WorkoutWeek

        # Clear existing workouts
        today = datetime.date.today()
        iso = today.isocalendar()
        db.query(WorkoutWeek).filter(
            WorkoutWeek.user_id == test_user.id,
            WorkoutWeek.year == iso.year,
            WorkoutWeek.week_number == iso.week,
        ).delete()
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/workout/current",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data["sessions"]) > 0


class TestPinWorkout:
    """Tests for POST /user/{user_id}/workout/current/pin endpoint."""

    def test_pin_workout_success(
        self, client: TestClient, auth_headers: dict, test_user, test_workout_week
    ):
        """Test pinning a workout."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/current/pin",
            headers=auth_headers,
            json={"workout_week_id": test_workout_week.id},
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["is_pinned"] is True

    def test_pin_workout_requires_auth(self, client: TestClient, test_user):
        """Test pinning workout requires authentication."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/current/pin",
            json={"workout_week_id": 1},
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_pin_workout_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, test_workout_week, db
    ):
        """Test that user cannot pin other user's workout."""
        from app.core.security import get_password_hash
        from app.models.user import User

        other_user = User(
            email="other@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
        )
        db.add(other_user)
        db.commit()

        response = client.post(
            f"/api/user/{other_user.id}/workout/current/pin",
            headers=auth_headers,
            json={"workout_week_id": test_workout_week.id},
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_pin_nonexistent_workout(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test pinning non-existent workout."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/current/pin",
            headers=auth_headers,
            json={"workout_week_id": 99999},
        )
        assert response.status_code == HTTPStatus.NOT_FOUND


class TestRegenerateWorkout:
    """Tests for POST /user/{user_id}/workout/regenerate endpoint."""

    def test_regenerate_workout_success(
        self,
        client: TestClient,
        auth_headers: dict,
        test_user,
        test_exercise,
        test_leg_exercise,
    ):
        """Test regenerating a workout."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/regenerate",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "id" in data
        assert "sessions" in data

    def test_regenerate_workout_requires_auth(self, client: TestClient, test_user):
        """Test regenerating workout requires authentication."""
        response = client.post(f"/api/user/{test_user.id}/workout/regenerate")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_regenerate_workout_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot regenerate other user's workout."""
        from app.core.security import get_password_hash
        from app.models.user import User

        other_user = User(
            email="other@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
        )
        db.add(other_user)
        db.commit()

        response = client.post(
            f"/api/user/{other_user.id}/workout/regenerate",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_regenerate_workout_respects_pinned(
        self, client: TestClient, auth_headers: dict, test_user, test_workout_week
    ):
        """Test that regenerating doesn't override pinned workouts."""
        # Pin the workout
        client.post(
            f"/api/user/{test_user.id}/workout/current/pin",
            headers=auth_headers,
            json={"workout_week_id": test_workout_week.id},
        )

        # Try to regenerate
        response = client.post(
            f"/api/user/{test_user.id}/workout/regenerate",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        # Should return the pinned workout
        assert data["is_pinned"] is True


class TestListCustomWorkouts:
    """Tests for GET /user/{user_id}/workout/custom endpoint."""

    def test_list_custom_workouts_success(
        self, client: TestClient, auth_headers: dict, test_user, test_custom_workout
    ):
        """Test listing custom workouts."""
        response = client.get(
            f"/api/user/{test_user.id}/workout/custom",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_list_custom_workouts_requires_auth(self, client: TestClient, test_user):
        """Test listing custom workouts requires authentication."""
        response = client.get(f"/api/user/{test_user.id}/workout/custom")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_list_custom_workouts_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot list other user's custom workouts."""
        from app.core.security import get_password_hash
        from app.models.user import User

        other_user = User(
            email="other@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
        )
        db.add(other_user)
        db.commit()

        response = client.get(
            f"/api/user/{other_user.id}/workout/custom",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_list_custom_workouts_empty(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test listing custom workouts when none exist."""
        from app.models.workout import CustomWorkout

        # Clear custom workouts
        db.query(CustomWorkout).filter(CustomWorkout.user_id == test_user.id).delete()
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/workout/custom",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data == []


class TestCreateCustomWorkout:
    """Tests for POST /user/{user_id}/workout/custom endpoint."""

    def test_create_custom_workout_success(
        self, client: TestClient, auth_headers: dict, test_user, test_exercise
    ):
        """Test creating a custom workout."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/custom",
            headers=auth_headers,
            json={
                "name": "My Strength Routine",
                "exercises": [
                    {
                        "exercise_id": test_exercise.id,
                        "position": 0,
                        "sets": 4,
                        "reps_min": 5,
                        "reps_max": 8,
                    }
                ],
            },
        )
        assert response.status_code == HTTPStatus.CREATED
        data = response.json()
        assert data["name"] == "My Strength Routine"
        assert len(data["exercises"]) == 1

    def test_create_custom_workout_requires_auth(self, client: TestClient, test_user):
        """Test creating custom workout requires authentication."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/custom",
            json={
                "name": "My Routine",
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_create_custom_workout_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot create workout for other user."""
        from app.core.security import get_password_hash
        from app.models.user import User

        other_user = User(
            email="other@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
        )
        db.add(other_user)
        db.commit()

        response = client.post(
            f"/api/user/{other_user.id}/workout/custom",
            headers=auth_headers,
            json={
                "name": "My Routine",
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_create_custom_workout_empty_exercises(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test creating custom workout with no exercises."""
        response = client.post(
            f"/api/user/{test_user.id}/workout/custom",
            headers=auth_headers,
            json={
                "name": "Empty Routine",
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.CREATED
        data = response.json()
        assert len(data["exercises"]) == 0


class TestDeleteCustomWorkout:
    """Tests for DELETE /user/{user_id}/workout/custom/{workout_id} endpoint."""

    def test_delete_custom_workout_success(
        self, client: TestClient, auth_headers: dict, test_user, test_custom_workout
    ):
        """Test deleting a custom workout."""
        response = client.delete(
            f"/api/user/{test_user.id}/workout/custom/{test_custom_workout.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.NO_CONTENT

    def test_delete_custom_workout_requires_auth(
        self, client: TestClient, test_user, test_custom_workout
    ):
        """Test deleting custom workout requires authentication."""
        response = client.delete(
            f"/api/user/{test_user.id}/workout/custom/{test_custom_workout.id}"
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_delete_custom_workout_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, test_custom_workout, db
    ):
        """Test that user cannot delete other user's custom workout."""
        from app.core.security import get_password_hash
        from app.models.user import User

        other_user = User(
            email="other@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
        )
        db.add(other_user)
        db.commit()

        response = client.delete(
            f"/api/user/{other_user.id}/workout/custom/{test_custom_workout.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_delete_nonexistent_custom_workout(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test deleting non-existent custom workout."""
        response = client.delete(
            f"/api/user/{test_user.id}/workout/custom/99999",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.NOT_FOUND
