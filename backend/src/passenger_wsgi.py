"""Passenger WSGI entry point for cPanel deployment.

This module serves as the WSGI entry point for Passenger web server on cPanel
shared hosting. It handles virtual environment bootstrap and Flask application
initialization.

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

INTERP = os.path.join(
    os.environ.get("VIRTUAL_ENV", "/home/cpaneluser/virtualenv/blog"),
    "bin",
    "python3",
)

if sys.executable != INTERP and os.path.exists(INTERP):
    os.execl(INTERP, INTERP, *sys.argv)

from main import create_app  # noqa: E402

application = create_app()
