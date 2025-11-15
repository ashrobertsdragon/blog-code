"""Database connection management with SQLModel.

Provides PostgreSQL connection management using SQLModel with connection
pooling, health checks, and session lifecycle management for dependency
injection.
"""

from collections.abc import Generator
from functools import lru_cache

from sqlalchemy.engine import Engine
from sqlmodel import Session, create_engine

from config import get_db_url


@lru_cache
def get_engine() -> Engine:
    """Get or create database engine.

    Returns:
        Cached SQLModel engine instance

    Note:
        Uses pool_pre_ping for connection health checks.
    """
    return create_engine(
        get_db_url(),
        pool_pre_ping=True,
        echo=False,
    )


def get_db() -> Generator[Session]:
    """Context manager for database sessions.

    Yields:
        SQLModel Session instance
    """
    with Session(get_engine()) as session:
        yield session
