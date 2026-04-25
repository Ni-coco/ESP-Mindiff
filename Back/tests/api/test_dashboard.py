"""
Tests for dashboard endpoints (app/api/dashboard.py).

Tests cover:
- Getting meal suggestions with TDEE calculation
- Authorization checks
- Error handling for missing users
"""

from http import HTTPStatus
from unittest.mock import patch

from fastapi.testclient import TestClient


class TestGetMealSuggestions:
    """Tests for GET /user/{user_id}/dashboard/meal-suggestions endpoint."""

    def test_get_meal_suggestions_success(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test getting meal suggestions."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 2500,
                "consumed_today": 1000,
                "remaining": 1500,
                "suggestions": [
                    {
                        "meal_type": "lunch",
                        "label": "Chicken Rice",
                        "calories": 500,
                        "protein_g": 35.0,
                        "fat_g": 15.0,
                        "carbs_g": 50.0,
                        "fiber_g": 3.0,
                        "servings": 2,
                        "image_url": "https://example.com/image.jpg",
                        "recipe_url": "https://example.com/recipe",
                        "source": "Edamam",
                        "ingredient_lines": [],
                    }
                ],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.OK
            data = response.json()
            assert "tdee" in data
            assert "consumed_today" in data
            assert "remaining" in data
            assert "suggestions" in data

    def test_get_meal_suggestions_requires_auth(self, client: TestClient, test_user):
        """Test getting meal suggestions requires authentication."""
        response = client.get(f"/api/user/{test_user.id}/dashboard/meal-suggestions")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_meal_suggestions_forbidden_for_other_user(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that user cannot get suggestions for other user."""
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
            f"/api/user/{other_user.id}/dashboard/meal-suggestions",
            headers=auth_headers,
        )
        assert response.status_code == HTTPStatus.FORBIDDEN

    def test_get_meal_suggestions_superuser_can_access_other(
        self, client: TestClient, superuser_auth_headers: dict, test_user
    ):
        """Test that superuser can get suggestions for other user."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 2500,
                "consumed_today": 0,
                "remaining": 2500,
                "suggestions": [],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=superuser_auth_headers,
            )
            assert response.status_code == HTTPStatus.OK

    def test_get_meal_suggestions_user_not_found(
        self, client: TestClient, auth_headers: dict
    ):
        """Test getting suggestions for non-existent user."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.side_effect = ValueError("User introuvable")

            response = client.get(
                "/api/user/99999/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.NOT_FOUND

    def test_get_meal_suggestions_with_no_metrics(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test getting suggestions when user has no metrics."""
        from app.models.user import UserMetrics

        # Clear metrics
        db.query(UserMetrics).filter(UserMetrics.user_id == test_user.id).delete()
        db.commit()

        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 0,
                "consumed_today": 0,
                "remaining": 0,
                "suggestions": [],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.OK

    def test_get_meal_suggestions_includes_all_fields(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test that suggestions include all expected fields."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 2500,
                "consumed_today": 800,
                "remaining": 1700,
                "suggestions": [
                    {
                        "meal_type": "lunch",
                        "label": "Grilled Salmon",
                        "calories": 450,
                        "protein_g": 40.0,
                        "fat_g": 20.0,
                        "carbs_g": 30.0,
                        "fiber_g": 2.0,
                        "servings": 2,
                        "image_url": "https://example.com/salmon.jpg",
                        "recipe_url": "https://example.com/salmon_recipe",
                        "source": "Edamam",
                        "ingredient_lines": ["Salmon fillet", "Lemon"],
                    }
                ],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.OK
            data = response.json()

            # Check top-level fields
            assert data["tdee"] == 2500
            assert data["consumed_today"] == 800
            assert data["remaining"] == 1700

            # Check suggestions
            assert len(data["suggestions"]) == 1
            suggestion = data["suggestions"][0]
            assert suggestion["meal_type"] == "lunch"
            assert suggestion["label"] == "Grilled Salmon"
            assert suggestion["calories"] == 450
            assert suggestion["protein_g"] == 40.0
            assert suggestion["fat_g"] == 20.0
            assert suggestion["carbs_g"] == 30.0
            assert suggestion["fiber_g"] == 2.0
            assert suggestion["servings"] == 2

    def test_get_meal_suggestions_no_suggestions_when_full(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test that no suggestions returned when daily goal is met."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 2500,
                "consumed_today": 2500,
                "remaining": 0,
                "suggestions": [],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.OK
            data = response.json()
            assert data["remaining"] == 0
            assert data["suggestions"] == []

    def test_get_meal_suggestions_multiple_suggestions(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test getting multiple meal suggestions."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 2500,
                "consumed_today": 500,
                "remaining": 2000,
                "suggestions": [
                    {
                        "meal_type": "lunch",
                        "label": "Chicken Salad",
                        "calories": 600,
                        "protein_g": 45.0,
                        "fat_g": 15.0,
                        "carbs_g": 50.0,
                        "fiber_g": 5.0,
                        "servings": 1,
                        "image_url": "https://example.com/salad.jpg",
                        "recipe_url": "https://example.com/salad_recipe",
                        "source": "Edamam",
                        "ingredient_lines": [],
                    },
                    {
                        "meal_type": "snack",
                        "label": "Greek Yogurt",
                        "calories": 150,
                        "protein_g": 20.0,
                        "fat_g": 3.0,
                        "carbs_g": 10.0,
                        "fiber_g": 0.0,
                        "servings": 1,
                        "image_url": "https://example.com/yogurt.jpg",
                        "recipe_url": "https://example.com/yogurt_recipe",
                        "source": "Edamam",
                        "ingredient_lines": [],
                    },
                ],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.OK
            data = response.json()
            assert len(data["suggestions"]) == 2

    def test_get_meal_suggestions_considers_goal(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test that suggestions consider user's sport objective."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.return_value = {
                "tdee": 2500,
                "consumed_today": 0,
                "remaining": 2500,
                "suggestions": [
                    {
                        "meal_type": "lunch",
                        "label": "Chicken Rice - High Protein",
                        "calories": 700,
                        "protein_g": 60.0,
                        "fat_g": 15.0,
                        "carbs_g": 70.0,
                        "fiber_g": 3.0,
                        "servings": 2,
                        "image_url": "https://example.com/hprotein.jpg",
                        "recipe_url": "https://example.com/recipe",
                        "source": "Edamam",
                        "ingredient_lines": [],
                    }
                ],
            }

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.OK
            data = response.json()
            # Should get high-protein suggestions for build_muscle goal
            assert data["suggestions"][0]["protein_g"] == 60.0

    def test_get_meal_suggestions_service_value_error(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test handling of ValueError from service (lines 31-32)."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            # Service raises ValueError
            mock_suggestions.side_effect = ValueError("Unable to calculate metrics")

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.NOT_FOUND
            assert "Unable to calculate metrics" in response.json()["detail"]

    def test_get_meal_suggestions_service_value_error_user_metrics(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test ValueError when user has no metrics."""
        with patch(
            "app.services.meal_suggestions.get_meal_suggestions"
        ) as mock_suggestions:
            mock_suggestions.side_effect = ValueError("User has no metrics")

            response = client.get(
                f"/api/user/{test_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.NOT_FOUND
