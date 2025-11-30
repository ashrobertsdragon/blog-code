"""Passenger WSGI entry point for cPanel deployment.

This module serves as the WSGI entry point for Passenger web server on cPanel
shared hosting. It handles virtual environment bootstrap, path configuration,
and Flask application initialization.

Environment Variables:
    VIRTUAL_ENV: Path to Python virtual environment (uv-managed).
                 Defaults to /home/cpaneluser/virtualenv/blog if not set.

Deployment Notes:
    - Passenger requires the WSGI application object to be named 'application'
    - Virtual environment must be created with uv: `uv venv`
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

# Virtual environment bootstrap
# Passenger may start with system Python, so we need to re-exec with venv Python
# Only perform bootstrap on Linux/production (not Windows development)
INTERP = os.path.join(
    os.environ.get("VIRTUAL_ENV", "/home/cpaneluser/virtualenv/blog"),
    "bin",
    "python3",
)

if sys.executable != INTERP and os.path.exists(INTERP):
    os.execl(INTERP, INTERP, *sys.argv)

# Path configuration
# Add application root and src/ directory to Python path for imports
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

# Application bootstrap
try:
    from main import create_app  # type: ignore[import-not-found]

    application = create_app()
except ImportError as e:
    sys.stderr.write(f"Failed to import Flask app: {e}\n")
    sys.stderr.write("Ensure dependencies are installed: uv sync\n")
    sys.stderr.write(f"Python path: {sys.path}\n")
    sys.stderr.write(f"Working directory: {os.getcwd()}\n")
    raise
except Exception as e:
    sys.stderr.write(f"Failed to create Flask application: {e}\n")
    sys.stderr.write(
        "Check application configuration and environment variables\n"
    )
    raise
