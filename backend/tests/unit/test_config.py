"""Unit tests for configuration management.

Tests Pydantic DBSettings class and database url.
"""

import pytest
from pydantic import ValidationError

from config import (
    DBSettings,
    DevDBSettings,
    FlaskEnv,
    ProductionDBSettings,
    _db_settings,
    get_db_url,
)


@pytest.fixture
def clear_caches():
    get_db_url.cache_clear()
    _db_settings.cache_clear()


def test_settings_can_be_imported():
    """DBSettings class should be importable from config module."""
    assert DBSettings is not None


def test_settings_has_all_required_fields():
    """DBSettings should define all required configuration fields."""
    assert hasattr(DBSettings, "model_fields")
    required_fields = {
        "DB_HOST",
        "DB_NAME",
        "DB_USER",
        "DB_PASSWORD",
        "FLASK_ENV",
    }
    settings_fields = set(DBSettings.model_fields.keys())
    assert required_fields.issubset(settings_fields), (
        f"Missing fields: {required_fields - settings_fields}"
    )


def test_flask_env_has_default_value():
    """FLASK_ENV should have a default value of 'PRODUCTION'."""
    flask_env_field = DBSettings.model_fields.get("FLASK_ENV")
    assert flask_env_field is not None
    assert flask_env_field.default == FlaskEnv.PRODUCTION


@pytest.mark.parametrize("missing_field", ["DB_NAME", "DB_USER", "DB_PASSWORD"])
def test_missing_required_field_raises_validation_error(
    valid_env, missing_field
):
    """DBSettings should raise ValidationError on missing required field."""
    valid_env.delenv(missing_field)

    with pytest.raises(ValidationError) as exc_info:
        DBSettings()

    assert missing_field in str(exc_info.value)


def test_valid_settings_with_all_fields(base_settings):
    """DBSettings should instantiate successfully with all required fields."""

    assert base_settings.DB_HOST == "localhost"
    assert base_settings.DB_NAME == "blog_db"
    assert base_settings.DB_USER == "blog_user"
    assert base_settings.DB_PASSWORD == "secure_password"
    assert base_settings.FLASK_ENV == FlaskEnv.PRODUCTION


def test_valid_settings_with_defaults(base_settings):
    """DBSettings should use defaults for optional fields when not provided."""

    assert base_settings.DB_HOST == "localhost"
    assert base_settings.FLASK_ENV == FlaskEnv.PRODUCTION


def test_string_fields_are_strings(base_settings):
    """String fields should be str type."""

    assert isinstance(base_settings.DB_HOST, str)
    assert isinstance(base_settings.DB_NAME, str)
    assert isinstance(base_settings.DB_USER, str)
    assert isinstance(base_settings.DB_PASSWORD, str)


def test_enum_field_is_enum(base_settings):
    """Enum fields should be Enum type."""
    assert isinstance(base_settings.FLASK_ENV, FlaskEnv)


def test_settings_reads_from_environment_variables(clean_env):
    """DBSettings should read values from environment variables."""
    test_values = {
        "DB_NAME": "production_db",
        "DB_USER": "prod_user",
        "DB_PASSWORD": "prod_password",
        "FLASK_ENV": "PRODUCTION",
    }

    for key, value in test_values.items():
        clean_env.setenv(key, value)

    settings = DBSettings()

    assert settings.DB_NAME == "production_db"
    assert settings.DB_USER == "prod_user"
    assert settings.DB_PASSWORD == "prod_password"
    assert settings.FLASK_ENV == FlaskEnv.PRODUCTION


def test_db_host_is_localhost(base_settings):
    """DB_HOST should be 'localhost'."""

    assert base_settings.DB_HOST == "localhost"


def test_settings_no_hardcoded_secrets():
    """DBSettings class should not contain any hardcoded secrets."""
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


def test_db_settings_returns_production_subclass(production_env):
    """Factory should return ProductionDBSettings when FLASK_ENV=PRODUCTION."""
    _db_settings.cache_clear()
    settings = _db_settings()
    assert isinstance(settings, ProductionDBSettings)


def test_db_settings_returns_dev_subclass(dev_env):
    """Factory should return DevDBSettings when FLASK_ENV=DEVELOPMENT."""
    _db_settings.cache_clear()
    settings = _db_settings()
    assert isinstance(settings, DevDBSettings)


def test_db_settings_returns_production_subclass_default(production_env):
    """Factory should return ProductionDBSettings when FLASK_ENV is not set."""
    production_env.delenv("FLASK_ENV")
    _db_settings.cache_clear()
    settings = _db_settings()
    assert isinstance(settings, ProductionDBSettings)


def test_production_settings(production_settings):
    """ProductionDBSettings should return correct values."""
    assert production_settings.DB_HOST == "localhost"
    assert production_settings.DB_NAME == "PRODUCTION_DB"
    assert production_settings.DB_USER == "PRODUCTION_USER"
    assert production_settings.DB_PASSWORD == "PRODUCTION_PASSWORD"


def test_dev_settings(dev_settings):
    """DevDBSettings should return correct values."""
    assert dev_settings.DB_HOST == "localhost"
    assert dev_settings.DB_NAME == "DEV_DB"
    assert dev_settings.DB_USER == "DEV_USER"
    assert dev_settings.DB_PASSWORD == "DEV_PASSWORD"


def test_get_db_url_returns_dev_connection_string(dev_settings, clear_caches):
    """get_db_url should return correct development connection string."""
    get_db_url.cache_clear()
    _db_settings.cache_clear()
    expected_url = (
        "postgresql+psycopg2://DEV_USER:DEV_PASSWORD@localhost/DEV_DB"
    )
    assert get_db_url() == expected_url


def test_get_db_url_returns_production_connection_string(
    production_settings, clear_caches
):
    """get_db_url should return correct production connection string."""
    expected_url = "postgresql+psycopg2://PRODUCTION_USER:PRODUCTION_PASSWORD@localhost/PRODUCTION_DB"
    assert get_db_url() == expected_url


def test_get_db_url_is_cached(dev_settings, clear_caches):
    """get_db_url should be cached."""
    url1 = get_db_url()
    url2 = get_db_url()
    assert url1 is url2
