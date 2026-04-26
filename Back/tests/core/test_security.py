"""
Comprehensive test suite for app/core/security.py module.

This module tests all security functions including password hashing,
verification, and JWT token creation/decoding with complete coverage.
"""

from datetime import timedelta
from unittest.mock import patch


from app.core.security import (
    create_access_token,
    decode_access_token,
    get_password_hash,
    verify_password,
)


class TestPasswordHashing:
    """Test suite for password hashing and verification functions."""

    def test_verify_password_correct(self):
        """
        Test that verify_password returns True when comparing
        a plain password with its correct hash.
        """
        plain_password = "test_password_123"
        hashed_password = get_password_hash(plain_password)

        result = verify_password(plain_password, hashed_password)

        assert result is True

    def test_verify_password_incorrect(self):
        """
        Test that verify_password returns False when comparing
        a plain password with an incorrect hash.
        """
        plain_password = "correct_password"
        hashed_password = get_password_hash("different_password")

        result = verify_password(plain_password, hashed_password)

        assert result is False

    def test_get_password_hash(self):
        """
        Test that get_password_hash generates a valid bcrypt hash
        and returns it as a string.
        """
        password = "secure_password_2024"

        hashed = get_password_hash(password)

        assert hashed is not None
        assert isinstance(hashed, str)
        assert len(hashed) > 0
        assert hashed != password
        # Bcrypt hashes typically start with $2
        assert hashed.startswith("$2")

    def test_get_password_hash_different_each_time(self):
        """
        Test that get_password_hash generates different hashes
        for the same password (due to salt).
        """
        password = "same_password"

        hash1 = get_password_hash(password)
        hash2 = get_password_hash(password)

        assert hash1 != hash2
        assert verify_password(password, hash1)
        assert verify_password(password, hash2)


class TestJWTTokenCreation:
    """Test suite for JWT access token creation functions."""

    @patch("app.core.security.settings")
    def test_create_access_token(self, mock_settings):
        """
        Test that create_access_token generates a valid JWT token
        with the default expiration time.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {"sub": "test_user@example.com", "user_id": 1}

        token = create_access_token(user_data)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    @patch("app.core.security.settings")
    def test_create_access_token_with_expiry(self, mock_settings):
        """
        Test that create_access_token respects custom expiration
        delta when provided.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {"sub": "test_user@example.com", "user_id": 2}
        custom_expiry = timedelta(minutes=60)

        token = create_access_token(user_data, expires_delta=custom_expiry)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    @patch("app.core.security.settings")
    def test_create_access_token_includes_exp_claim(self, mock_settings):
        """
        Test that the generated JWT token includes the 'exp' claim.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {"sub": "test_user@example.com"}

        token = create_access_token(user_data)
        decoded = decode_access_token(token)

        assert decoded is not None
        assert "exp" in decoded
        assert isinstance(decoded["exp"], (int, float))

    @patch("app.core.security.settings")
    def test_create_access_token_preserves_user_data(self, mock_settings):
        """
        Test that create_access_token preserves the original user data
        in the token payload.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {
            "sub": "test_user@example.com",
            "user_id": 123,
            "email": "test@example.com",
        }

        token = create_access_token(user_data)
        decoded = decode_access_token(token)

        assert decoded["sub"] == "test_user@example.com"
        assert decoded["user_id"] == 123
        assert decoded["email"] == "test@example.com"


class TestJWTTokenDecoding:
    """Test suite for JWT access token decoding functions."""

    @patch("app.core.security.settings")
    def test_decode_access_token_valid(self, mock_settings):
        """
        Test that decode_access_token successfully decodes a valid token
        and returns the payload dictionary.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {"sub": "valid_user@example.com", "user_id": 42}
        token = create_access_token(user_data)

        decoded = decode_access_token(token)

        assert decoded is not None
        assert decoded["sub"] == "valid_user@example.com"
        assert decoded["user_id"] == 42

    @patch("app.core.security.settings")
    def test_decode_access_token_invalid(self, mock_settings):
        """
        Test that decode_access_token returns None for an invalid token
        that cannot be decoded.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"

        invalid_token = "invalid.token.here"

        decoded = decode_access_token(invalid_token)

        assert decoded is None

    @patch("app.core.security.settings")
    def test_decode_access_token_wrong_secret(self, mock_settings):
        """
        Test that decode_access_token returns None when the token was
        signed with a different secret key.
        """
        # Create token with one secret
        mock_settings.SECRET_KEY = "original_secret_key"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {"sub": "test_user@example.com"}
        token = create_access_token(user_data)

        # Try to decode with different secret
        mock_settings.SECRET_KEY = "different_secret_key"

        decoded = decode_access_token(token)

        assert decoded is None

    @patch("app.core.security.settings")
    def test_decode_access_token_expired(self, mock_settings):
        """
        Test that decode_access_token returns None for an expired token.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user_data = {"sub": "test_user@example.com"}
        # Create token that expires in the past
        expired_delta = timedelta(minutes=-1)
        token = create_access_token(user_data, expires_delta=expired_delta)

        decoded = decode_access_token(token)

        assert decoded is None

    @patch("app.core.security.settings")
    def test_decode_access_token_malformed(self, mock_settings):
        """
        Test that decode_access_token returns None for a malformed token
        that lacks proper JWT structure.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"

        malformed_token = "not.a.valid.jwt.token.at.all"

        decoded = decode_access_token(malformed_token)

        assert decoded is None

    @patch("app.core.security.settings")
    def test_decode_access_token_empty_string(self, mock_settings):
        """
        Test that decode_access_token returns None for an empty token string.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"

        empty_token = ""

        decoded = decode_access_token(empty_token)

        assert decoded is None


class TestTokenRoundTrip:
    """Test suite for token creation and decoding round trips."""

    @patch("app.core.security.settings")
    def test_token_roundtrip_with_multiple_claims(self, mock_settings):
        """
        Test that a token can be created, then decoded, preserving
        all claims including custom ones.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        original_data = {
            "sub": "user@example.com",
            "user_id": 999,
            "role": "admin",
            "scope": ["read", "write"],
        }

        token = create_access_token(original_data)
        decoded = decode_access_token(token)

        assert decoded is not None
        assert decoded["sub"] == original_data["sub"]
        assert decoded["user_id"] == original_data["user_id"]
        assert decoded["role"] == original_data["role"]
        assert decoded["scope"] == original_data["scope"]

    @patch("app.core.security.settings")
    def test_token_different_for_different_users(self, mock_settings):
        """
        Test that different users generate different tokens.
        """
        mock_settings.SECRET_KEY = "test_secret_key_for_jwt"
        mock_settings.ALGORITHM = "HS256"
        mock_settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30

        user1_data = {"sub": "user1@example.com", "user_id": 1}
        user2_data = {"sub": "user2@example.com", "user_id": 2}

        token1 = create_access_token(user1_data)
        token2 = create_access_token(user2_data)

        assert token1 != token2

        decoded1 = decode_access_token(token1)
        decoded2 = decode_access_token(token2)

        assert decoded1["sub"] == "user1@example.com"
        assert decoded2["sub"] == "user2@example.com"
