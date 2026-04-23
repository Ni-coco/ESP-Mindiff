"""
Tests for weight log endpoints (app/api/weight_log.py).

Tests cover:
- Getting weight history
- Adding weight entries
- Authorization checks
- Carry-forward logic
"""

import datetime
from http import HTTPStatus

import pytest
from fastapi.testclient import TestClient


class TestWeightHistoryGet:
    """Tests for GET /api/user/{user_id}/weight-history endpoint."""

    def test_get_weight_history_success(
        self, client: TestClient, auth_headers: dict, test_user, test_weight_log
    ):
        """Test getting weight history for own user."""
        response = client.get(
            f"/api/user/{test_user.id}/weight-history",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "entries" in data
        assert isinstance(data["entries"], list)
        assert len(data["entries"]) > 0

    def test_get_weight_history_requires_auth(self, client: TestClient, test_user):
        """Test getting weight history requires authentication."""
        response = client.get(f"/api/user/{test_user.id}/weight-history")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_weight_history_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot access other user's weight history."""
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
            f"/api/user/{other_user.id}/weight-history",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_get_weight_history_superuser_can_access_other_user(
        self,
        client: TestClient,
        superuser_auth_headers: dict,
        test_user,
        test_weight_log,
    ):
        """Test that superuser can access other user's weight history."""
        response = client.get(
            f"/api/user/{test_user.id}/weight-history",
            headers=superuser_auth_headers,
        )
        assert response.status_code == HTTPStatus.OK

    def test_get_weight_history_empty(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test getting weight history when no entries exist."""
        from app.models.user import WeightLog

        # Clear any existing weight logs
        db.query(WeightLog).filter(WeightLog.user_id == test_user.id).delete()
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/weight-history",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["entries"] == []

    def test_get_weight_history_carry_forward(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that weight history fills gaps with carry-forward."""
        from app.models.user import WeightLog

        # Clear existing
        db.query(WeightLog).filter(WeightLog.user_id == test_user.id).delete()
        db.commit()

        # Add entry for 3 days ago
        three_days_ago = datetime.date.today() - datetime.timedelta(days=3)
        entry1 = WeightLog(
            user_id=test_user.id,
            date=three_days_ago,
            weight=75.0,
            source="manual",
        )
        db.add(entry1)
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/weight-history",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        entries = data["entries"]

        # Should have entries for all days from first entry to today
        assert len(entries) >= 4
        # First entry should be the real one
        assert entries[0]["weight"] == 75.0
        assert entries[0]["source"] == "manual"
        # Following days should be carry-forward
        assert entries[1]["weight"] == 75.0
        assert entries[1]["source"] == "carried_forward"


class TestWeightAdd:
    """Tests for POST /api/user/{user_id}/weight endpoint."""

    def test_add_weight_success(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test adding a weight entry."""
        response = client.post(
            f"/api/user/{test_user.id}/weight",
            headers=auth_headers,
            json={
                "weight": 76.5,
                "source": "manual",
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["weight"] == 76.5
        assert data["source"] == "manual"
        assert data["date"] == str(datetime.date.today())

    def test_add_weight_requires_auth(self, client: TestClient, test_user):
        """Test adding weight requires authentication."""
        response = client.post(
            f"/api/user/{test_user.id}/weight",
            json={
                "weight": 76.5,
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_add_weight_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot add weight for other user."""
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
            f"/api/user/{other_user.id}/weight",
            headers=auth_headers,
            json={"weight": 76.5},
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_add_weight_superuser_can_add_for_other_user(
        self, client: TestClient, superuser_auth_headers: dict, test_user
    ):
        """Test that superuser can add weight for other user."""
        response = client.post(
            f"/api/user/{test_user.id}/weight",
            headers=superuser_auth_headers,
            json={"weight": 76.5},
        )
        assert response.status_code == HTTPStatus.OK

    def test_add_weight_default_source(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test adding weight with default source."""
        response = client.post(
            f"/api/user/{test_user.id}/weight",
            headers=auth_headers,
            json={"weight": 77.0},
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["source"] == "manual"

    def test_add_weight_upsert(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that adding weight for same date updates existing entry."""
        today = datetime.date.today()

        # Add first entry
        response1 = client.post(
            f"/api/user/{test_user.id}/weight",
            headers=auth_headers,
            json={"weight": 75.0},
        )
        assert response1.status_code == HTTPStatus.OK

        # Add second entry for same day (should update)
        response2 = client.post(
            f"/api/user/{test_user.id}/weight",
            headers=auth_headers,
            json={"weight": 75.5},
        )
        assert response2.status_code == HTTPStatus.OK

        # Verify only one entry exists
        from app.models.user import WeightLog

        entries = (
            db.query(WeightLog)
            .filter(WeightLog.user_id == test_user.id, WeightLog.date == today)
            .all()
        )
        assert len(entries) == 1
        assert entries[0].weight == 75.5

    def test_add_weight_different_dates(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test adding weight entries for different dates."""
        yesterday = datetime.date.today() - datetime.timedelta(days=1)

        # Add entry for today
        response1 = client.post(
            f"/api/user/{test_user.id}/weight",
            headers=auth_headers,
            json={"weight": 75.0},
        )
        assert response1.status_code == HTTPStatus.OK

        # Add entry for yesterday (manual API call to add different date)
        from app.models.user import WeightLog

        entry = WeightLog(
            user_id=test_user.id,
            date=yesterday,
            weight=74.5,
            source="manual",
        )
        db.add(entry)
        db.commit()

        # Verify both entries exist
        entries = (
            db.query(WeightLog)
            .filter(WeightLog.user_id == test_user.id)
            .order_by(WeightLog.date)
            .all()
        )
        assert len(entries) == 2
