"""
Tests for meal endpoints (app/api/meals.py).

Tests cover:
- Adding meals with Edamam integration
- Getting daily meals summary
- Deleting meals
- Authorization checks
- Edamam API error handling
"""

import datetime
from http import HTTPStatus
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient


class TestAddMeal:
    """Tests for POST /api/user/{user_id}/meals endpoint."""

    def test_add_meal_with_manual_nutrition(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test adding meal with manually provided nutrition."""
        response = client.post(
            f"/api/user/{test_user.id}/meals",
            headers=auth_headers,
            json={
                "meal_type": "lunch",
                "description": "Chicken with rice",
                "calories": 650.0,
                "protein_g": 45.0,
                "fat_g": 15.0,
                "carbs_g": 65.0,
                "fiber_g": 3.0,
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["meal_type"] == "lunch"
        assert data["description"] == "Chicken with rice"
        assert data["calories"] == 650.0
        assert data["date"] == str(datetime.date.today())

    def test_add_meal_with_edamam_api(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test adding meal with Edamam API analysis."""
        with patch("app.services.edamam.analyze_nutrition") as mock_edamam:
            mock_edamam.return_value = {
                "calories": 450.0,
                "protein_g": 30.0,
                "fat_g": 12.0,
                "carbs_g": 50.0,
                "fiber_g": 2.5,
            }

            response = client.post(
                f"/api/user/{test_user.id}/meals",
                headers=auth_headers,
                json={
                    "meal_type": "breakfast",
                    "description": "Oatmeal with berries",
                },
            )
            assert response.status_code == HTTPStatus.OK
            data = response.json()
            assert data["meal_type"] == "breakfast"
            assert data["calories"] == 450.0

    def test_add_meal_requires_auth(self, client: TestClient, test_user):
        """Test adding meal requires authentication."""
        response = client.post(
            f"/api/user/{test_user.id}/meals",
            json={
                "meal_type": "lunch",
                "description": "Test meal",
                "calories": 500.0,
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_add_meal_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot add meals for other user."""
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
            f"/api/user/{other_user.id}/meals",
            headers=auth_headers,
            json={
                "meal_type": "lunch",
                "description": "Test meal",
                "calories": 500.0,
            },
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_add_meal_superuser_can_add_for_other(
        self, client: TestClient, superuser_auth_headers: dict, test_user
    ):
        """Test that superuser can add meals for other user."""
        response = client.post(
            f"/api/user/{test_user.id}/meals",
            headers=superuser_auth_headers,
            json={
                "meal_type": "lunch",
                "description": "Test meal",
                "calories": 500.0,
            },
        )
        assert response.status_code == HTTPStatus.OK

    def test_add_meal_edamam_error_handling(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test handling of Edamam API errors."""
        import httpx

        with patch("app.services.edamam.analyze_nutrition") as mock_edamam:
            mock_response = MagicMock()
            mock_response.text = "API Error"
            mock_edamam.side_effect = httpx.HTTPStatusError(
                "Error", request=MagicMock(), response=mock_response
            )

            response = client.post(
                f"/api/user/{test_user.id}/meals",
                headers=auth_headers,
                json={
                    "meal_type": "lunch",
                    "description": "Test meal",
                },
            )
            assert response.status_code == HTTPStatus.SERVICE_UNAVAILABLE

    def test_add_meal_generic_error_handling(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test handling of generic errors during meal analysis."""
        with patch("app.services.edamam.analyze_nutrition") as mock_edamam:
            mock_edamam.side_effect = ValueError("Invalid response")

            response = client.post(
                f"/api/user/{test_user.id}/meals",
                headers=auth_headers,
                json={
                    "meal_type": "lunch",
                    "description": "Test meal",
                },
            )
            assert response.status_code == HTTPStatus.SERVICE_UNAVAILABLE

    def test_add_meal_with_custom_date(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test adding meal with custom date."""
        custom_date = datetime.date.today() - datetime.timedelta(days=1)
        response = client.post(
            f"/api/user/{test_user.id}/meals",
            headers=auth_headers,
            json={
                "meal_type": "lunch",
                "description": "Yesterday's meal",
                "date": str(custom_date),
                "calories": 500.0,
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["date"] == str(custom_date)

    def test_add_meal_all_types(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test adding meals of all types."""
        meal_types = ["breakfast", "lunch", "dinner", "snack"]

        for meal_type in meal_types:
            response = client.post(
                f"/api/user/{test_user.id}/meals",
                headers=auth_headers,
                json={
                    "meal_type": meal_type,
                    "description": f"Test {meal_type}",
                    "calories": 500.0,
                },
            )
            assert response.status_code == HTTPStatus.OK
            assert response.json()["meal_type"] == meal_type


class TestGetMeals:
    """Tests for GET /api/user/{user_id}/meals endpoint."""

    def test_get_meals_success(
        self, client: TestClient, auth_headers: dict, test_user, test_meal_log
    ):
        """Test getting daily meals."""
        response = client.get(
            f"/api/user/{test_user.id}/meals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "date" in data
        assert "meals" in data
        assert "total_calories" in data
        assert "total_protein_g" in data

    def test_get_meals_requires_auth(self, client: TestClient, test_user):
        """Test getting meals requires authentication."""
        response = client.get(f"/api/user/{test_user.id}/meals")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_meals_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot get other user's meals."""
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
            f"/api/user/{other_user.id}/meals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_get_meals_superuser_can_get_other(
        self, client: TestClient, superuser_auth_headers: dict, test_user, test_meal_log
    ):
        """Test that superuser can get other user's meals."""
        response = client.get(
            f"/api/user/{test_user.id}/meals",
            headers=superuser_auth_headers,
        )
        assert response.status_code == HTTPStatus.OK

    def test_get_meals_totals_calculation(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that meal totals are correctly calculated."""
        from app.models.user import MealLog

        # Add multiple meals
        today = datetime.date.today()
        meals_data = [
            ("breakfast", 300.0, 15.0, 8.0, 40.0, 2.0),
            ("lunch", 650.0, 45.0, 15.0, 65.0, 3.0),
            ("snack", 150.0, 5.0, 7.0, 20.0, 1.0),
        ]

        for meal_type, cal, prot, fat, carbs, fiber in meals_data:
            meal = MealLog(
                user_id=test_user.id,
                date=today,
                meal_type=meal_type,
                description=f"Test {meal_type}",
                calories=cal,
                protein_g=prot,
                fat_g=fat,
                carbs_g=carbs,
                fiber_g=fiber,
            )
            db.add(meal)
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/meals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["total_calories"] == 1100.0
        assert data["total_protein_g"] == 65.0
        assert data["total_fat_g"] == 30.0
        assert data["total_carbs_g"] == 125.0
        assert data["total_fiber_g"] == 6.0

    def test_get_meals_custom_date(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test getting meals for a specific date."""
        from app.models.user import MealLog

        yesterday = datetime.date.today() - datetime.timedelta(days=1)
        meal = MealLog(
            user_id=test_user.id,
            date=yesterday,
            meal_type="lunch",
            description="Yesterday meal",
            calories=500.0,
            protein_g=30.0,
            fat_g=10.0,
            carbs_g=50.0,
            fiber_g=2.0,
        )
        db.add(meal)
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/meals?date={str(yesterday)}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["date"] == str(yesterday)
        assert len(data["meals"]) == 1

    def test_get_meals_empty(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test getting meals when none exist for the date."""
        from app.models.user import MealLog

        # Clear existing meals
        db.query(MealLog).filter(MealLog.user_id == test_user.id).delete()
        db.commit()

        response = client.get(
            f"/api/user/{test_user.id}/meals",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["meals"] == []
        assert data["total_calories"] == 0.0


class TestDeleteMeal:
    """Tests for DELETE /api/user/{user_id}/meals/{meal_id} endpoint."""

    def test_delete_meal_success(
        self, client: TestClient, auth_headers: dict, test_user, test_meal_log
    ):
        """Test deleting a meal."""
        response = client.delete(
            f"/api/user/{test_user.id}/meals/{test_meal_log.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.NO_CONTENT

    def test_delete_meal_requires_auth(
        self, client: TestClient, test_user, test_meal_log
    ):
        """Test deleting meal requires authentication."""
        response = client.delete(f"/api/user/{test_user.id}/meals/{test_meal_log.id}")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_delete_meal_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, test_meal_log, db
    ):
        """Test that user cannot delete other user's meals."""
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
            f"/api/user/{other_user.id}/meals/{test_meal_log.id}",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_delete_meal_superuser_can_delete_other(
        self, client: TestClient, superuser_auth_headers: dict, test_user, test_meal_log
    ):
        """Test that superuser can delete other user's meals."""
        response = client.delete(
            f"/api/user/{test_user.id}/meals/{test_meal_log.id}",
            headers=superuser_auth_headers,
        )
        assert response.status_code == HTTPStatus.NO_CONTENT

    def test_delete_nonexistent_meal(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test deleting non-existent meal."""
        response = client.delete(
            f"/api/user/{test_user.id}/meals/99999",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.NOT_FOUND
        assert "Repas introuvable" in response.json()["detail"]
