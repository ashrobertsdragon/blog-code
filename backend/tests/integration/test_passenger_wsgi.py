"""Integration tests for Passenger WSGI entry point.

Tests WSGI interface compliance for passenger_wsgi.py module.
This module must expose an 'application' variable that is a WSGI-compliant
Flask application instance.
"""

import sys
from pathlib import Path


def test_passenger_wsgi_imports_without_error():
    """passenger_wsgi module should be importable without errors."""
    try:
        import passenger_wsgi
    except ImportError as e:
        raise AssertionError(
            f"Failed to import passenger_wsgi module: {e}"
        ) from e

    assert passenger_wsgi is not None


def test_application_variable_exists():
    """passenger_wsgi module must expose 'application' variable for WSGI spec.

    WSGI servers like Passenger look for a module-level variable named
    'application', not 'app'. This is a WSGI specification requirement.
    """
    import passenger_wsgi

    assert hasattr(passenger_wsgi, "application"), (
        "passenger_wsgi module must expose 'application' variable"
    )


def test_application_is_flask_app():
    """application variable must be a Flask instance."""
    from flask import Flask

    import passenger_wsgi

    assert isinstance(passenger_wsgi.application, Flask), (
        "application must be a Flask instance"
    )


def test_application_is_callable():
    """application must be callable to satisfy WSGI spec.

    WSGI spec requires application to be a callable that accepts
    environ and start_response parameters.
    """
    import passenger_wsgi

    assert callable(passenger_wsgi.application), (
        "application must be callable per WSGI spec"
    )


def test_application_handles_basic_request():
    """application should handle basic HTTP requests through WSGI interface.

    Tests that the WSGI application can process a basic request using
    Flask's test client, which simulates WSGI environ/start_response.
    """
    import passenger_wsgi

    client = passenger_wsgi.application.test_client()
    response = client.get("/health")

    assert response.status_code in (
        200,
        503,
    ), "application should respond to health check"
    assert response.content_type == "application/json", (
        "application should return JSON responses"
    )


def test_health_endpoint_via_wsgi():
    """Health endpoint should be accessible through WSGI application.

    Verifies that blueprints are properly registered and routes work
    through the WSGI interface.
    """
    import passenger_wsgi

    client = passenger_wsgi.application.test_client()
    response = client.get("/health")

    assert response.status_code == 200, "health endpoint should return 200"
    assert response.json is not None, "health endpoint should return JSON"
    assert "status" in response.json, (
        "health endpoint should include status field"
    )


def test_sys_path_includes_src():
    """sys.path should include src/ directory for module imports.

    passenger_wsgi.py must add src/ to sys.path to allow imports like
    'from main import create_app' and 'from config import FlaskEnv'.
    """

    backend_dir = Path(__file__).parent.parent.parent
    src_dir = backend_dir / "src"
    src_path = str(src_dir.resolve())

    assert src_path in sys.path, (
        f"src/ directory ({src_path}) must be in sys.path"
    )
