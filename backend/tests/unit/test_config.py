"""Unit tests for configuration management.

Tests Pydantic Settings class that loads all configuration from environment
variables with proper validation and fail-fast behavior on missing variables.
"""

import pytest
from pydantic import ValidationError

from config import Settings


@pytest.fixture
def clean_env(monkeypatch):
    """Clear all DB-related environment variables."""
    for key in [
        "DB_HOST",
        "DB_PORT",
        "DB_NAME",
        "DB_USER",
        "DB_PASS",
        "FLASK_ENV",
    ]:
        monkeypatch.delenv(key, raising=False)
    return monkeypatch


@pytest.fixture
def valid_env(clean_env):
    """Set all required environment variables with valid values."""
    clean_env.setenv("DB_HOST", "localhost")
    clean_env.setenv("DB_PORT", "5432")
    clean_env.setenv("DB_NAME", "blog_db")
    clean_env.setenv("DB_USER", "blog_user")
    clean_env.setenv("DB_PASS", "secure_password")
    clean_env.setenv("FLASK_ENV", "production")
    return clean_env


@pytest.fixture
def minimal_env(clean_env):
    """Set only required environment variables without defaults."""
    clean_env.setenv("DB_HOST", "localhost")
    clean_env.setenv("DB_NAME", "blog_db")
    clean_env.setenv("DB_USER", "blog_user")
    clean_env.setenv("DB_PASS", "secure_password")
    return clean_env


def test_settings_can_be_imported():
    """Settings class should be importable from config module."""
    assert Settings is not None


def test_settings_has_all_required_fields():
    """Settings should define all required configuration fields."""
    assert hasattr(Settings, "model_fields")
    required_fields = {
        "DB_HOST",
        "DB_PORT",
        "DB_NAME",
        "DB_USER",
        "DB_PASS",
        "FLASK_ENV",
    }
    settings_fields = set(Settings.model_fields.keys())
    assert required_fields.issubset(settings_fields), (
        f"Missing fields: {required_fields - settings_fields}"
    )


def test_db_port_has_default_value():
    """DB_PORT should have a default value of 5432."""
    db_port_field = Settings.model_fields.get("DB_PORT")
    assert db_port_field is not None
    assert db_port_field.default == 5432


def test_flask_env_has_default_value():
    """FLASK_ENV should have a default value of 'production'."""
    flask_env_field = Settings.model_fields.get("FLASK_ENV")
    assert flask_env_field is not None
    assert flask_env_field.default == "production"


@pytest.mark.parametrize(
    "missing_field", ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASS"]
)
def test_missing_required_field_raises_validation_error(
    valid_env, missing_field
):
    """Settings should raise ValidationError on missing required field."""
    valid_env.delenv(missing_field)

    with pytest.raises(ValidationError) as exc_info:
        Settings()

    assert missing_field in str(exc_info.value)


def test_valid_settings_with_all_fields(valid_env):
    """Settings should instantiate successfully with all required fields."""
    settings = Settings()

    assert settings.DB_HOST == "localhost"
    assert settings.DB_PORT == 5432
    assert settings.DB_NAME == "blog_db"
    assert settings.DB_USER == "blog_user"
    assert settings.DB_PASS == "secure_password"
    assert settings.FLASK_ENV == "production"


def test_valid_settings_with_defaults(minimal_env):
    """Settings should use defaults for optional fields when not provided."""
    settings = Settings()

    assert settings.DB_HOST == "localhost"
    assert settings.DB_PORT == 5432
    assert settings.DB_NAME == "blog_db"
    assert settings.DB_USER == "blog_user"
    assert settings.DB_PASS == "secure_password"
    assert settings.FLASK_ENV == "production"


def test_db_port_is_integer(valid_env):
    """DB_PORT should be an integer."""
    settings = Settings()

    assert isinstance(settings.DB_PORT, int)
    assert settings.DB_PORT == 5432


def test_db_port_converts_string_to_int(minimal_env):
    """DB_PORT should be converted from string to integer."""
    minimal_env.setenv("DB_PORT", "3306")
    settings = Settings()

    assert isinstance(settings.DB_PORT, int)
    assert settings.DB_PORT == 3306


def test_db_port_invalid_string_raises_validation_error(minimal_env):
    """DB_PORT should raise ValidationError if not a valid integer."""
    minimal_env.setenv("DB_PORT", "not_a_number")

    with pytest.raises(ValidationError):
        Settings()


def test_string_fields_are_strings(valid_env):
    """String fields should be str type."""
    settings = Settings()

    assert isinstance(settings.DB_HOST, str)
    assert isinstance(settings.DB_NAME, str)
    assert isinstance(settings.DB_USER, str)
    assert isinstance(settings.DB_PASS, str)
    assert isinstance(settings.FLASK_ENV, str)


def test_settings_reads_from_environment_variables(clean_env):
    """Settings should read values from environment variables."""
    test_values = {
        "DB_HOST": "db.example.com",
        "DB_PORT": "5433",
        "DB_NAME": "production_db",
        "DB_USER": "prod_user",
        "DB_PASS": "prod_password",
        "FLASK_ENV": "production",
    }

    for key, value in test_values.items():
        clean_env.setenv(key, value)

    settings = Settings()

    assert settings.DB_HOST == "db.example.com"
    assert settings.DB_PORT == 5433
    assert settings.DB_NAME == "production_db"
    assert settings.DB_USER == "prod_user"
    assert settings.DB_PASS == "prod_password"
    assert settings.FLASK_ENV == "production"


def test_settings_uses_env_config_class():
    """Settings should use Config class with env_file configuration."""
    assert hasattr(Settings, "Config") or hasattr(Settings, "model_config")


def test_db_host_accepts_localhost(minimal_env):
    """DB_HOST should accept 'localhost' for cPanel deployments."""
    settings = Settings()
    assert settings.DB_HOST == "localhost"


def test_singleton_pattern_optional():
    """Settings should ideally be instantiated once (singleton pattern)."""

    assert Settings is not None
    assert hasattr(Settings, "DB_HOST")


def test_settings_no_hardcoded_secrets():
    """Settings class should not contain any hardcoded secrets."""
    import config

    with open(config.__file__) as f:
        config_source = f.read()

    dangerous_patterns = [
        "password",
        "secret",
        "api_key",
        "token",
        "credentials",
    ]

    for pattern in dangerous_patterns:
        assert (
            "=" not in config_source
            or pattern not in config_source.lower()
            or "environment" in config_source.lower()
        ), f"Potential hardcoded secret containing '{pattern}' found"
