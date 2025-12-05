"""Integration tests for Passenger WSGI entry point.

Tests WSGI interface compliance for passenger_wsgi.py module.
This module must expose an 'application' variable that is a WSGI-compliant
Flask application instance.
"""

import os
from unittest.mock import patch

import pytest

if "TYPE_CHECKING":
    from flask.testing import FlaskClient

import passenger_wsgi


@pytest.fixture
def mock_virtualenv() -> str:
    """Fixture providing a mock virtual environment path."""
    return os.path.join("home", "cpaneluser", "virtualenv", "blog")


@pytest.fixture
def mock_interpreter_path() -> str:
    """Fixture providing a mock interpreter path."""
    return os.path.join(
        "home", "cpaneluser", "virtualenv", "blog", "bin", "python3"
    )


@pytest.fixture
def flask_test_client() -> FlaskClient:  # type: ignore
    return passenger_wsgi.application.test_client()  # type: ignore


def test_application_variable_exists():
    """passenger_wsgi module must expose 'application' variable for WSGI spec.

    WSGI servers like Passenger look for a module-level variable named
    'application', not 'app'. This is a WSGI specification requirement.
    """
    with patch("os.execl"):
        assert hasattr(passenger_wsgi, "application"), (
            "passenger_wsgi module must expose 'application' variable"
        )


def test_application_is_flask_app():
    """application variable must be a Flask instance."""
    from flask import Flask

    with patch("os.execl"):
        assert isinstance(passenger_wsgi.application, Flask), (
            "application must be a Flask instance"
        )


def test_application_is_callable():
    """application must be callable to satisfy WSGI spec.

    WSGI spec requires application to be a callable that accepts
    environ and start_response parameters.
    """
    with patch("os.execl"):
        assert callable(passenger_wsgi.application), (
            "application must be callable per WSGI spec"
        )


def test_application_handles_basic_request(flask_test_client):
    """application should handle basic HTTP requests through WSGI interface.

    Tests that the WSGI application can process a basic request using
    Flask's test client, which simulates WSGI environ/start_response.
    """
    with patch("os.execl"):
        response = flask_test_client.get("/health")

        assert response.status_code in (
            200,
            503,
        ), "application should respond to health check"
        assert response.content_type == "application/json", (
            "application should return JSON responses"
        )


def test_health_endpoint_via_wsgi(flask_test_client):
    """Health endpoint should be accessible through WSGI application.

    Verifies that blueprints are properly registered and routes work
    through the WSGI interface.
    """
    with patch("os.execl"):
        response = flask_test_client.get("/health")

        assert response.status_code == 200, "health endpoint should return 200"
        assert response.json is not None, "health endpoint should return JSON"
        assert "status" in response.json, (
            "health endpoint should include status field"
        )


def test_load_environment_loads_correct_python_env(
    mock_virtualenv, mock_interpreter_path
):
    """load_environment should pass the correct interpreter to os.execl()."""
    with (
        patch("os.path.exists", return_value=True),
        patch("os.execl") as mock_execl,
    ):
        passenger_wsgi.load_environment(mock_virtualenv)
        assert mock_execl.call_args[0][0] == mock_interpreter_path


def test_load_environment_raises_value_error_with_no_path():
    """load_environment should raise a ValueError when no path is set."""
    with pytest.raises(ValueError) as exec_info:
        passenger_wsgi.load_environment()
    assert str(exec_info.value) == "Virtual Environment path must be set"


def test_load_environment_uses_envvar():
    """load_environment should use environment value as fallback."""
    os.environ["VENV_PATH"] = "test_path"
    with (
        patch("os.path.exists", return_value=True),
        patch("os.execl") as mock_execl,
    ):
        passenger_wsgi.load_environment()
        assert mock_execl.call_args[0][0] == os.path.join(
            "test_path", "bin", "python3"
        )


def test_load_environment_uses_arg_over_envvar(
    mock_virtualenv, mock_interpreter_path
):
    """load_environment should use argument value over environment value."""
    os.environ["VENV_PATH"] = "test_path"
    with (
        patch("os.path.exists", return_value=True),
        patch("os.execl") as mock_execl,
    ):
        passenger_wsgi.load_environment(mock_virtualenv)
        assert mock_execl.call_args[0][0] == mock_interpreter_path
