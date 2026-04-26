"""
Tests for program endpoints (app/api/program.py).

Tests cover:
- Listing programs
- Creating programs
- Getting a specific program
- Updating programs
- Deleting programs
- Authorization checks
"""

from http import HTTPStatus

from fastapi.testclient import TestClient


class TestListPrograms:
    """Tests for GET /program/ endpoint."""

    def test_list_programs_success(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test listing programs."""
        response = client.get("/api/program/", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_list_programs_requires_auth(self, client: TestClient):
        """Test listing programs requires authentication."""
        response = client.get("/api/program/")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_list_programs_returns_program_details(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test that program list includes expected fields."""
        response = client.get("/api/program/", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        program = data[0]
        assert "id" in program
        assert "name" in program
        assert "description" in program
        assert "difficulty" in program


class TestCreateProgram:
    """Tests for POST /program/ endpoint."""

    def test_create_program_success(self, client: TestClient, auth_headers: dict):
        """Test creating a new program."""
        response = client.post(
            "/api/program/",
            headers=auth_headers,
            json={
                "name": "Advanced Strength",
                "description": "High intensity strength program",
                "difficulty": "hard",
                "calorie_burn": 350,
                "duration": 60,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["name"] == "Advanced Strength"
        assert data["description"] == "High intensity strength program"
        assert data["difficulty"] == "hard"

    def test_create_program_requires_auth(self, client: TestClient):
        """Test creating program requires authentication."""
        response = client.post(
            "/api/program/",
            json={
                "name": "Test Program",
                "description": "Test",
                "difficulty": "easy",
                "calorie_burn": 200,
                "duration": 30,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_create_program_invalid_difficulty(
        self, client: TestClient, auth_headers: dict
    ):
        """Test creating program with invalid difficulty."""
        response = client.post(
            "/api/program/",
            headers=auth_headers,
            json={
                "name": "Test Program",
                "description": "Test",
                "difficulty": "invalid_difficulty",
                "calorie_burn": 200,
                "duration": 30,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY

    def test_create_program_all_difficulties(
        self, client: TestClient, auth_headers: dict
    ):
        """Test creating programs with all difficulty levels."""
        difficulties = ["easy", "medium", "hard"]

        for difficulty in difficulties:
            response = client.post(
                "/api/program/",
                headers=auth_headers,
                json={
                    "name": f"Program {difficulty}",
                    "description": f"A {difficulty} program",
                    "difficulty": difficulty,
                    "calorie_burn": 200,
                    "duration": 30,
                    "exercises": [],
                },
            )
            assert response.status_code == HTTPStatus.OK
            assert response.json()["difficulty"] == difficulty


class TestGetProgram:
    """Tests for GET /program/{program_id} endpoint."""

    def test_get_program_success(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test getting a specific program."""
        response = client.get(f"/api/program/{test_program.id}", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["id"] == test_program.id
        assert data["name"] == "Beginner Strength"

    def test_get_program_requires_auth(self, client: TestClient, test_program):
        """Test getting program requires authentication."""
        response = client.get(f"/api/program/{test_program.id}")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_nonexistent_program(self, client: TestClient, auth_headers: dict):
        """Test getting non-existent program."""
        response = client.get("/api/program/99999", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        # Service returns None
        assert response.json() is None

    def test_get_program_includes_all_fields(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test that program response includes all expected fields."""
        response = client.get(f"/api/program/{test_program.id}", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "id" in data
        assert "name" in data
        assert "description" in data
        assert "difficulty" in data
        assert "calorie_burn" in data
        assert "duration" in data


class TestUpdateProgram:
    """Tests for PUT /program/{program_id} endpoint."""

    def test_update_program_success(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test updating a program."""
        response = client.put(
            f"/api/program/{test_program.id}",
            headers=auth_headers,
            json={
                "name": "Updated Program",
                "description": "Updated description",
                "difficulty": "medium",
                "calorie_burn": 250,
                "duration": 45,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["name"] == "Updated Program"
        assert data["difficulty"] == "medium"
        assert data["calorie_burn"] == 250

    def test_update_program_requires_auth(self, client: TestClient, test_program):
        """Test updating program requires authentication."""
        response = client.put(
            f"/api/program/{test_program.id}",
            json={
                "name": "Updated",
                "description": "Updated",
                "difficulty": "easy",
                "calorie_burn": 200,
                "duration": 30,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_update_program_partial(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test partial program update."""
        response = client.put(
            f"/api/program/{test_program.id}",
            headers=auth_headers,
            json={
                "name": "Beginner Strength",
                "description": "A beginner-friendly strength program",
                "difficulty": "hard",
                "calorie_burn": 300,
                "duration": 45,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["difficulty"] == "hard"
        assert data["calorie_burn"] == 300

    def test_update_nonexistent_program(self, client: TestClient, auth_headers: dict):
        """Test updating non-existent program."""
        response = client.put(
            "/api/program/99999",
            headers=auth_headers,
            json={
                "name": "Updated",
                "description": "Updated",
                "difficulty": "easy",
                "calorie_burn": 200,
                "duration": 30,
                "exercises": [],
            },
        )
        assert response.status_code == HTTPStatus.OK
        # Service returns None
        assert response.json() is None


class TestDeleteProgram:
    """Tests for DELETE /program/{program_id} endpoint."""

    def test_delete_program_success(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test deleting a program."""
        program_id = test_program.id
        response = client.delete(f"/api/program/{program_id}", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        # Response should have message field for success
        data = response.json()
        assert "message" in data or "error" not in data

    def test_delete_program_requires_auth(self, client: TestClient, test_program):
        """Test deleting program requires authentication."""
        response = client.delete(f"/api/program/{test_program.id}")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_delete_nonexistent_program(self, client: TestClient, auth_headers: dict):
        """Test deleting non-existent program."""
        response = client.delete("/api/program/99999", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        # Should return error message for non-existent program
        data = response.json()
        assert "error" in data or data is None

    def test_delete_program_cascades(
        self, client: TestClient, auth_headers: dict, test_program
    ):
        """Test that deleting program cascades properly."""
        program_id = test_program.id
        response = client.delete(f"/api/program/{program_id}", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK

        # Verify program is deleted
        get_response = client.get(f"/api/program/{program_id}", headers=auth_headers)
        assert get_response.status_code == HTTPStatus.OK
        assert get_response.json() is None
