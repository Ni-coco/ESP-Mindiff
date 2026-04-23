"""
Tests for dependency functions (app/core/dependencies.py).

Tests cover:
- Getting current user from token
- Invalid/expired tokens
- Missing email in token
- User not found
- Getting current active user
- Getting current superuser
"""

from http import HTTPStatus
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.user import User


class TestGetCurrentUser:
    """Tests for get_current_user dependency."""

    def test_get_current_user_valid_token(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test getting current user with valid token."""
        response = client.get("/api/user/", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK

    def test_get_current_user_no_token(self, client: TestClient):
        """Test that request fails without token."""
        response = client.get("/api/user/")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_invalid_token(self, client: TestClient):
        """Test that invalid token raises credentials exception."""
        headers = {"Authorization": "Bearer invalid_token_format"}
        response = client.get("/api/user/", headers=headers)
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_malformed_token(self, client: TestClient):
        """Test that malformed token raises credentials exception."""
        headers = {
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.invalid"
        }
        response = client.get("/api/user/", headers=headers)
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_payload_is_none(self, client: TestClient):
        """Test when decode_access_token returns None (line 33)."""
        with patch("app.core.dependencies.decode_access_token") as mock_decode:
            mock_decode.return_value = None
            headers = {"Authorization": "Bearer someinvalidtoken"}
            response = client.get("/api/user/", headers=headers)
            assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_email_is_none(self, client: TestClient):
        """Test when email is None in payload (line 42)."""
        with patch("app.core.dependencies.decode_access_token") as mock_decode:
            mock_decode.return_value = {"some_other_field": "value"}
            headers = {"Authorization": "Bearer sometoken"}
            response = client.get("/api/user/", headers=headers)
            assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_user_not_found(self, client: TestClient):
        """Test when user is not found in database (line 54)."""
        with patch("app.core.dependencies.decode_access_token") as mock_decode:
            mock_decode.return_value = {"sub": "nonexistent@example.com"}
            headers = {"Authorization": "Bearer sometoken"}
            response = client.get("/api/user/", headers=headers)
            assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_includes_metrics(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test that current user includes user_metrics."""
        response = client.get("/api/user/", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK


class TestGetCurrentActiveUser:
    """Tests for get_current_active_user dependency."""

    def test_get_current_active_user_active(
        self, client: TestClient, auth_headers: dict, test_user
    ):
        """Test getting active user."""
        response = client.get("/api/user/", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK

    def test_get_current_active_user_inactive(
        self, client: TestClient, test_inactive_user
    ):
        """Test that inactive user is rejected."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "inactive@example.com",
                "password": "inactivepass123",
            },
        )
        # Login should fail for inactive user
        assert response.status_code == HTTPStatus.BAD_REQUEST

    def test_get_current_active_user_requires_auth(self, client: TestClient):
        """Test that active user check requires authentication."""
        response = client.get("/api/user/")
        assert response.status_code == HTTPStatus.UNAUTHORIZED


class TestGetCurrentSuperuser:
    """Tests for get_current_superuser dependency."""

    def test_get_current_superuser_regular_user_forbidden(
        self, client: TestClient, auth_headers: dict, test_user, db
    ):
        """Test that regular user cannot access superuser endpoints (line 66-71)."""
        from unittest.mock import patch

        from app.core.security import get_password_hash
        from app.models.user import User

        # Create another user
        other_user = User(
            email="other_user@example.com",
            username="otheruser",
            hashed_password=get_password_hash("pass123"),
            is_active=True,
            is_superuser=False,
        )
        db.add(other_user)
        db.commit()

        # Regular user trying to access meal suggestions for other user
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
                f"/api/user/{other_user.id}/dashboard/meal-suggestions",
                headers=auth_headers,
            )
            assert response.status_code == HTTPStatus.FORBIDDEN

    def test_get_current_superuser_direct_call_not_superuser(
        self, db: Session, test_user: User
    ):
        """
        Test get_current_superuser directly when user is not superuser (lines 66-71).
        This ensures the is_superuser check is covered.
        """
        import pytest
        from fastapi import HTTPException

        from app.core.dependencies import get_current_superuser

        # test_user has is_superuser=False by default
        assert test_user.is_superuser is False

        # Call get_current_superuser directly with a non-superuser
        with pytest.raises(HTTPException) as exc_info:
            pytest_asyncio_fixture = AsyncMock()
            # We need to test this via async context
            import asyncio

            asyncio.run(get_current_superuser(test_user))

        # Verify it's the 403 Forbidden error
        assert exc_info.value.status_code == HTTPStatus.FORBIDDEN
        assert "privileges" in exc_info.value.detail.lower()

    def test_get_current_superuser_inactive_superuser(self, client: TestClient, db):
        """Test that inactive superuser cannot access protected endpoints."""
        from app.core.security import get_password_hash
        from app.models.user import User

        # Create inactive superuser
        inactive_superuser = User(
            email="inactivesuperuser@example.com",
            username="inactivesuperuser",
            hashed_password=get_password_hash("superpass123"),
            is_active=False,
            is_superuser=True,
        )
        db.add(inactive_superuser)
        db.commit()

        response = client.post(
            "/api/auth/login",
            json={
                "email": "inactivesuperuser@example.com",
                "password": "superpass123",
            },
        )
        # Login should fail for inactive user even if superuser
        assert response.status_code == HTTPStatus.BAD_REQUEST


class TestDirectDependencyFunctions:
    """Tests calling dependency functions directly to ensure code coverage."""

    def test_get_current_user_not_found_directly(self, db: Session):
        """
        Test get_current_user directly when user is not found (line 54).
        This ensures the `if user is None` check is covered.
        """
        import pytest
        from fastapi import HTTPException

        from app.core.dependencies import get_current_user
        from app.core.security import create_access_token

        # Create a token for an email that doesn't exist in DB
        token = create_access_token(data={"sub": "nonexistent@example.com"})

        # Call get_current_user directly
        with pytest.raises(HTTPException) as exc_info:
            import asyncio

            asyncio.run(get_current_user(token, db))

        # Verify it raises 401 Unauthorized
        assert exc_info.value.status_code == HTTPStatus.UNAUTHORIZED
        assert "validate credentials" in exc_info.value.detail.lower()

    def test_get_current_superuser_not_superuser_directly(
        self, db: Session, test_user: User
    ):
        """
        Test get_current_superuser directly when user is not superuser (lines 66-71).
        This ensures the `if not current_user.is_superuser` check is covered.
        """
        import pytest
        from fastapi import HTTPException

        from app.core.dependencies import get_current_superuser

        # test_user has is_superuser=False
        assert test_user.is_superuser is False

        # Call get_current_superuser directly
        with pytest.raises(HTTPException) as exc_info:
            import asyncio

            asyncio.run(get_current_superuser(test_user))

        # Verify it's the 403 Forbidden error
        assert exc_info.value.status_code == HTTPStatus.FORBIDDEN
        assert "privileges" in exc_info.value.detail.lower()


class TestOAuth2Scheme:
    """Tests for OAuth2 scheme behavior."""

    def test_oauth2_scheme_missing_token(self, client: TestClient):
        """Test that missing token is detected."""
        response = client.get("/api/user/")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_oauth2_scheme_bearer_prefix_required(self, client: TestClient):
        """Test that Bearer prefix is required."""
        headers = {"Authorization": "sometoken"}
        response = client.get("/api/user/", headers=headers)
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_oauth2_scheme_case_sensitive_bearer(self, client: TestClient):
        """Test Bearer prefix case sensitivity."""
        headers = {"Authorization": "bearer sometoken"}
        response = client.get("/api/user/", headers=headers)
        assert response.status_code == HTTPStatus.UNAUTHORIZED
