"""Shared fixtures for integration tests."""

from pathlib import Path
from unittest.mock import patch

import pytest


@pytest.fixture
def mock_build_dir():
    """Mock the build directory path to avoid requiring actual React build."""
    with patch("pathlib.Path.exists") as mock_exists:
        mock_exists.return_value = True
        yield Path("monorepo/frontend/dist")


@pytest.fixture
def app(dev_settings, mock_build_dir):
    """Create Flask app using factory pattern for testing.

    Uses the actual create_app() factory function with mocked build directory.
    """
    from main import create_app

    with patch("pathlib.Path.exists", return_value=True):
        app = create_app(config={"TESTING": True})

    return app


@pytest.fixture
def client(app):
    """Create Flask test client."""
    return app.test_client()
