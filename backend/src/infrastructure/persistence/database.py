"""Database connection management with SQLModel.

Provides PostgreSQL connection management using SQLModel with connection
pooling, health checks, and session lifecycle management for dependency
injection.
"""

from collections.abc import Generator
from functools import lru_cache

from sqlalchemy.engine import Engine
from sqlmodel import Session, create_engine

from config import get_db_settings


@lru_cache
def get_engine() -> Engine:
    """Get or create database engine.

    Returns:
        Cached SQLModel engine instance

    Note:
        Engine is created once and cached for reuse.
        Uses pool_pre_ping for connection health checks.
    """
    settings = get_db_settings()
    return create_engine(
        f"postgresql+psycopg2://{settings.DB_USER}:{settings.DB_PASSWORD}"
        f"@{settings.DB_HOST}/{settings.DB_NAME}",
        pool_pre_ping=True,
        echo=False,
    )


def get_db() -> Generator[Session]:
    """Dependency injection function for database sessions.

    Yields:
        SQLModel Session instance

    Note:
        Uses context manager for automatic session cleanup.
        Use with FastAPI Depends() or Flask teardown for automatic cleanup.
    """
    with Session(get_engine()) as session:
        yield session
