"""Passenger WSGI entry point for cPanel deployment.

This module serves as the WSGI entry point for Passenger web server on cPanel
shared hosting. It handles virtual environment bootstrap and Flask application
initialization.

Environment Variables:
    VENV_PATH: Path to Python virtual environment (uv-managed).
               Defaults to /home/cpaneluser/virtualenv/blog if not set.

Deployment Notes:
    - Passenger requires the WSGI application object to be named 'application'
    - Dependencies must be synced: `uv sync`
    - This file should be placed in the application root directory
    - Passenger will execute this file to start the application

Usage:
    Passenger automatically loads this module when starting the application.
    No manual execution required in production.

References:
    - PEP 3333: Python Web Server Gateway Interface v1.0.1
    - Passenger documentation: https://www.phusionpassenger.com/
"""

import os
import sys

from backend.main import create_app


def get_interpreter_path(venv_path: str) -> str:
    """Get the path to the Python interpreter in the virtual environment.

    Args:
        venv_path: Path to virtual environment.

    Returns:
        Absolute path to the Python 3 interpreter.
    """
    return os.path.join(venv_path, "bin", "python3")


def should_bootstrap(interpreter_path: str, current_executable: str) -> bool:
    """Determine if virtual environment bootstrap is needed.

    Args:
        interpreter_path: Path to desired Python interpreter.
        current_executable: Path to currently running Python interpreter.

    Returns:
        True if bootstrap is needed (paths differ and target exists).
    """
    return current_executable != interpreter_path and os.path.exists(
        interpreter_path
    )


def bootstrap_virtualenv(interpreter_path: str) -> None:
    """Re-execute the script using the virtual environment Python.

    Args:
        interpreter_path: Path to the Python interpreter to use.
    """
    os.execl(interpreter_path, interpreter_path, *sys.argv)


def load_environment(path: str | None = None) -> None:
    """Load virtual environment."""
    venv_path = path or os.environ.get("VENV_PATH")
    if not venv_path:
        raise ValueError("Virtual Environment path must be set")
    interpreter = get_interpreter_path(venv_path)

    if should_bootstrap(interpreter, sys.executable):
        bootstrap_virtualenv(interpreter)


if not os.environ.get("FLASK_ENV") == "TESTING":
    load_environment()

application = create_app()
