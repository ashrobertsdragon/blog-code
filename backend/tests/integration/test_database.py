"""Integration tests for database connection management.

Tests SQLModel engine initialization, connection pooling, and session
lifecycle management with dependency injection pattern.
"""

import pytest
from sqlalchemy.exc import OperationalError
from sqlmodel import Session, select

from infrastructure.persistence.database import get_db, get_engine


def test_get_engine_returns_engine(dev_settings):
    """get_engine should return SQLModel engine instance."""
    from sqlalchemy.engine import Engine

    get_engine.cache_clear()
    engine = get_engine()
    assert isinstance(engine, Engine)


def test_engine_uses_postgresql(dev_settings):
    """Engine should be configured for PostgreSQL."""
    get_engine.cache_clear()
    engine = get_engine()
    assert "postgresql" in str(engine.url)


def test_engine_uses_localhost(dev_settings):
    """Engine should use localhost for DB_HOST (cPanel requirement)."""
    get_engine.cache_clear()
    engine = get_engine()
    assert engine.url.host == "localhost"


def test_engine_has_pool_pre_ping(dev_settings):
    """Engine should configure pool_pre_ping for health checks."""
    get_engine.cache_clear()
    engine = get_engine()
    assert engine.pool._pre_ping is True


def test_get_engine_is_cached(dev_settings):
    """get_engine should return same instance on repeated calls."""
    get_engine.cache_clear()
    engine1 = get_engine()
    engine2 = get_engine()
    assert engine1 is engine2


def test_get_db_is_generator():
    """get_db should be a generator function."""
    import inspect

    assert inspect.isgeneratorfunction(get_db)


def test_get_db_yields_session(dev_settings):
    """get_db should yield SQLModel Session instance."""
    db_gen = get_db()
    session = next(db_gen)

    assert isinstance(session, Session)

    try:
        next(db_gen)
    except StopIteration:
        pass


def test_session_can_execute_simple_query(dev_settings):
    """Session from get_db should execute SELECT queries."""
    db_gen = get_db()
    session = next(db_gen)

    try:
        result = session.exec(select(1)).one()
        assert result == 1
    except OperationalError as e:
        pytest.skip(f"Database not available: {e}")
    finally:
        try:
            next(db_gen)
        except StopIteration:
            pass


def test_multiple_get_db_calls_yield_different_sessions(dev_settings):
    """Multiple calls to get_db should yield independent sessions."""
    db_gen1 = get_db()
    db_gen2 = get_db()

    session1 = next(db_gen1)
    session2 = next(db_gen2)

    assert session1 is not session2

    for gen in [db_gen1, db_gen2]:
        try:
            next(gen)
        except StopIteration:
            pass
