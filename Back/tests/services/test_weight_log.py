"""
Comprehensive unit tests for app.services.weight_log module.

Tests cover all weight_log service functions with 100% coverage:
- add_weight_entry: create/update weight log entry (upsert)
- get_weight_history: retrieve weight history with carry-forward
"""

import datetime

from sqlalchemy.orm import Session

from app.models.user import User, WeightLog
from app.services import weight_log as weight_log_service


class TestAddWeightEntry:
    """Tests for add_weight_entry function."""

    def test_add_weight_entry_basic(self, db: Session, test_user: User):
        """Test adding a basic weight entry."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.5,
            source="manual",
            date=datetime.date.today(),
        )

        assert weight.id is not None
        assert weight.user_id == test_user.id
        assert weight.weight == 75.5
        assert weight.source == "manual"
        assert weight.date == datetime.date.today()

    def test_add_weight_entry_default_date(self, db: Session, test_user: User):
        """Test adding weight entry with default date (today)."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
        )

        assert weight.date == datetime.date.today()

    def test_add_weight_entry_default_source(self, db: Session, test_user: User):
        """Test adding weight entry with default source."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            date=datetime.date.today(),
        )

        assert weight.source == "manual"

    def test_add_weight_entry_persisted_to_db(self, db: Session, test_user: User):
        """Test that weight entry is persisted to database."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=datetime.date.today(),
        )

        retrieved = db.query(WeightLog).filter(WeightLog.id == weight.id).first()
        assert retrieved is not None
        assert retrieved.weight == 75.0

    def test_add_weight_entry_upsert_same_date(self, db: Session, test_user: User):
        """Test that adding weight on same date updates existing entry."""
        date = datetime.date.today()

        # Add first entry
        entry1 = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=date,
        )
        entry1_id = entry1.id

        # Add second entry on same date
        entry2 = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=76.0,
            source="scale",
            date=date,
        )

        # Should be same ID (upsert)
        assert entry2.id == entry1_id
        assert entry2.weight == 76.0
        assert entry2.source == "scale"

        # Verify only one entry in database
        count = (
            db.query(WeightLog)
            .filter(WeightLog.user_id == test_user.id, WeightLog.date == date)
            .count()
        )
        assert count == 1

    def test_add_weight_entry_different_dates(self, db: Session, test_user: User):
        """Test adding weight entries on different dates creates separate entries."""
        date1 = datetime.date.today()
        date2 = datetime.date.today() - datetime.timedelta(days=1)

        entry1 = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=date1,
        )

        entry2 = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=74.5,
            source="manual",
            date=date2,
        )

        assert entry1.id != entry2.id
        assert entry1.date == date1
        assert entry2.date == date2

    def test_add_weight_entry_decimal_values(self, db: Session, test_user: User):
        """Test adding weight with decimal values."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.55,
            source="manual",
            date=datetime.date.today(),
        )

        assert weight.weight == 75.55

    def test_add_weight_entry_different_sources(self, db: Session, test_user: User):
        """Test adding weight entries with different sources."""
        sources = ["manual", "scale", "registration", "api"]
        dates = [datetime.date.today() - datetime.timedelta(days=i) for i in range(4)]

        for i, source in enumerate(sources):
            weight = weight_log_service.add_weight_entry(
                db,
                user_id=test_user.id,
                weight=75.0 + i,
                source=source,
                date=dates[i],
            )
            assert weight.source == source

    def test_add_weight_entry_zero_weight(self, db: Session, test_user: User):
        """Test adding weight entry with zero value."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=0.0,
            source="manual",
            date=datetime.date.today(),
        )

        assert weight.weight == 0.0

    def test_add_weight_entry_large_weight(self, db: Session, test_user: User):
        """Test adding weight entry with large value."""
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=500.0,
            source="manual",
            date=datetime.date.today(),
        )

        assert weight.weight == 500.0

    def test_add_weight_entry_past_date(self, db: Session, test_user: User):
        """Test adding weight entry with past date."""
        past_date = datetime.date.today() - datetime.timedelta(days=30)
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=past_date,
        )

        assert weight.date == past_date

    def test_add_weight_entry_future_date(self, db: Session, test_user: User):
        """Test adding weight entry with future date."""
        future_date = datetime.date.today() + datetime.timedelta(days=30)
        weight = weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=future_date,
        )

        assert weight.date == future_date

    def test_add_weight_entry_multiple_users(self, db: Session):
        """Test that weight entries are isolated per user."""
        from app.core.security import get_password_hash

        user1 = User(
            email="user1@example.com",
            username="user1",
            hashed_password=get_password_hash("pass"),
        )
        user2 = User(
            email="user2@example.com",
            username="user2",
            hashed_password=get_password_hash("pass"),
        )
        db.add_all([user1, user2])
        db.commit()

        date = datetime.date.today()

        weight1 = weight_log_service.add_weight_entry(
            db, user_id=user1.id, weight=75.0, source="manual", date=date
        )

        weight2 = weight_log_service.add_weight_entry(
            db, user_id=user2.id, weight=80.0, source="manual", date=date
        )

        assert weight1.id != weight2.id
        assert weight1.weight != weight2.weight


class TestGetWeightHistory:
    """Tests for get_weight_history function."""

    def test_get_weight_history_empty(self, db: Session, test_user: User):
        """Test getting weight history when no entries exist."""
        history = weight_log_service.get_weight_history(db, test_user.id)
        assert history == []

    def test_get_weight_history_single_entry(self, db: Session, test_user: User):
        """Test weight history with single entry."""
        today = datetime.date.today()
        weight_log_service.add_weight_entry(
            db, user_id=test_user.id, weight=75.0, source="manual", date=today
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        assert len(history) == 1
        assert history[0]["date"] == today
        assert history[0]["weight"] == 75.0
        assert history[0]["source"] == "manual"

    def test_get_weight_history_multiple_entries(self, db: Session, test_user: User):
        """Test weight history with multiple entries."""
        today = datetime.date.today()

        # Add entries on consecutive days
        for i in range(3):
            date = today - datetime.timedelta(days=i)
            weight_log_service.add_weight_entry(
                db,
                user_id=test_user.id,
                weight=75.0 + i,
                source="manual",
                date=date,
            )

        history = weight_log_service.get_weight_history(db, test_user.id)

        assert len(history) == 3

    def test_get_weight_history_with_gaps(self, db: Session, test_user: User):
        """Test weight history with gaps (carry-forward)."""
        today = datetime.date.today()

        # Add weight on day 1
        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=today - datetime.timedelta(days=2),
        )

        # Add weight on day 3 (skip day 2)
        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=74.5,
            source="manual",
            date=today,
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # Should have 3 entries: day-2, day-1 (carried forward), day
        assert len(history) == 3

        # Day-2 should have source "manual"
        assert history[0]["source"] == "manual"

        # Day-1 should have source "carried_forward"
        assert history[1]["source"] == "carried_forward"
        assert history[1]["weight"] == 75.0

        # Day should have source "manual"
        assert history[2]["source"] == "manual"

    def test_get_weight_history_carry_forward_value(self, db: Session, test_user: User):
        """Test that carry-forward preserves the last known weight."""
        start_date = datetime.date.today() - datetime.timedelta(days=5)

        # Add entry at start
        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=80.0,
            source="manual",
            date=start_date,
        )

        # Add entry 5 days later
        end_date = start_date + datetime.timedelta(days=5)
        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=79.0,
            source="manual",
            date=end_date,
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # All intermediate days should have 80.0
        for i in range(1, 5):
            assert history[i]["weight"] == 80.0
            assert history[i]["source"] == "carried_forward"

    def test_get_weight_history_to_today(self, db: Session, test_user: User):
        """Test that weight history extends to today."""
        past_date = datetime.date.today() - datetime.timedelta(days=5)

        weight_log_service.add_weight_entry(
            db, user_id=test_user.id, weight=75.0, source="manual", date=past_date
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # Should extend from past_date to today
        assert history[-1]["date"] == datetime.date.today()

    def test_get_weight_history_does_not_predate_first_entry(
        self, db: Session, test_user: User
    ):
        """Test that history doesn't include days before first entry."""
        entry_date = datetime.date.today() - datetime.timedelta(days=5)

        weight_log_service.add_weight_entry(
            db, user_id=test_user.id, weight=75.0, source="manual", date=entry_date
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # First entry should be entry_date, not earlier
        assert history[0]["date"] == entry_date

    def test_get_weight_history_ordered_by_date(self, db: Session, test_user: User):
        """Test that history is ordered chronologically."""
        dates = [
            datetime.date.today() - datetime.timedelta(days=3),
            datetime.date.today() - datetime.timedelta(days=1),
            datetime.date.today(),
        ]

        # Add in random order
        for date in [dates[2], dates[0], dates[1]]:
            weight_log_service.add_weight_entry(
                db, user_id=test_user.id, weight=75.0, source="manual", date=date
            )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # Should be in chronological order
        for i in range(len(history) - 1):
            assert history[i]["date"] <= history[i + 1]["date"]

    def test_get_weight_history_different_sources(self, db: Session, test_user: User):
        """Test that history preserves source information."""
        today = datetime.date.today()

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=today - datetime.timedelta(days=2),
        )

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=74.5,
            source="scale",
            date=today - datetime.timedelta(days=1),
        )

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=74.0,
            source="api",
            date=today,
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        assert history[0]["source"] == "manual"
        assert history[1]["source"] == "scale"
        assert history[2]["source"] == "api"

    def test_get_weight_history_long_gap(self, db: Session, test_user: User):
        """Test weight history with long gap between entries."""
        start_date = datetime.date.today() - datetime.timedelta(days=30)

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=start_date,
        )

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=74.0,
            source="manual",
            date=datetime.date.today(),
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # Should have 31 entries (30 days + today)
        assert len(history) == 31

    def test_get_weight_history_multiple_users_isolated(
        self, db: Session, test_user: User
    ):
        """Test that weight history is isolated per user."""
        from app.core.security import get_password_hash

        other_user = User(
            email="other@example.com",
            username="other",
            hashed_password=get_password_hash("pass"),
        )
        db.add(other_user)
        db.commit()

        today = datetime.date.today()

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=today,
        )

        weight_log_service.add_weight_entry(
            db,
            user_id=other_user.id,
            weight=80.0,
            source="manual",
            date=today,
        )

        history1 = weight_log_service.get_weight_history(db, test_user.id)
        history2 = weight_log_service.get_weight_history(db, other_user.id)

        assert history1[0]["weight"] == 75.0
        assert history2[0]["weight"] == 80.0

    def test_get_weight_history_weight_changes(self, db: Session, test_user: User):
        """Test that weight history tracks weight changes."""
        today = datetime.date.today()

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=80.0,
            source="manual",
            date=today - datetime.timedelta(days=10),
        )

        weight_log_service.add_weight_entry(
            db,
            user_id=test_user.id,
            weight=75.0,
            source="manual",
            date=today,
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        # First entry should be 80.0
        assert history[0]["weight"] == 80.0

        # Last entry should be 75.0
        assert history[-1]["weight"] == 75.0

    def test_get_weight_history_upsert_update(self, db: Session, test_user: User):
        """Test that upsert updates are reflected in history."""
        date = datetime.date.today()

        # Add initial weight
        weight_log_service.add_weight_entry(
            db, user_id=test_user.id, weight=75.0, source="manual", date=date
        )

        # Update on same date
        weight_log_service.add_weight_entry(
            db, user_id=test_user.id, weight=74.5, source="scale", date=date
        )

        history = weight_log_service.get_weight_history(db, test_user.id)

        assert len(history) == 1
        assert history[0]["weight"] == 74.5
        assert history[0]["source"] == "scale"
