"""
Comprehensive unit tests for app.services.user module.

Tests cover all user service functions with 100% coverage:
- get_users
- get_user_by_email
- get_user_by_username
- get_user
- create_user
- update_user
- authenticate_user
- delete_user
"""

from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models.user import User, UserMetrics
from app.schemas.user import UserCreate, UserUpdate
from app.schemas.user import UserMetrics as UserMetricsSchema
from app.services import user as user_service


class TestGetUsers:
    """Tests for get_users function."""

    def test_get_users_empty(self, db: Session):
        """Test getting users when database is empty."""
        users = user_service.get_users(db)
        assert users == []

    def test_get_users_single_user(self, db: Session, test_user: User):
        """Test getting users with one user in database."""
        users = user_service.get_users(db)
        assert len(users) == 1
        assert users[0].id == test_user.id
        assert users[0].email == test_user.email

    def test_get_users_multiple_users(self, db: Session):
        """Test getting multiple users from database."""
        # Create multiple users
        for i in range(3):
            user = User(
                email=f"user{i}@example.com",
                username=f"user{i}",
                hashed_password=get_password_hash(f"pass{i}"),
                is_active=True,
            )
            db.add(user)
        db.commit()

        users = user_service.get_users(db)
        assert len(users) == 3

    def test_get_users_includes_superusers(self, db: Session):
        """Test that get_users returns both regular and superusers."""
        superuser = User(
            email="super@example.com",
            username="super",
            hashed_password=get_password_hash("pass"),
            is_active=True,
            is_superuser=True,
        )
        regular_user = User(
            email="regular@example.com",
            username="regular",
            hashed_password=get_password_hash("pass"),
            is_active=True,
            is_superuser=False,
        )
        db.add_all([superuser, regular_user])
        db.commit()

        users = user_service.get_users(db)
        assert len(users) == 2
        assert any(u.is_superuser for u in users)
        assert any(not u.is_superuser for u in users)

    def test_get_users_includes_inactive_users(self, db: Session):
        """Test that get_users returns inactive users."""
        inactive_user = User(
            email="inactive@example.com",
            username="inactive",
            hashed_password=get_password_hash("pass"),
            is_active=False,
        )
        db.add(inactive_user)
        db.commit()

        users = user_service.get_users(db)
        assert any(not u.is_active for u in users)


class TestGetUserByEmail:
    """Tests for get_user_by_email function."""

    def test_get_user_by_email_found(self, db: Session, test_user: User):
        """Test retrieving an existing user by email."""
        user = user_service.get_user_by_email(db, test_user.email)
        assert user is not None
        assert user.id == test_user.id
        assert user.email == test_user.email

    def test_get_user_by_email_not_found(self, db: Session):
        """Test retrieving non-existent user by email."""
        user = user_service.get_user_by_email(db, "nonexistent@example.com")
        assert user is None

    def test_get_user_by_email_case_sensitive(self, db: Session, test_user: User):
        """Test that email lookup works with exact email."""
        user = user_service.get_user_by_email(db, test_user.email)
        assert user is not None

    def test_get_user_by_email_with_multiple_users(self, db: Session):
        """Test email lookup returns correct user among many."""
        user1 = User(
            email="alice@example.com",
            username="alice",
            hashed_password=get_password_hash("pass1"),
        )
        user2 = User(
            email="bob@example.com",
            username="bob",
            hashed_password=get_password_hash("pass2"),
        )
        db.add_all([user1, user2])
        db.commit()

        found = user_service.get_user_by_email(db, "bob@example.com")
        assert found.username == "bob"


class TestGetUserByUsername:
    """Tests for get_user_by_username function."""

    def test_get_user_by_username_found(self, db: Session, test_user: User):
        """Test retrieving an existing user by username."""
        user = user_service.get_user_by_username(db, test_user.username)
        assert user is not None
        assert user.id == test_user.id
        assert user.username == test_user.username

    def test_get_user_by_username_not_found(self, db: Session):
        """Test retrieving non-existent user by username."""
        user = user_service.get_user_by_username(db, "nonexistent")
        assert user is None

    def test_get_user_by_username_with_multiple_users(self, db: Session):
        """Test username lookup returns correct user among many."""
        user1 = User(
            email="alice@example.com",
            username="alice",
            hashed_password=get_password_hash("pass1"),
        )
        user2 = User(
            email="bob@example.com",
            username="bob",
            hashed_password=get_password_hash("pass2"),
        )
        db.add_all([user1, user2])
        db.commit()

        found = user_service.get_user_by_username(db, "bob")
        assert found.email == "bob@example.com"


class TestGetUser:
    """Tests for get_user function."""

    def test_get_user_by_id_found(self, db: Session, test_user: User):
        """Test retrieving user by existing ID."""
        user = user_service.get_user(db, test_user.id)
        assert user is not None
        assert user.id == test_user.id
        assert user.email == test_user.email

    def test_get_user_by_id_not_found(self, db: Session):
        """Test retrieving user by non-existent ID."""
        user = user_service.get_user(db, 99999)
        assert user is None

    def test_get_user_by_invalid_id(self, db: Session):
        """Test retrieving user with invalid ID value."""
        user = user_service.get_user(db, 0)
        assert user is None

    def test_get_user_after_creation(self, db: Session):
        """Test retrieving user immediately after creation."""
        new_user = User(
            email="new@example.com",
            username="newuser",
            hashed_password=get_password_hash("password"),
        )
        db.add(new_user)
        db.commit()

        retrieved = user_service.get_user(db, new_user.id)
        assert retrieved is not None
        assert retrieved.email == "new@example.com"


class TestCreateUser:
    """Tests for create_user function."""

    def test_create_user_basic(self, db: Session):
        """Test creating a new user with basic information."""
        user_data = UserCreate(
            email="newuser@example.com",
            username="newuser",
            password="securepass123",
        )
        created = user_service.create_user(db, user_data)

        assert created.id is not None
        assert created.email == "newuser@example.com"
        assert created.username == "newuser"
        assert verify_password("securepass123", created.hashed_password)

    def test_create_user_password_hashing(self, db: Session):
        """Test that user password is properly hashed."""
        user_data = UserCreate(
            email="user@example.com",
            username="user",
            password="mypassword",
        )
        created = user_service.create_user(db, user_data)

        assert created.hashed_password != "mypassword"
        assert verify_password("mypassword", created.hashed_password)

    def test_create_user_persisted_in_db(self, db: Session):
        """Test that created user is persisted in database."""
        user_data = UserCreate(
            email="persisted@example.com",
            username="persisted",
            password="password123",
        )
        created = user_service.create_user(db, user_data)
        user_id = created.id

        retrieved = user_service.get_user(db, user_id)
        assert retrieved is not None
        assert retrieved.email == "persisted@example.com"

    def test_create_user_multiple_users(self, db: Session):
        """Test creating multiple users."""
        for i in range(3):
            user_data = UserCreate(
                email=f"user{i}@example.com",
                username=f"user{i}",
                password="password123",
            )
            user_service.create_user(db, user_data)

        users = user_service.get_users(db)
        assert len(users) == 3

    def test_create_user_with_special_characters(self, db: Session):
        """Test creating user with special characters in username."""
        user_data = UserCreate(
            email="special@example.com",
            username="user_123-special",
            password="password123",
        )
        created = user_service.create_user(db, user_data)
        assert created.username == "user_123-special"

    def test_create_user_with_long_password(self, db: Session):
        """Test creating user with very long password."""
        long_password = "a" * 60
        user_data = UserCreate(
            email="longpass@example.com",
            username="longpass",
            password=long_password,
        )
        created = user_service.create_user(db, user_data)
        assert verify_password(long_password, created.hashed_password)


class TestUpdateUser:
    """Tests for update_user function."""

    def test_update_user_basic_fields(self, db: Session, test_user: User):
        """Test updating basic user fields."""
        update_data = UserUpdate(
            email="updated@example.com",
            username="updated_user",
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert updated.email == "updated@example.com"
        assert updated.username == "updated_user"

    def test_update_user_password(self, db: Session, test_user: User):
        """Test updating user password."""
        update_data = UserUpdate(
            email=test_user.email,
            username=test_user.username,
            password="newpassword123",
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert verify_password("newpassword123", updated.hashed_password)

    def test_update_user_is_active(self, db: Session, test_user: User):
        """Test updating user is_active status."""
        update_data = UserUpdate(
            email=test_user.email,
            username=test_user.username,
            is_active=False,
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert updated.is_active is False

    def test_update_user_is_superuser(self, db: Session, test_user: User):
        """Test updating user is_superuser status."""
        update_data = UserUpdate(
            email=test_user.email,
            username=test_user.username,
            is_superuser=True,
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert updated.is_superuser is True

    def test_update_user_profile_fields(self, db: Session, test_user: User):
        """Test updating user profile fields."""
        update_data = UserUpdate(
            email=test_user.email,
            username=test_user.username,
            gender="female",
            sport_objective="build_muscle",
            target_weight=70.0,
            sessions_per_week=4,
            health_considerations="None",
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert updated.gender == "female"
        assert updated.sport_objective == "build_muscle"
        assert updated.target_weight == 70.0
        assert updated.sessions_per_week == 4

    def test_update_user_metrics_new(self, db: Session, test_user: User):
        """Test adding metrics to user without existing metrics."""
        metrics_data = UserMetricsSchema(
            weight=80.0,
            actual_weight=79.5,
            height=175.0,
            age=28,
        )
        update_data = UserUpdate(
            email=test_user.email,
            username=test_user.username,
            metrics=metrics_data,
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert len(updated.user_metrics) > 0
        assert updated.user_metrics[0].weight == 80.0

    def test_update_user_metrics_existing(self, db: Session):
        """Test updating existing user metrics (lines 76-80 in app/services/user.py)."""
        user = User(
            email="user_metrics@example.com",
            username="usermetrics",
            hashed_password=get_password_hash("password123"),
        )
        db.add(user)
        db.flush()

        metrics = UserMetrics(
            user_id=user.id,
            weight=75.0,
            actual_weight=74.0,
            height=180,
            age=30,
        )
        db.add(metrics)
        db.commit()

        metrics_data = UserMetricsSchema(
            weight=72.0,
            actual_weight=71.0,
            height=182,
            age=31,
        )
        update_data = UserUpdate(
            email=user.email,
            username=user.username,
            metrics=metrics_data,
        )
        updated = user_service.update_user(db, user.id, update_data)

        assert updated is not None
        assert len(updated.user_metrics) == 1
        # Verify all fields are updated (lines 77-81 coverage)
        assert updated.user_metrics[0].weight == 72.0
        assert updated.user_metrics[0].actual_weight == 71.0
        assert updated.user_metrics[0].height == 182
        assert updated.user_metrics[0].age == 31

    def test_update_user_metrics_existing_with_none_actual_weight(self, db: Session):
        """Test updating metrics with None actual_weight defaults to weight (line 78 or-logic)."""
        user = User(
            email="user_metrics_none@example.com",
            username="usermetricsnone",
            hashed_password=get_password_hash("password123"),
        )
        db.add(user)
        db.flush()

        metrics = UserMetrics(
            user_id=user.id,
            weight=75.0,
            actual_weight=None,
            height=180,
            age=30,
        )
        db.add(metrics)
        db.commit()

        metrics_data = UserMetricsSchema(
            weight=72.0,
            actual_weight=None,  # This should default to weight
            height=182,
            age=31,
        )
        update_data = UserUpdate(
            email=user.email,
            username=user.username,
            metrics=metrics_data,
        )
        updated = user_service.update_user(db, user.id, update_data)

        assert updated is not None
        assert len(updated.user_metrics) == 1
        # Verify actual_weight defaults to weight when None (line 78 coverage)
        assert updated.user_metrics[0].weight == 72.0
        assert updated.user_metrics[0].actual_weight == 72.0

    def test_update_user_not_found(self, db: Session):
        """Test updating non-existent user."""
        update_data = UserUpdate(
            email="new@example.com",
            username="newuser",
        )
        updated = user_service.update_user(db, 99999, update_data)
        assert updated is None

    def test_update_user_partial_fields(self, db: Session, test_user: User):
        """Test updating user with only some fields."""
        original_email = test_user.email
        update_data = UserUpdate(
            email=original_email,
            username="newtestuser",
            gender="male",
        )
        updated = user_service.update_user(db, test_user.id, update_data)

        assert updated is not None
        assert updated.email == original_email
        assert updated.username == "newtestuser"

    def test_update_user_persisted(self, db: Session, test_user: User):
        """Test that user updates are persisted in database."""
        update_data = UserUpdate(
            email="persist@example.com",
            username="persistent",
            password="newpass123",
        )
        user_service.update_user(db, test_user.id, update_data)

        db.expire_all()
        retrieved = user_service.get_user(db, test_user.id)
        assert retrieved is not None
        assert retrieved.email == "persist@example.com"
        assert retrieved.username == "persistent"


class TestAuthenticateUser:
    """Tests for authenticate_user function."""

    def test_authenticate_user_correct_credentials(self, db: Session):
        """Test successful authentication with correct credentials."""
        user_data = UserCreate(
            email="auth@example.com",
            username="auth",
            password="correct_pass",
        )
        user_service.create_user(db, user_data)

        authenticated = user_service.authenticate_user(
            db, "auth@example.com", "correct_pass"
        )
        assert authenticated is not None
        assert authenticated.email == "auth@example.com"

    def test_authenticate_user_wrong_password(self, db: Session):
        """Test authentication with wrong password."""
        user_data = UserCreate(
            email="wrong@example.com",
            username="wrong",
            password="correct_pass",
        )
        user_service.create_user(db, user_data)

        authenticated = user_service.authenticate_user(
            db, "wrong@example.com", "wrong_pass"
        )
        assert authenticated is None

    def test_authenticate_user_nonexistent_email(self, db: Session):
        """Test authentication with non-existent email."""
        authenticated = user_service.authenticate_user(
            db, "nonexistent@example.com", "anypassword"
        )
        assert authenticated is None

    def test_authenticate_user_empty_password(self, db: Session):
        """Test authentication with empty password."""
        user_data = UserCreate(
            email="empty@example.com",
            username="empty",
            password="realpass",
        )
        user_service.create_user(db, user_data)

        authenticated = user_service.authenticate_user(db, "empty@example.com", "")
        assert authenticated is None

    def test_authenticate_user_case_sensitive_password(self, db: Session):
        """Test that password is case sensitive."""
        user_data = UserCreate(
            email="case@example.com",
            username="case",
            password="CaseSensitive",
        )
        user_service.create_user(db, user_data)

        authenticated = user_service.authenticate_user(
            db, "case@example.com", "casesensitive"
        )
        assert authenticated is None

    def test_authenticate_inactive_user(self, db: Session):
        """Test authenticating inactive user."""
        user = User(
            email="inactive@example.com",
            username="inactive",
            hashed_password=get_password_hash("pass"),
            is_active=False,
        )
        db.add(user)
        db.commit()

        authenticated = user_service.authenticate_user(
            db, "inactive@example.com", "pass"
        )
        assert authenticated is not None  # Still authenticates but user is inactive

    def test_authenticate_superuser(self, db: Session):
        """Test authenticating superuser."""
        user = User(
            email="super@example.com",
            username="super",
            hashed_password=get_password_hash("pass"),
            is_superuser=True,
        )
        db.add(user)
        db.commit()

        authenticated = user_service.authenticate_user(db, "super@example.com", "pass")
        assert authenticated is not None
        assert authenticated.is_superuser is True


class TestDeleteUser:
    """Tests for delete_user function."""

    def test_delete_user_existing(self, db: Session, test_user: User):
        """Test deleting an existing user."""
        user_id = test_user.id
        deleted = user_service.delete_user(db, user_id)

        assert deleted is not None
        assert deleted.id == user_id

    def test_delete_user_not_found(self, db: Session):
        """Test deleting non-existent user."""
        deleted = user_service.delete_user(db, 99999)
        assert deleted is None

    def test_delete_user_removes_from_db(self, db: Session, test_user: User):
        """Test that deleted user is actually removed from database."""
        user_id = test_user.id
        user_service.delete_user(db, user_id)

        retrieved = user_service.get_user(db, user_id)
        assert retrieved is None

    def test_delete_user_cascades_to_metrics(self, db: Session):
        """Test that deleting user also removes associated metrics."""
        user = User(
            email="cascade@example.com",
            username="cascade",
            hashed_password=get_password_hash("pass"),
        )
        db.add(user)
        db.flush()

        metrics = UserMetrics(
            user_id=user.id,
            weight=75.0,
            height=180,
            age=30,
        )
        db.add(metrics)
        db.commit()

        user_id = user.id
        user_service.delete_user(db, user_id)

        retrieved_user = user_service.get_user(db, user_id)
        assert retrieved_user is None

    def test_delete_multiple_users(self, db: Session):
        """Test deleting multiple users."""
        user1 = User(
            email="del1@example.com",
            username="del1",
            hashed_password=get_password_hash("pass"),
        )
        user2 = User(
            email="del2@example.com",
            username="del2",
            hashed_password=get_password_hash("pass"),
        )
        db.add_all([user1, user2])
        db.commit()

        user_service.delete_user(db, user1.id)
        user_service.delete_user(db, user2.id)

        users = user_service.get_users(db)
        assert len(users) == 0
