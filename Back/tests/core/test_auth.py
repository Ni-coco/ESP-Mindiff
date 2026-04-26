from http import HTTPStatus

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_register_user():
    """Test creating a new user."""
    response = client.post(
        "/api/auth/register",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123",
        },
    )
    assert response.status_code == HTTPStatus.CREATED
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["username"] == "testuser"
    assert "hashed_password" not in data
    assert data["is_active"] is True
    assert data["is_superuser"] is False


def test_register_duplicate_email():
    """Test creating a new user with an email already registered."""
    client.post(
        "/api/auth/register",
        json={
            "email": "duplicate@example.com",
            "username": "user1",
            "password": "testpass123",
        },
    )

    # Tentative de duplication
    response = client.post(
        "/api/auth/register",
        json={
            "email": "duplicate@example.com",
            "username": "user2",
            "password": "testpass123",
        },
    )
    assert response.status_code == HTTPStatus.BAD_REQUEST
    assert "Email already registered" in response.json()["detail"]


def test_register_duplicate_username():
    """Test creating a new user with a username already taken."""
    client.post(
        "/api/auth/register",
        json={
            "email": "user3@example.com",
            "username": "duplicateuser",
            "password": "testpass123",
        },
    )

    response = client.post(
        "/api/auth/register",
        json={
            "email": "user4@example.com",
            "username": "duplicateuser",
            "password": "testpass123",
        },
    )
    assert response.status_code == HTTPStatus.BAD_REQUEST
    assert "Username already taken" in response.json()["detail"]


def test_login_success():
    """Test of successful login."""
    client.post(
        "/api/auth/register",
        json={
            "email": "login@example.com",
            "username": "loginuser",
            "password": "testpass123",
        },
    )

    response = client.post(
        "/api/auth/login",
        json={"email": "login@example.com", "password": "testpass123"},
    )
    assert response.status_code == HTTPStatus.OK
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert len(data["access_token"]) > 0


def test_login_wrong_password():
    """Test login with wrong password"""
    client.post(
        "/api/auth/register",
        json={
            "email": "wrongpass@example.com",
            "username": "wrongpassuser",
            "password": "correctpass123",
        },
    )

    response = client.post(
        "/api/auth/login",
        json={"email": "wrongpass@example.com", "password": "wrongpassword"},
    )
    assert response.status_code == HTTPStatus.UNAUTHORIZED
    assert "Incorrect email or password" in response.json()["detail"]


def test_login_nonexistent_user():
    """Test login with nonexistent user."""
    response = client.post(
        "/api/auth/login",
        json={"email": "nonexistent@example.com", "password": "testpass123"},
    )
    assert response.status_code == HTTPStatus.UNAUTHORIZED
    assert "Incorrect email or password" in response.json()["detail"]


def test_get_current_user():
    """Test for getting the current user."""
    client.post(
        "/api/auth/register",
        json={
            "email": "currentuser@example.com",
            "username": "currentuser",
            "password": "testpass123",
        },
    )

    login_response = client.post(
        "/api/auth/login",
        json={"email": "currentuser@example.com", "password": "testpass123"},
    )
    token = login_response.json()["access_token"]

    response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == HTTPStatus.OK
    data = response.json()
    assert data["email"] == "currentuser@example.com"
    assert data["username"] == "currentuser"


def test_get_current_user_without_token():
    """Test getting current user without token."""
    response = client.get("/api/auth/me")
    assert response.status_code == HTTPStatus.UNAUTHORIZED


def test_get_current_user_invalid_token():
    """Test getting current user with invalid token."""
    response = client.get(
        "/api/auth/me", headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == HTTPStatus.UNAUTHORIZED
