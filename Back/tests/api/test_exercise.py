"""
Tests for exercise endpoints (app/api/exercise.py).

Tests cover:
- Listing exercises with pagination
- Filtering exercises by body part, equipment, target
- Counting exercises
- Getting single exercise by ID
- Error handling for not found
"""

from http import HTTPStatus

from fastapi.testclient import TestClient


class TestExerciseList:
    """Tests for GET /api/exercise/ endpoint."""

    def test_list_exercises_success(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test listing exercises successfully."""
        response = client.get("/api/exercise/", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_list_exercises_with_pagination(
        self,
        client: TestClient,
        auth_headers: dict,
        test_exercise,
        test_leg_exercise,
        db,
    ):
        """Test listing exercises with skip and limit."""
        response = client.get(
            "/api/exercise/?skip=0&limit=1",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data) <= 1

    def test_list_exercises_filter_by_body_part(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by body part."""
        response = client.get(
            "/api/exercise/?body_part=chest",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert all(ex["body_part"] == "chest" for ex in data)

    def test_list_exercises_filter_by_target(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by target muscle."""
        response = client.get(
            "/api/exercise/?target=pectorals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert all(ex["target"] == "pectorals" for ex in data)

    def test_list_exercises_filter_by_equipment(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by equipment."""
        response = client.get(
            "/api/exercise/?equipment=barbell",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert all(ex["equipment"] == "barbell" for ex in data)

    def test_list_exercises_filter_by_secondary_muscle(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by secondary muscle."""
        response = client.get(
            "/api/exercise/?secondary_muscle=triceps",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        # Should find bench press which has triceps as secondary
        assert len(data) >= 1

    def test_list_exercises_requires_authentication(self, client: TestClient):
        """Test that listing exercises requires authentication."""
        response = client.get("/api/exercise/")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_list_exercises_limit_validation(
        self, client: TestClient, auth_headers: dict
    ):
        """Test that limit parameter is validated."""
        response = client.get(
            "/api/exercise/?limit=1000",  # Exceeds max of 500
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY

    def test_list_exercises_skip_validation(
        self, client: TestClient, auth_headers: dict
    ):
        """Test that skip parameter must be non-negative."""
        response = client.get(
            "/api/exercise/?skip=-1",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY


class TestExerciseCount:
    """Tests for GET /api/exercise/count endpoint."""

    def test_count_exercises_success(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test counting exercises successfully."""
        response = client.get("/api/exercise/count", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "count" in data
        assert isinstance(data["count"], int)
        assert data["count"] >= 1

    def test_count_exercises_filter_by_body_part(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test counting exercises filtered by body part."""
        response = client.get(
            "/api/exercise/count?body_part=chest",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["count"] >= 1

    def test_count_exercises_filter_by_target(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test counting exercises filtered by target."""
        response = client.get(
            "/api/exercise/count?target=pectorals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["count"] >= 1

    def test_count_exercises_filter_by_equipment(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test counting exercises filtered by equipment."""
        response = client.get(
            "/api/exercise/count?equipment=barbell",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["count"] >= 1

    def test_count_exercises_no_matches(self, client: TestClient, auth_headers: dict):
        """Test counting exercises with no matches."""
        response = client.get(
            "/api/exercise/count?body_part=nonexistent",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["count"] == 0

    def test_count_exercises_requires_authentication(self, client: TestClient):
        """Test that counting exercises requires authentication."""
        response = client.get("/api/exercise/count")
        assert response.status_code == HTTPStatus.UNAUTHORIZED


class TestExerciseFilter:
    """Tests for GET /api/exercise/filter endpoint."""

    def test_filter_exercises_by_name(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by name."""
        response = client.get(
            "/api/exercise/filter?q=bench",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data) >= 1
        assert any("bench" in ex["name"].lower() for ex in data)

    def test_filter_exercises_by_target(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by target muscle."""
        response = client.get(
            "/api/exercise/filter?q=pectorals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data) >= 1

    def test_filter_exercises_by_body_part(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises by body part."""
        response = client.get(
            "/api/exercise/filter?q=chest",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data) >= 1

    def test_filter_exercises_case_insensitive(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test that filtering is case-insensitive."""
        response = client.get(
            "/api/exercise/filter?q=BENCH",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data) >= 1

    def test_filter_exercises_with_pagination(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test filtering exercises with skip and limit."""
        response = client.get(
            "/api/exercise/filter?q=bench&skip=0&limit=1",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert len(data) <= 1

    def test_filter_exercises_empty_query(self, client: TestClient, auth_headers: dict):
        """Test filtering with empty query fails validation."""
        response = client.get(
            "/api/exercise/filter?q=",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY

    def test_filter_exercises_no_query(self, client: TestClient, auth_headers: dict):
        """Test filtering without query fails validation."""
        response = client.get(
            "/api/exercise/filter",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY

    def test_filter_exercises_requires_authentication(self, client: TestClient):
        """Test that filtering exercises requires authentication."""
        response = client.get("/api/exercise/filter?q=bench")
        assert response.status_code == HTTPStatus.UNAUTHORIZED


class TestExerciseGetById:
    """Tests for GET /api/exercise/{exercise_id} endpoint."""

    def test_get_exercise_success(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test getting a specific exercise by ID."""
        response = client.get(
            f"/api/exercise/{test_exercise.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["id"] == "bench_press_001"
        assert data["name"] == "Bench Press"
        assert data["body_part"] == "chest"
        assert data["target"] == "pectorals"

    def test_get_exercise_includes_instructions(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test that exercise response includes instructions."""
        response = client.get(
            f"/api/exercise/{test_exercise.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "instructions" in data
        assert len(data["instructions"]) == 2
        assert data["instructions"][0]["text"] == "Lie on bench"

    def test_get_exercise_includes_secondary_muscles(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test that exercise response includes secondary muscles."""
        response = client.get(
            f"/api/exercise/{test_exercise.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "secondary_muscles" in data
        assert len(data["secondary_muscles"]) == 1
        assert data["secondary_muscles"][0]["name"] == "triceps"

    def test_get_exercise_not_found(self, client: TestClient, auth_headers: dict):
        """Test getting non-existent exercise."""
        response = client.get(
            "/api/exercise/nonexistent_id",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.NOT_FOUND
        assert "Exercise not found" in response.json()["detail"]

    def test_get_exercise_requires_authentication(
        self, client: TestClient, test_exercise
    ):
        """Test that getting exercise requires authentication."""
        response = client.get(f"/api/exercise/{test_exercise.id}")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_cardio_exercise(
        self, client: TestClient, auth_headers: dict, test_cardio_exercise
    ):
        """Test getting a cardio exercise."""
        response = client.get(
            f"/api/exercise/{test_cardio_exercise.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["body_part"] == "cardio"
        assert data["target"] is None

    def test_get_exercise_with_gif_url(
        self, client: TestClient, auth_headers: dict, test_exercise
    ):
        """Test that exercise response includes gif_url."""
        response = client.get(
            f"/api/exercise/{test_exercise.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "gif_url" in data
        assert data["gif_url"] == "https://example.com/bench_press.gif"
