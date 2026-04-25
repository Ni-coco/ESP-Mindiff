"""
Comprehensive unit tests for app.services.meal_log module.

Tests cover all meal_log service functions with 100% coverage:
- add_meal: create new meal log entry
- get_meals_by_date: retrieve meals for a specific date
- delete_meal: remove meal log entry
"""

import datetime

from sqlalchemy.orm import Session

from app.models.user import MealLog, User
from app.services import meal_log as meal_log_service


class TestAddMeal:
    """Tests for add_meal function."""

    def test_add_meal_basic(self, db: Session, test_user: User):
        """Test adding a basic meal entry."""
        meal = meal_log_service.add_meal(
            db,
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

        assert meal.id is not None
        assert meal.user_id == test_user.id
        assert meal.meal_type == "lunch"
        assert meal.description == "Chicken with rice"
        assert meal.calories == 650.0

    def test_add_meal_persisted_in_db(self, db: Session, test_user: User):
        """Test that added meal is persisted in database."""
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="breakfast",
            description="Oatmeal with berries",
            calories=350.0,
            protein_g=12.0,
            fat_g=8.0,
            carbs_g=60.0,
            fiber_g=6.0,
        )

        retrieved = db.query(MealLog).filter(MealLog.id == meal.id).first()
        assert retrieved is not None
        assert retrieved.description == "Oatmeal with berries"

    def test_add_meal_all_meal_types(self, db: Session, test_user: User):
        """Test adding meals with different meal types."""
        meal_types = ["breakfast", "lunch", "dinner", "snack"]
        for meal_type in meal_types:
            meal = meal_log_service.add_meal(
                db,
                user_id=test_user.id,
                date=datetime.date.today(),
                meal_type=meal_type,
                description=f"A {meal_type}",
                calories=500.0,
                protein_g=20.0,
                fat_g=15.0,
                carbs_g=50.0,
                fiber_g=3.0,
            )
            assert meal.meal_type == meal_type

    def test_add_meal_with_zero_macros(self, db: Session, test_user: User):
        """Test adding meal with zero macronutrients."""
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="snack",
            description="Empty meal",
            calories=0.0,
            protein_g=0.0,
            fat_g=0.0,
            carbs_g=0.0,
            fiber_g=0.0,
        )

        assert meal.calories == 0.0
        assert meal.protein_g == 0.0

    def test_add_meal_with_high_values(self, db: Session, test_user: User):
        """Test adding meal with high macro values."""
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="lunch",
            description="Large meal",
            calories=5000.0,
            protein_g=250.0,
            fat_g=200.0,
            carbs_g=400.0,
            fiber_g=50.0,
        )

        assert meal.calories == 5000.0
        assert meal.protein_g == 250.0

    def test_add_meal_with_float_values(self, db: Session, test_user: User):
        """Test adding meal with decimal macro values."""
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="snack",
            description="Precise meal",
            calories=123.45,
            protein_g=12.34,
            fat_g=5.67,
            carbs_g=23.45,
            fiber_g=1.23,
        )

        assert meal.calories == 123.45
        assert meal.protein_g == 12.34

    def test_add_meal_past_date(self, db: Session, test_user: User):
        """Test adding meal with past date."""
        past_date = datetime.date.today() - datetime.timedelta(days=5)
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=past_date,
            meal_type="lunch",
            description="Past meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        assert meal.date == past_date

    def test_add_meal_future_date(self, db: Session, test_user: User):
        """Test adding meal with future date."""
        future_date = datetime.date.today() + datetime.timedelta(days=5)
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=future_date,
            meal_type="lunch",
            description="Future meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        assert meal.date == future_date

    def test_add_meal_long_description(self, db: Session, test_user: User):
        """Test adding meal with long description."""
        long_desc = "A" * 1000
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="lunch",
            description=long_desc,
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        assert meal.description == long_desc

    def test_add_meal_special_characters_in_description(
        self, db: Session, test_user: User
    ):
        """Test adding meal with special characters."""
        desc = "Café au lait & crème brûlée (délicieux!) 🍰"
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="breakfast",
            description=desc,
            calories=400.0,
            protein_g=15.0,
            fat_g=20.0,
            carbs_g=45.0,
            fiber_g=2.0,
        )

        assert meal.description == desc

    def test_add_meal_multiple_meals_same_day(self, db: Session, test_user: User):
        """Test adding multiple meals for the same day."""
        date = datetime.date.today()
        meal1 = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="breakfast",
            description="Breakfast",
            calories=300.0,
            protein_g=10.0,
            fat_g=10.0,
            carbs_g=40.0,
            fiber_g=2.0,
        )
        meal2 = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="lunch",
            description="Lunch",
            calories=600.0,
            protein_g=40.0,
            fat_g=20.0,
            carbs_g=60.0,
            fiber_g=4.0,
        )

        assert meal1.id != meal2.id
        assert meal1.meal_type != meal2.meal_type

    def test_add_meal_refreshed_from_db(self, db: Session, test_user: User):
        """Test that added meal is refreshed from database."""
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="lunch",
            description="Refreshed meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        # Verify it has created_at timestamp
        assert meal.created_at is not None


class TestGetMealsByDate:
    """Tests for get_meals_by_date function."""

    def test_get_meals_by_date_empty(self, db: Session, test_user: User):
        """Test getting meals for date with no entries."""
        meals = meal_log_service.get_meals_by_date(
            db, test_user.id, datetime.date.today()
        )
        assert meals == []

    def test_get_meals_by_date_single_meal(
        self, db: Session, test_user: User, test_meal_log: MealLog
    ):
        """Test getting meals for date with one entry."""
        meals = meal_log_service.get_meals_by_date(db, test_user.id, test_meal_log.date)
        assert len(meals) == 1
        assert meals[0].id == test_meal_log.id

    def test_get_meals_by_date_multiple_meals(self, db: Session, test_user: User):
        """Test getting multiple meals for same date."""
        date = datetime.date.today()
        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="breakfast",
            description="Breakfast",
            calories=300.0,
            protein_g=10.0,
            fat_g=10.0,
            carbs_g=40.0,
            fiber_g=2.0,
        )
        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="lunch",
            description="Lunch",
            calories=600.0,
            protein_g=40.0,
            fat_g=20.0,
            carbs_g=60.0,
            fiber_g=4.0,
        )

        meals = meal_log_service.get_meals_by_date(db, test_user.id, date)
        assert len(meals) == 2

    def test_get_meals_by_date_filters_by_user(self, db: Session, test_user: User):
        """Test that get_meals_by_date filters by user_id."""
        # Create another user
        from app.core.security import get_password_hash

        other_user = User(
            email="other@example.com",
            username="other",
            hashed_password=get_password_hash("pass"),
        )
        db.add(other_user)
        db.commit()

        date = datetime.date.today()

        # Add meal for first user
        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="lunch",
            description="User 1 meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        # Add meal for second user
        meal_log_service.add_meal(
            db,
            user_id=other_user.id,
            date=date,
            meal_type="lunch",
            description="User 2 meal",
            calories=600.0,
            protein_g=30.0,
            fat_g=20.0,
            carbs_g=55.0,
            fiber_g=4.0,
        )

        # Get meals for first user
        meals = meal_log_service.get_meals_by_date(db, test_user.id, date)
        assert len(meals) == 1
        assert meals[0].description == "User 1 meal"

    def test_get_meals_by_date_filters_by_date(self, db: Session, test_user: User):
        """Test that get_meals_by_date filters by date."""
        date1 = datetime.date.today()
        date2 = datetime.date.today() - datetime.timedelta(days=1)

        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date1,
            meal_type="lunch",
            description="Today meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date2,
            meal_type="lunch",
            description="Yesterday meal",
            calories=600.0,
            protein_g=30.0,
            fat_g=20.0,
            carbs_g=55.0,
            fiber_g=4.0,
        )

        meals = meal_log_service.get_meals_by_date(db, test_user.id, date1)
        assert len(meals) == 1
        assert meals[0].description == "Today meal"

    def test_get_meals_by_date_ordered_by_created_at(
        self, db: Session, test_user: User
    ):
        """Test that meals are ordered by created_at."""
        date = datetime.date.today()

        meal1 = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="breakfast",
            description="First",
            calories=300.0,
            protein_g=10.0,
            fat_g=10.0,
            carbs_g=40.0,
            fiber_g=2.0,
        )

        meal2 = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="lunch",
            description="Second",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        meals = meal_log_service.get_meals_by_date(db, test_user.id, date)
        assert meals[0].id == meal1.id
        assert meals[1].id == meal2.id

    def test_get_meals_by_date_past_date(self, db: Session, test_user: User):
        """Test getting meals from past date."""
        past_date = datetime.date.today() - datetime.timedelta(days=30)

        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=past_date,
            meal_type="lunch",
            description="Past meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        meals = meal_log_service.get_meals_by_date(db, test_user.id, past_date)
        assert len(meals) == 1

    def test_get_meals_by_date_future_date(self, db: Session, test_user: User):
        """Test getting meals from future date."""
        future_date = datetime.date.today() + datetime.timedelta(days=30)

        meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=future_date,
            meal_type="lunch",
            description="Future meal",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        meals = meal_log_service.get_meals_by_date(db, test_user.id, future_date)
        assert len(meals) == 1


class TestDeleteMeal:
    """Tests for delete_meal function."""

    def test_delete_meal_existing(
        self, db: Session, test_user: User, test_meal_log: MealLog
    ):
        """Test deleting an existing meal."""
        result = meal_log_service.delete_meal(db, test_meal_log.id, test_user.id)
        assert result is True

        # Verify it's deleted
        meal = db.query(MealLog).filter(MealLog.id == test_meal_log.id).first()
        assert meal is None

    def test_delete_meal_not_exists(self, db: Session, test_user: User):
        """Test deleting non-existent meal returns False."""
        result = meal_log_service.delete_meal(db, 99999, test_user.id)
        assert result is False

    def test_delete_meal_wrong_user(
        self, db: Session, test_user: User, test_meal_log: MealLog
    ):
        """Test that delete fails if meal belongs to different user."""
        # Create another user
        from app.core.security import get_password_hash

        other_user = User(
            email="other@example.com",
            username="other",
            hashed_password=get_password_hash("pass"),
        )
        db.add(other_user)
        db.commit()

        # Try to delete meal with wrong user_id
        result = meal_log_service.delete_meal(db, test_meal_log.id, other_user.id)
        assert result is False

        # Verify meal still exists
        meal = db.query(MealLog).filter(MealLog.id == test_meal_log.id).first()
        assert meal is not None

    def test_delete_meal_persisted(self, db: Session, test_user: User):
        """Test that deletion is persisted to database."""
        meal = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=datetime.date.today(),
            meal_type="lunch",
            description="To delete",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )
        meal_id = meal.id

        meal_log_service.delete_meal(db, meal_id, test_user.id)

        # Verify deletion from database
        retrieved = db.query(MealLog).filter(MealLog.id == meal_id).first()
        assert retrieved is None

    def test_delete_meal_multiple_meals(self, db: Session, test_user: User):
        """Test deleting one meal doesn't affect others."""
        date = datetime.date.today()

        meal1 = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="breakfast",
            description="Meal 1",
            calories=300.0,
            protein_g=10.0,
            fat_g=10.0,
            carbs_g=40.0,
            fiber_g=2.0,
        )

        meal2 = meal_log_service.add_meal(
            db,
            user_id=test_user.id,
            date=date,
            meal_type="lunch",
            description="Meal 2",
            calories=500.0,
            protein_g=25.0,
            fat_g=15.0,
            carbs_g=50.0,
            fiber_g=3.0,
        )

        # Delete first meal
        meal_log_service.delete_meal(db, meal1.id, test_user.id)

        # Verify second meal still exists
        meals = meal_log_service.get_meals_by_date(db, test_user.id, date)
        assert len(meals) == 1
        assert meals[0].id == meal2.id

    def test_delete_meal_invalid_id(self, db: Session, test_user: User):
        """Test deleting meal with invalid ID."""
        result = meal_log_service.delete_meal(db, 0, test_user.id)
        assert result is False

    def test_delete_meal_idempotent(self, db: Session, test_user: User):
        """Test that deleting non-existent meal returns False consistently."""
        result1 = meal_log_service.delete_meal(db, 99999, test_user.id)
        result2 = meal_log_service.delete_meal(db, 99999, test_user.id)
        assert result1 is False
        assert result2 is False
