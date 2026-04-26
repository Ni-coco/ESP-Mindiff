"""
Tests for authentication endpoints (app/api/auth.py).

Tests cover:
- User registration with validation
- User login with JWT token generation
- OAuth2 form login
- Getting current authenticated user
- Error handling for invalid credentials
"""

from http import HTTPStatus

from fastapi.testclient import TestClient


class TestAuthRegister:
    """Tests for POST /api/auth/register endpoint."""

    def test_register_success(self, client: TestClient):
        """Test successful user registration."""
        response = client.post(
            "/api/auth/register",
            json={
                "email": "newuser@example.com",
                "username": "newuser",
                "password": "securepass123",
            },
        )
        assert response.status_code == HTTPStatus.CREATED
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["username"] == "newuser"
        assert data["is_active"] is True
        assert data["is_superuser"] is False
        assert "hashed_password" not in data

    def test_register_duplicate_email(self, client: TestClient, test_user):
        """Test registration with email already in use."""
        response = client.post(
            "/api/auth/register",
            json={
                "email": "test@example.com",  # Same as test_user
                "username": "anotheruser",
                "password": "securepass123",
            },
        )
        assert response.status_code == HTTPStatus.BAD_REQUEST
        assert "Email already registered" in response.json()["detail"]

    def test_register_duplicate_username(self, client: TestClient, test_user):
        """Test registration with username already in use."""
        response = client.post(
            "/api/auth/register",
            json={
                "email": "another@example.com",
                "username": "testuser",  # Same as test_user
                "password": "securepass123",
            },
        )
        assert response.status_code == HTTPStatus.BAD_REQUEST
        assert "Username already taken" in response.json()["detail"]

    def test_register_invalid_email(self, client: TestClient):
        """Test registration with invalid email format."""
        response = client.post(
            "/api/auth/register",
            json={
                "email": "invalid-email",
                "username": "newuser",
                "password": "securepass123",
            },
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY

    def test_register_short_password(self, client: TestClient):
        """Test registration with password too short."""
        response = client.post(
            "/api/auth/register",
            json={
                "email": "user@example.com",
                "username": "newuser",
                "password": "short",
            },
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY

    def test_register_short_username(self, client: TestClient):
        """Test registration with username too short."""
        response = client.post(
            "/api/auth/register",
            json={
                "email": "user@example.com",
                "username": "ab",  # Too short
                "password": "securepass123",
            },
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY


class TestAuthLogin:
    """Tests for POST /api/auth/login endpoint."""

    def test_login_success(self, client: TestClient, test_user):
        """Test successful login."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "test@example.com",
                "password": "testpass123",
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert len(data["access_token"]) > 0

    def test_login_wrong_password(self, client: TestClient, test_user):
        """Test login with wrong password."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "test@example.com",
                "password": "wrongpassword",
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED
        assert "Incorrect email or password" in response.json()["detail"]

    def test_login_nonexistent_user(self, client: TestClient):
        """Test login with non-existent email."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "nonexistent@example.com",
                "password": "anypassword",
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED
        assert "Incorrect email or password" in response.json()["detail"]

    def test_login_inactive_user(self, client: TestClient, test_inactive_user):
        """Test login with inactive user account."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "inactive@example.com",
                "password": "inactivepass123",
            },
        )
        assert response.status_code == HTTPStatus.BAD_REQUEST
        assert "Inactive user" in response.json()["detail"]

    def test_login_invalid_email_format(self, client: TestClient):
        """Test login with invalid email format."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "invalid-email",
                "password": "anypassword",
            },
        )
        assert response.status_code == HTTPStatus.UNPROCESSABLE_ENTITY


class TestAuthLoginForm:
    """Tests for POST /api/auth/login/form endpoint (OAuth2)."""

    def test_login_form_success(self, client: TestClient, test_user):
        """Test successful OAuth2 form login."""
        response = client.post(
            "/api/auth/login/form",
            data={
                "username": "test@example.com",  # OAuth2 uses "username" field
                "password": "testpass123",
            },
        )
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    def test_login_form_wrong_password(self, client: TestClient, test_user):
        """Test OAuth2 form login with wrong password."""
        response = client.post(
            "/api/auth/login/form",
            data={
                "username": "test@example.com",
                "password": "wrongpassword",
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED
        assert "Incorrect email or password" in response.json()["detail"]

    def test_login_form_nonexistent_user(self, client: TestClient):
        """Test OAuth2 form login with non-existent user."""
        response = client.post(
            "/api/auth/login/form",
            data={
                "username": "nonexistent@example.com",
                "password": "anypassword",
            },
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_login_form_inactive_user(self, client: TestClient, test_inactive_user):
        """Test OAuth2 form login with inactive user."""
        response = client.post(
            "/api/auth/login/form",
            data={
                "username": "inactive@example.com",
                "password": "inactivepass123",
            },
        )
        assert response.status_code == HTTPStatus.BAD_REQUEST
        assert "Inactive user" in response.json()["detail"]


class TestAuthMe:
    """Tests for GET /api/auth/me endpoint."""

    def test_get_current_user_success(self, client: TestClient, auth_headers: dict):
        """Test getting current authenticated user."""
        response = client.get("/api/auth/me", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["username"] == "testuser"
        assert data["is_active"] is True

    def test_get_current_user_without_token(self, client: TestClient):
        """Test getting current user without token."""
        response = client.get("/api/auth/me")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_invalid_token(self, client: TestClient):
        """Test getting current user with invalid token."""
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer invalid_token_here"},
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_malformed_header(self, client: TestClient):
        """Test getting current user with malformed auth header."""
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "InvalidFormat token"},
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_get_current_user_includes_metrics(
        self, client: TestClient, auth_headers: dict
    ):
        """Test that current user response includes metrics."""
        response = client.get("/api/auth/me", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "user_metrics" in data
        assert len(data["user_metrics"]) > 0


class TestAuthTokenValidation:
    """Tests for JWT token validation and expiration."""

    def test_token_contains_correct_claims(self, client: TestClient, test_user):
        """Test that token contains correct claims."""
        response = client.post(
            "/api/auth/login",
            json={
                "email": "test@example.com",
                "password": "testpass123",
            },
        )
        token = response.json()["access_token"]

        # Decode token to verify claims
        from jose import jwt

        from app.core.config import settings

        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        assert payload["sub"] == "test@example.com"
        assert "exp" in payload

    def test_device_token_success(self, client: TestClient, auth_headers: dict):
        """Authenticated user can obtain a device token."""
        response = client.post("/api/auth/device-token", headers=auth_headers)
        assert response.status_code == HTTPStatus.OK
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        # Device token has no expiry — verify by decoding
        from jose import jwt
        from app.core.config import settings

        payload = jwt.decode(
            data["access_token"],
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
            options={"verify_exp": False},
        )
        assert payload.get("scope") == "device"
        assert "exp" not in payload

    def test_device_token_requires_auth(self, client: TestClient):
        """Unauthenticated request for device token is rejected."""
        response = client.post("/api/auth/device-token")
        assert response.status_code == HTTPStatus.UNAUTHORIZED

    def test_superuser_can_access_protected_endpoint(
        self, client: TestClient, superuser_auth_headers: dict
    ):
        """Test that superuser can access protected endpoints."""
        response = client.get("/api/auth/me", headers=superuser_auth_headers)
        assert response.status_code == HTTPStatus.OK
        assert response.json()["is_superuser"] is True

    def test_expired_token_rejected(self, client: TestClient, test_user, monkeypatch):
        """Test that expired tokens are rejected."""
        from datetime import timedelta

        from app.core.security import create_access_token

        # Create a token that expires immediately
        expired_token = create_access_token(
            data={"sub": "test@example.com"}, expires_delta=timedelta(seconds=-1)
        )

        response = client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        assert response.status_code == HTTPStatus.UNAUTHORIZED
