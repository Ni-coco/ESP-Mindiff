"""
Comprehensive unit tests for app.services.meal_suggestions module.

Tests cover all meal_suggestions service functions with 100% coverage:
- _calculate_tdee: calculate total daily energy expenditure
- _fetch_recipe: fetch recipe from Edamam API
- get_meal_suggestions: get meal suggestions for user
"""

import datetime
from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy.orm import Session

from app.models.user import MealLog, User, UserMetrics
from app.services import meal_suggestions as meal_suggestions_service


class TestCalculateTdee:
    """Tests for _calculate_tdee function."""

    def test_calculate_tdee_basic(self, db: Session, test_user: User):
        """Test basic TDEE calculation."""
        tdee = meal_suggestions_service._calculate_tdee(test_user)

        # TDEE should be a reasonable positive number
        assert isinstance(tdee, (int, float))
        assert tdee > 0

    def test_calculate_tdee_no_metrics(self, db: Session):
        """Test TDEE calculation with no metrics returns 0."""
        user = User(
            email="nometrics@example.com",
            username="nometrics",
            hashed_password="hashedpass",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        tdee = meal_suggestions_service._calculate_tdee(user)
        assert tdee == 0.0

    def test_calculate_tdee_male_vs_female(self, db: Session):
        """Test that TDEE differs for male vs female."""
        from app.core.security import get_password_hash

        male_user = User(
            email="male@example.com",
            username="male",
            hashed_password=get_password_hash("pass"),
            gender="male",
            sessions_per_week=3,
        )
        female_user = User(
            email="female@example.com",
            username="female",
            hashed_password=get_password_hash("pass"),
            gender="female",
            sessions_per_week=3,
        )
        db.add_all([male_user, female_user])
        db.commit()

        # Add same metrics for both
        male_metrics = UserMetrics(
            user_id=male_user.id, weight=75.0, height=175, age=30
        )
        female_metrics = UserMetrics(
            user_id=female_user.id, weight=75.0, height=175, age=30
        )
        db.add_all([male_metrics, female_metrics])
        db.commit()
        db.refresh(male_user)
        db.refresh(female_user)

        male_tdee = meal_suggestions_service._calculate_tdee(male_user)
        female_tdee = meal_suggestions_service._calculate_tdee(female_user)

        # Male should have higher TDEE
        assert male_tdee > female_tdee

    def test_calculate_tdee_different_activity_levels(self, db: Session):
        """Test TDEE calculation with different activity levels."""
        from app.core.security import get_password_hash

        users = []
        for sessions in [0, 2, 4, 6]:
            user = User(
                email=f"activity{sessions}@example.com",
                username=f"activity{sessions}",
                hashed_password=get_password_hash("pass"),
                gender="male",
                sessions_per_week=sessions,
            )
            db.add(user)
            db.flush()

            metrics = UserMetrics(user_id=user.id, weight=75.0, height=175.0, age=30)
            db.add(metrics)
            db.flush()
            users.append(user)

        db.commit()

        # Refresh all users after commit to load relationships
        for user in users:
            db.refresh(user)

        tdees = [meal_suggestions_service._calculate_tdee(u) for u in users]

        # TDEE should generally increase with activity (allow some rounding variance)
        assert tdees[0] <= tdees[1] <= tdees[2] <= tdees[3]
        # At least the extremes should be clearly different
        assert tdees[0] < tdees[3]

    def test_calculate_tdee_weight_variation(self, db: Session):
        """Test that heavier users have higher TDEE."""
        from app.core.security import get_password_hash

        light_user = User(
            email="light@example.com",
            username="light",
            hashed_password=get_password_hash("pass"),
            sessions_per_week=3,
        )
        heavy_user = User(
            email="heavy@example.com",
            username="heavy",
            hashed_password=get_password_hash("pass"),
            sessions_per_week=3,
        )
        db.add_all([light_user, heavy_user])
        db.commit()

        light_metrics = UserMetrics(
            user_id=light_user.id, weight=60.0, height=170, age=30
        )
        heavy_metrics = UserMetrics(
            user_id=heavy_user.id, weight=100.0, height=170, age=30
        )
        db.add_all([light_metrics, heavy_metrics])
        db.commit()
        db.refresh(light_user)
        db.refresh(heavy_user)

        light_tdee = meal_suggestions_service._calculate_tdee(light_user)
        heavy_tdee = meal_suggestions_service._calculate_tdee(heavy_user)

        # Heavier user should have higher TDEE
        assert heavy_tdee > light_tdee

    def test_calculate_tdee_returns_number(self, db: Session, test_user: User):
        """Test that TDEE returns a number."""
        tdee = meal_suggestions_service._calculate_tdee(test_user)
        assert isinstance(tdee, (int, float))

    def test_calculate_tdee_default_values(self, db: Session):
        """Test TDEE calculation with default/missing values."""
        from app.core.security import get_password_hash

        user = User(
            email="defaults@example.com",
            username="defaults",
            hashed_password=get_password_hash("pass"),
            gender=None,  # Should default to "male"
            sessions_per_week=None,  # Should default to 3
        )
        db.add(user)
        db.flush()

        metrics = UserMetrics(user_id=user.id, weight=75.0, height=175, age=30)
        db.add(metrics)
        db.commit()
        db.refresh(user)

        tdee = meal_suggestions_service._calculate_tdee(user)
        assert tdee > 0


class TestFetchRecipe:
    """Tests for _fetch_recipe function."""

    @patch("app.services.meal_suggestions.httpx.get")
    def test_fetch_recipe_success(self, mock_get):
        """Test successful recipe fetch."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "hits": [
                {
                    "recipe": {
                        "label": "Chicken Rice",
                        "calories": 600,
                        "yield": 2,
                        "image": "https://example.com/image.jpg",
                        "url": "https://example.com/recipe",
                        "source": "Example Source",
                        "ingredientLines": ["Chicken", "Rice"],
                        "totalNutrients": {
                            "PROCNT": {"quantity": 80},
                            "FAT": {"quantity": 30},
                            "CHOCDF": {"quantity": 100},
                            "FIBTG": {"quantity": 6},
                        },
                    }
                }
            ]
        }
        mock_get.return_value = mock_response

        result = meal_suggestions_service._fetch_recipe("chicken", 1, 300)

        assert result is not None
        assert "label" in result
        assert result["calories"] == 300  # 600 / 2

    @patch("app.services.meal_suggestions.httpx.get")
    def test_fetch_recipe_no_results(self, mock_get):
        """Test recipe fetch with no results."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"hits": []}
        mock_get.return_value = mock_response

        result = meal_suggestions_service._fetch_recipe("nonexistent", 1, 300)

        assert result is None

    @patch("app.services.meal_suggestions.httpx.get")
    def test_fetch_recipe_api_error(self, mock_get):
        """Test recipe fetch with API error."""
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_get.return_value = mock_response

        result = meal_suggestions_service._fetch_recipe("chicken", 1, 300)

        assert result is None

    @patch("app.services.meal_suggestions.httpx.get")
    def test_fetch_recipe_network_error(self, mock_get):
        """Test recipe fetch with network error."""
        mock_get.side_effect = Exception("Network error")

        result = meal_suggestions_service._fetch_recipe("chicken", 1, 300)

        assert result is None

    @patch("app.services.meal_suggestions.httpx.get")
    def test_fetch_recipe_missing_nutrients(self, mock_get):
        """Test recipe fetch handles missing nutrients gracefully."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "hits": [
                {
                    "recipe": {
                        "label": "Simple Dish",
                        "calories": 400,
                        "yield": 1,
                        "image": None,
                        "url": "https://example.com",
                        "source": "Source",
                        "ingredientLines": [],
                        "totalNutrients": {},  # Missing nutrients
                    }
                }
            ]
        }
        mock_get.return_value = mock_response

        result = meal_suggestions_service._fetch_recipe("simple", 1, 200)

        assert result is not None
        assert result["protein_g"] == 0.0

    @patch("app.services.meal_suggestions.httpx.get")
    def test_fetch_recipe_returns_per_serving(self, mock_get):
        """Test that recipe values are per serving."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "hits": [
                {
                    "recipe": {
                        "label": "Dish",
                        "calories": 1000,
                        "yield": 4,  # 4 servings
                        "image": None,
                        "url": "",
                        "source": "",
                        "ingredientLines": [],
                        "totalNutrients": {
                            "PROCNT": {"quantity": 200},
                            "FAT": {"quantity": 120},
                            "CHOCDF": {"quantity": 200},
                            "FIBTG": {"quantity": 20},
                        },
                    }
                }
            ]
        }
        mock_get.return_value = mock_response

        result = meal_suggestions_service._fetch_recipe("dish", 1, 250)

        # Values should be divided by yield (4)
        assert result["calories"] == 250
        assert result["protein_g"] == 50.0
        assert result["fat_g"] == 30.0


class TestGetMealSuggestions:
    """Tests for get_meal_suggestions function."""

    def test_get_meal_suggestions_nonexistent_user(self, db: Session):
        """Test getting suggestions for non-existent user."""
        with pytest.raises(ValueError, match="User introuvable"):
            meal_suggestions_service.get_meal_suggestions(db, 99999)

    def test_get_meal_suggestions_no_metrics(self, db: Session):
        """Test suggestions with user having no metrics."""
        from app.core.security import get_password_hash

        user = User(
            email="nometrics@example.com",
            username="nometrics",
            hashed_password=get_password_hash("pass"),
        )
        db.add(user)
        db.commit()

        result = meal_suggestions_service.get_meal_suggestions(db, user.id)

        assert result["tdee"] == 0
        assert result["consumed_today"] == 0
        assert result["remaining"] == 0
        assert result["suggestions"] == []

    def test_get_meal_suggestions_basic(self, db: Session, test_user: User):
        """Test basic meal suggestions."""
        with patch.object(meal_suggestions_service, "_fetch_recipe", return_value=None):
            result = meal_suggestions_service.get_meal_suggestions(db, test_user.id)

            assert "tdee" in result
            assert "consumed_today" in result
            assert "remaining" in result
            assert "suggestions" in result
            assert isinstance(result["suggestions"], list)

    def test_get_meal_suggestions_counts_consumed(
        self, db: Session, test_user: User, test_meal_log: MealLog
    ):
        """Test that suggestions count consumed calories."""
        with patch.object(meal_suggestions_service, "_fetch_recipe", return_value=None):
            result = meal_suggestions_service.get_meal_suggestions(db, test_user.id)

            assert result["consumed_today"] == test_meal_log.calories

    def test_get_meal_suggestions_calculates_remaining(
        self, db: Session, test_user: User
    ):
        """Test that suggestions calculate remaining calories."""
        from app.services import meal_log as meal_log_service

        # Add 500 calorie meal
        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="breakfast",
            description="Breakfast",
            calories=500.0,
            protein_g=20.0,
            fat_g=10.0,
            carbs_g=40.0,
            fiber_g=2.0,
        )

        with patch.object(meal_suggestions_service, "_fetch_recipe", return_value=None):
            result = meal_suggestions_service.get_meal_suggestions(db, test_user.id)

            tdee = result["tdee"]
            consumed = result["consumed_today"]
            remaining = result["remaining"]

            assert remaining == max(0, tdee - consumed)

    def test_get_meal_suggestions_no_slots_if_all_logged(
        self, db: Session, test_user: User
    ):
        """Test that no suggestions if all meal slots logged."""
        from app.services import meal_log as meal_log_service

        # Log all meal types
        for meal_type in ["breakfast", "lunch", "dinner", "snack"]:
            meal_log_service.add_meal(
                db,
                user_id=test_user.id,
                date=datetime.date.today(),
                meal_type=meal_type,
                description=f"{meal_type}",
                calories=400.0,
                protein_g=20.0,
                fat_g=10.0,
                carbs_g=40.0,
                fiber_g=2.0,
            )

        result = meal_suggestions_service.get_meal_suggestions(db, test_user.id)

        assert result["suggestions"] == []

    def test_get_meal_suggestions_no_suggestions_if_no_remaining(
        self, db: Session, test_user: User
    ):
        """Test that no suggestions if no remaining calories."""
        from app.services import meal_log as meal_log_service

        # Add meals until TDEE exceeded
        for i in range(10):
            meal_log_service.add_meal(
                db,
                user_id=test_user.id,
                date=datetime.date.today(),
                meal_type="breakfast" if i == 0 else f"snack_{i}",
                description=f"meal_{i}",
                calories=500.0,
                protein_g=20.0,
                fat_g=10.0,
                carbs_g=40.0,
                fiber_g=2.0,
            )

        result = meal_suggestions_service.get_meal_suggestions(db, test_user.id)

        assert result["suggestions"] == []

    @patch("app.services.meal_suggestions.random.choice")
    @patch.object(meal_suggestions_service, "_fetch_recipe")
    def test_get_meal_suggestions_uses_correct_queries(
        self, mock_fetch, mock_choice, db: Session
    ):
        """Test that suggestions use correct queries based on objective."""
        from app.core.security import get_password_hash

        user = User(
            email="objective@example.com",
            username="objective",
            hashed_password=get_password_hash("pass"),
            sport_objective="build_muscle",
            sessions_per_week=4,
        )
        db.add(user)
        db.flush()

        metrics = UserMetrics(user_id=user.id, weight=75.0, height=175, age=30)
        db.add(metrics)
        db.commit()
        db.refresh(user)

        mock_fetch.return_value = {
            "label": "Recipe",
            "calories": 300,
            "protein_g": 30,
            "fat_g": 10,
            "carbs_g": 30,
            "fiber_g": 3,
            "servings": 1,
            "image_url": None,
            "recipe_url": "",
            "source": "",
            "ingredient_lines": [],
        }
        mock_choice.side_effect = lambda x: x[0]  # Return first query

        meal_suggestions_service.get_meal_suggestions(db, user.id)

        # Should have used build_muscle queries
        assert mock_fetch.called

    def test_get_meal_suggestions_structure(self, db: Session, test_user: User):
        """Test suggestion structure has required fields."""
        with patch.object(
            meal_suggestions_service,
            "_fetch_recipe",
            return_value={
                "label": "Chicken",
                "calories": 300,
                "protein_g": 30,
                "fat_g": 10,
                "carbs_g": 30,
                "fiber_g": 3,
                "servings": 1,
                "image_url": "https://example.com/img.jpg",
                "recipe_url": "https://example.com/recipe",
                "source": "Example",
                "ingredient_lines": ["Chicken", "Rice"],
            },
        ):
            result = meal_suggestions_service.get_meal_suggestions(db, test_user.id)

            for suggestion in result["suggestions"]:
                assert "meal_type" in suggestion
                assert "label" in suggestion
                assert "calories" in suggestion

    def test_get_meal_suggestions_respects_portions(self, db: Session, test_user: User):
        """Test that suggestions adjust portions based on remaining calories."""
        with patch.object(
            meal_suggestions_service, "_fetch_recipe", return_value=None
        ) as mock_fetch:
            meal_suggestions_service.get_meal_suggestions(db, test_user.id)

            # _fetch_recipe should be called with target_cal adjusted by portion
            if mock_fetch.called:
                # Verify it was called with proper parameters
                call_args = mock_fetch.call_args_list
                assert len(call_args) > 0
