"""Shared test fixtures for all test modules."""

import pytest

from config import DBSettings, DevDBSettings, ProductionDBSettings


@pytest.fixture
def clean_env(monkeypatch):
    """Clear all DB-related environment variables."""
    for key in [
        "DB_NAME",
        "DB_USER",
        "DB_PASSWORD",
        "FLASK_ENV",
    ]:
        monkeypatch.delenv(key, raising=False)
    return monkeypatch


@pytest.fixture
def valid_env(clean_env):
    """Fixture to set environment variables."""
    clean_env.setenv("DB_NAME", "blog_db")
    clean_env.setenv("DB_USER", "blog_user")
    clean_env.setenv("DB_PASSWORD", "secure_password")
    return clean_env


@pytest.fixture
def base_settings(valid_env) -> DBSettings:
    """Fixture to initialize base DBSettings class."""
    return DBSettings()


@pytest.fixture
def production_env(clean_env):
    """Fixture to initialize ProductionDBSettings environment variables."""
    clean_env.setenv("FLASK_ENV", "PRODUCTION")
    clean_env.setenv("CPANEL_DB_NAME", "PRODUCTION_DB")
    clean_env.setenv("CPANEL_DB_USER", "PRODUCTION_USER")
    clean_env.setenv("CPANEL_DB_PASSWORD", "PRODUCTION_PASSWORD")
    return clean_env


@pytest.fixture
def production_settings(production_env) -> ProductionDBSettings:
    """Fixture to initialize ProductionDBSettings class."""
    return ProductionDBSettings()


@pytest.fixture
def dev_env(clean_env):
    """Fixture to initialize DevDBSettings environment variables."""
    clean_env.setenv("FLASK_ENV", "DEVELOPMENT")
    clean_env.setenv("LOCAL_DB_NAME", "DEV_DB")
    clean_env.setenv("LOCAL_DB_USER", "DEV_USER")
    clean_env.setenv("LOCAL_DB_PASSWORD", "DEV_PASSWORD")
    return clean_env


@pytest.fixture
def dev_settings(dev_env) -> DevDBSettings:
    """Fixture to initialize DevDBSettings class."""
    return DevDBSettings()
