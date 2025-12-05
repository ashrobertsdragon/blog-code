"""e2e tests for database connection management."""

import os

import pytest
from infrastructure.persistence.database import get_db
from sqlmodel import select


@pytest.mark.skipif(
    not os.environ.get("DB_NAME"), reason="Database not configured"
)
def test_session_can_execute_simple_query():
    """Session from get_db should execute SELECT queries."""
    db_gen = get_db()
    session = next(db_gen)

    result = session.exec(select(1)).one()
    assert result == 1
