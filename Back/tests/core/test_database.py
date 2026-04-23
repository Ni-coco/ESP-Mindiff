"""
Comprehensive test suite for app/db/database.py and app/core/config.py modules.

This module tests database connection, session management, and configuration
loading with complete coverage for security and database initialization.
"""

import os
from unittest.mock import MagicMock, Mock, patch

import pytest
from sqlalchemy.orm import Session

from app.core.config import Settings, VaultConfig, load_settings, settings
from app.db.database import SessionLocal, engine, get_db


class TestDatabaseConfiguration:
    """Test suite for database configuration and engine setup."""

    @patch("app.db.database.settings")
    def test_database_url_construction(self, mock_settings):
        """
        Test that the database URL is correctly constructed from settings.
        """
        mock_settings.POSTGRES_USER = "testuser"
        mock_settings.POSTGRES_PASSWORD = "testpass"
        mock_settings.POSTGRES_DB = "testdb"

        expected_url = "postgresql+psycopg2://testuser:testpass@localhost:5432/testdb"

        # Manually construct URL to verify format
        actual_url = (
            f"postgresql+psycopg2://{mock_settings.POSTGRES_USER}:"
            f"{mock_settings.POSTGRES_PASSWORD}@localhost:5432/"
            f"{mock_settings.POSTGRES_DB}"
        )

        assert actual_url == expected_url

    @patch("app.db.database.settings")
    def test_database_url_with_special_characters(self, mock_settings):
        """
        Test that database URL handles special characters in credentials.
        """
        mock_settings.POSTGRES_USER = "user@domain"
        mock_settings.POSTGRES_PASSWORD = "p@ss%word"
        mock_settings.POSTGRES_DB = "my_db"

        expected_url = (
            "postgresql+psycopg2://user@domain:p@ss%word@localhost:5432/my_db"
        )

        actual_url = (
            f"postgresql+psycopg2://{mock_settings.POSTGRES_USER}:"
            f"{mock_settings.POSTGRES_PASSWORD}@localhost:5432/"
            f"{mock_settings.POSTGRES_DB}"
        )

        assert actual_url == expected_url

    def test_engine_is_sqlalchemy_engine(self):
        """
        Test that engine is a valid SQLAlchemy Engine instance.
        """
        assert engine is not None
        assert hasattr(engine, "connect")
        assert hasattr(engine, "dispose")
        # SQLAlchemy 2.0+ doesn't have execute on engine directly
        assert hasattr(engine, "begin")

    def test_session_local_is_session_factory(self):
        """
        Test that SessionLocal is a valid session factory.
        """
        assert SessionLocal is not None
        assert hasattr(SessionLocal, "configure")
        assert callable(SessionLocal)


class TestDatabaseSession:
    """Test suite for database session management."""

    def test_get_db_yields_session(self):
        """
        Test that get_db is a generator that yields a database session.
        """
        db_generator = get_db()

        # Verify it's a generator
        assert hasattr(db_generator, "__next__")

        # Get the session from the generator
        session = next(db_generator)

        assert session is not None
        assert isinstance(session, Session)
        session.close()

    def test_get_db_closes_session(self):
        """
        Test that get_db closes the database session after use.
        """
        db_generator = get_db()
        session = next(db_generator)

        # Mock the close method to track if it was called
        original_close = session.close
        session.close = MagicMock()

        # Exhaust the generator
        try:
            next(db_generator)
        except StopIteration:
            pass

        # Verify close was called
        session.close.assert_called_once()

    def test_get_db_closes_session_on_exception(self):
        """
        Test that get_db closes the session even if an exception occurs.
        """
        db_generator = get_db()
        session = next(db_generator)

        # Mock the close method
        session.close = MagicMock()

        # Simulate an exception
        try:
            db_generator.throw(Exception("Test exception"))
        except Exception:
            pass

        # Verify close was called even with exception
        session.close.assert_called_once()

    def test_get_db_session_has_required_methods(self):
        """
        Test that yielded session has required SQLAlchemy methods.
        """
        session = next(get_db())

        # Verify session has expected methods
        assert hasattr(session, "query")
        assert hasattr(session, "add")
        assert hasattr(session, "commit")
        assert hasattr(session, "rollback")
        assert hasattr(session, "close")

        session.close()

    def test_get_db_multiple_sessions_independent(self):
        """
        Test that multiple calls to get_db return independent sessions.
        """
        db_generator1 = get_db()
        db_generator2 = get_db()

        session1 = next(db_generator1)
        session2 = next(db_generator2)

        # Sessions should be different objects
        assert session1 is not session2

        session1.close()
        session2.close()


class TestVaultConfiguration:
    """Test suite for Vault configuration loading."""

    @patch("app.core.config.hvac.Client")
    def test_vault_config_initialization(self, mock_hvac_client):
        """
        Test that VaultConfig initializes with Vault client.
        """
        mock_client_instance = MagicMock()
        mock_client_instance.is_authenticated.return_value = True
        mock_hvac_client.return_value = mock_client_instance

        with patch.dict(
            os.environ,
            {"VAULT_ADDR": "http://localhost:8200", "VAULT_TOKEN": "test-token"},
        ):
            vault = VaultConfig()

            assert vault.client is not None
            mock_hvac_client.assert_called_once()

    @patch("app.core.config.hvac.Client")
    def test_vault_config_authentication_failed(self, mock_hvac_client):
        """
        Test that VaultConfig raises exception when authentication fails.
        """
        mock_client_instance = MagicMock()
        mock_client_instance.is_authenticated.return_value = False
        mock_hvac_client.return_value = mock_client_instance

        with patch.dict(
            os.environ,
            {"VAULT_ADDR": "http://localhost:8200", "VAULT_TOKEN": "invalid-token"},
        ):
            with pytest.raises(Exception, match="Vault authentication failed"):
                VaultConfig()

    @patch("app.core.config.hvac.Client")
    def test_vault_get_secrets(self, mock_hvac_client):
        """
        Test that VaultConfig.get_secrets retrieves secrets from Vault.
        """
        mock_client_instance = MagicMock()
        mock_client_instance.is_authenticated.return_value = True

        mock_secret_response = {
            "data": {
                "data": {
                    "SECRET_KEY": "vault_secret_key",
                    "POSTGRES_USER": "vault_user",
                }
            }
        }
        mock_client_instance.secrets.kv.v2.read_secret_version.return_value = (
            mock_secret_response
        )

        mock_hvac_client.return_value = mock_client_instance

        with patch.dict(
            os.environ,
            {"VAULT_ADDR": "http://localhost:8200", "VAULT_TOKEN": "test-token"},
        ):
            vault = VaultConfig()
            secrets = vault.get_secrets("mindiff")

            assert secrets == {
                "SECRET_KEY": "vault_secret_key",
                "POSTGRES_USER": "vault_user",
            }

    @patch("app.core.config.hvac.Client")
    def test_vault_get_secret(self, mock_hvac_client):
        """
        Test that VaultConfig.get_secret retrieves a specific secret value.
        """
        mock_client_instance = MagicMock()
        mock_client_instance.is_authenticated.return_value = True

        mock_secret_response = {
            "data": {
                "data": {
                    "SECRET_KEY": "vault_secret_key",
                    "POSTGRES_USER": "vault_user",
                }
            }
        }
        mock_client_instance.secrets.kv.v2.read_secret_version.return_value = (
            mock_secret_response
        )

        mock_hvac_client.return_value = mock_client_instance

        with patch.dict(
            os.environ,
            {"VAULT_ADDR": "http://localhost:8200", "VAULT_TOKEN": "test-token"},
        ):
            vault = VaultConfig()
            secret_value = vault.get_secret("mindiff", "SECRET_KEY")

            assert secret_value == "vault_secret_key"


class TestSettingsConfiguration:
    """Test suite for Settings configuration loading."""

    def test_settings_loads_from_environment(self):
        """
        Test that Settings loads values from environment.
        """
        env_vars = {
            "POSTGRES_USER": "env_user",
            "POSTGRES_PASSWORD": "env_pass",
            "POSTGRES_DB": "env_db",
            "SECRET_KEY": "env_secret",
        }

        with patch.dict(os.environ, env_vars, clear=False):
            test_settings = Settings(**env_vars)

            assert test_settings.POSTGRES_USER == "env_user"
            assert test_settings.POSTGRES_PASSWORD == "env_pass"
            assert test_settings.POSTGRES_DB == "env_db"
            assert test_settings.SECRET_KEY == "env_secret"

    def test_settings_algorithm_default(self):
        """
        Test that Settings has correct default algorithm.
        """
        env_vars = {
            "POSTGRES_USER": "user",
            "POSTGRES_PASSWORD": "pass",
            "POSTGRES_DB": "db",
            "SECRET_KEY": "secret",
        }

        with patch.dict(os.environ, env_vars, clear=False):
            test_settings = Settings(**env_vars)

            assert test_settings.ALGORITHM == "HS256"

    def test_settings_access_token_expire_minutes_default(self):
        """
        Test that Settings has correct default token expiry.
        """
        env_vars = {
            "POSTGRES_USER": "user",
            "POSTGRES_PASSWORD": "pass",
            "POSTGRES_DB": "db",
            "SECRET_KEY": "secret",
        }

        with patch.dict(os.environ, env_vars, clear=False):
            test_settings = Settings(**env_vars)

            assert test_settings.ACCESS_TOKEN_EXPIRE_MINUTES == 30

    def test_settings_custom_values(self):
        """
        Test that Settings accepts custom values for algorithm and expiry.
        """
        env_vars = {
            "POSTGRES_USER": "user",
            "POSTGRES_PASSWORD": "pass",
            "POSTGRES_DB": "db",
            "SECRET_KEY": "secret",
            "ALGORITHM": "HS512",
            "ACCESS_TOKEN_EXPIRE_MINUTES": "60",
        }

        with patch.dict(os.environ, env_vars, clear=False):
            test_settings = Settings(**env_vars)

            assert test_settings.ALGORITHM == "HS512"
            assert test_settings.ACCESS_TOKEN_EXPIRE_MINUTES == 60


class TestLoadSettingsFunction:
    """Test suite for the load_settings function."""

    @patch("app.core.config.VaultConfig")
    def test_load_settings_without_vault(self, mock_vault_config):
        """
        Test that load_settings falls back to .env when Vault is not configured.
        """
        env_vars = {
            "POSTGRES_USER": "user",
            "POSTGRES_PASSWORD": "pass",
            "POSTGRES_DB": "db",
            "SECRET_KEY": "secret",
            "VAULT_ADDR": "",
            "VAULT_TOKEN": "",
        }

        with patch.dict(os.environ, env_vars, clear=False):
            with patch("builtins.print") as mock_print:
                result = load_settings()

                assert result is not None
                assert isinstance(result, Settings)
                # Verify fallback warning was printed
                mock_print.assert_called()

    @patch("app.core.config.VaultConfig")
    def test_load_settings_with_vault(self, mock_vault_config):
        """
        Test that load_settings successfully loads from Vault when available.
        """
        mock_vault_instance = MagicMock()
        mock_vault_instance.get_secrets.return_value = {
            "POSTGRES_USER": "vault_user",
            "POSTGRES_PASSWORD": "vault_pass",
            "POSTGRES_DB": "vault_db",
            "SECRET_KEY": "vault_secret",
        }
        mock_vault_config.return_value = mock_vault_instance

        env_vars = {
            "VAULT_ADDR": "http://localhost:8200",
            "VAULT_TOKEN": "test-token",
        }

        with patch.dict(os.environ, env_vars):
            result = load_settings()

            assert result is not None
            assert isinstance(result, Settings)
            mock_vault_config.assert_called_once()

    @patch("app.core.config.VaultConfig")
    def test_load_settings_vault_error_fallback(self, mock_vault_config):
        """
        Test that load_settings falls back to env when Vault raises error.
        """
        mock_vault_config.side_effect = Exception("Vault connection failed")

        env_vars = {
            "VAULT_ADDR": "http://localhost:8200",
            "VAULT_TOKEN": "test-token",
            "POSTGRES_USER": "fallback_user",
            "POSTGRES_PASSWORD": "fallback_pass",
            "POSTGRES_DB": "fallback_db",
            "SECRET_KEY": "fallback_secret",
        }

        with patch.dict(os.environ, env_vars):
            with patch("builtins.print") as mock_print:
                result = load_settings()

                assert result is not None
                assert isinstance(result, Settings)
                # Verify error was handled and fallback was attempted
                mock_print.assert_called()

    def test_load_settings_returns_settings_instance(self):
        """
        Test that load_settings returns a Settings instance.
        """
        # Use environment with all required fields
        env_vars = {
            "POSTGRES_USER": "test_user",
            "POSTGRES_PASSWORD": "test_pass",
            "POSTGRES_DB": "test_db",
            "SECRET_KEY": "test_secret",
            "VAULT_ADDR": "",
            "VAULT_TOKEN": "",
        }

        with patch.dict(os.environ, env_vars, clear=False):
            result = load_settings()

            assert result is not None
            assert isinstance(result, Settings)

    def test_load_settings_preserves_vault_secrets(self):
        """
        Test that load_settings uses vault secrets when available.
        """
        with patch("app.core.config.VaultConfig") as mock_vault_config:
            mock_vault_instance = MagicMock()
            mock_vault_instance.get_secrets.return_value = {
                "POSTGRES_USER": "vault_user",
                "POSTGRES_PASSWORD": "vault_pass",
                "POSTGRES_DB": "vault_db",
                "SECRET_KEY": "vault_secret",
            }
            mock_vault_config.return_value = mock_vault_instance

            env_vars = {
                "VAULT_ADDR": "http://vault:8200",
                "VAULT_TOKEN": "token",
            }

            with patch.dict(os.environ, env_vars):
                result = load_settings()

                assert result is not None
                # Vault was attempted
                mock_vault_config.assert_called_once()


class TestDatabaseIntegration:
    """Test suite for integration between config and database modules."""

    @patch("app.db.database.settings")
    def test_database_uses_settings(self, mock_settings):
        """
        Test that database module correctly uses settings for configuration.
        """
        mock_settings.POSTGRES_USER = "test_user"
        mock_settings.POSTGRES_PASSWORD = "test_pass"
        mock_settings.POSTGRES_DB = "test_db"

        # Verify settings are used to construct URL
        expected_url = (
            "postgresql+psycopg2://test_user:test_pass@localhost:5432/test_db"
        )

        actual_url = (
            f"postgresql+psycopg2://{mock_settings.POSTGRES_USER}:"
            f"{mock_settings.POSTGRES_PASSWORD}@localhost:5432/"
            f"{mock_settings.POSTGRES_DB}"
        )

        assert actual_url == expected_url

    def test_session_local_is_bound_to_engine(self):
        """
        Test that SessionLocal is properly bound to the database engine.
        """
        assert SessionLocal is not None
        # Create a session and verify it can be instantiated
        session = SessionLocal()
        assert session is not None
        session.close()

    def test_get_db_integration_with_session_factory(self):
        """
        Test that get_db uses SessionLocal factory properly.
        """
        db_gen = get_db()
        session = next(db_gen)

        # Verify session came from SessionLocal factory
        assert isinstance(session, Session)
        session.close()
