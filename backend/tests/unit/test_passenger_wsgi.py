"""Unit tests for Passenger WSGI entry point.

Tests the virtualenv bootstrap logic and application creation with mocking.
"""

import sys
from unittest.mock import MagicMock, patch


def test_interp_path_construction_with_virtual_env():
    """INTERP path should use VIRTUAL_ENV when set."""
    with patch.dict("os.environ", {"VIRTUAL_ENV": "/custom/venv"}):
        with patch("os.path.exists", return_value=False):
            with patch("sys.executable", "/usr/bin/python3"):
                import importlib

                import passenger_wsgi

                importlib.reload(passenger_wsgi)
                expected = "/custom/venv/bin/python3"
                assert passenger_wsgi.INTERP == expected


def test_interp_path_construction_without_virtual_env():
    """INTERP path should use default when VIRTUAL_ENV not set."""
    with patch.dict("os.environ", {}, clear=True):
        with patch("os.path.exists", return_value=False):
            with patch("sys.executable", "/usr/bin/python3"):
                import importlib

                import passenger_wsgi

                importlib.reload(passenger_wsgi)
                expected = "/home/cpaneluser/virtualenv/blog/bin/python3"
                assert passenger_wsgi.INTERP == expected


def test_os_execl_called_when_interpreter_differs():
    """os.execl should be called when sys.executable != INTERP."""
    mock_execl = MagicMock()
    with patch.dict("os.environ", {"VIRTUAL_ENV": "/test/venv"}):
        with patch("os.path.exists", return_value=True):
            with patch("sys.executable", "/usr/bin/python3"):
                with patch("os.execl", mock_execl):
                    import importlib

                    import passenger_wsgi

                    importlib.reload(passenger_wsgi)
                    expected_interp = "/test/venv/bin/python3"
                    mock_execl.assert_called_once_with(
                        expected_interp, expected_interp, *sys.argv
                    )


def test_os_execl_not_called_when_interpreter_matches():
    """os.execl should not be called when sys.executable == INTERP."""
    mock_execl = MagicMock()
    interp = "/test/venv/bin/python3"
    with patch.dict("os.environ", {"VIRTUAL_ENV": "/test/venv"}):
        with patch("os.path.exists", return_value=True):
            with patch("sys.executable", interp):
                with patch("os.execl", mock_execl):
                    import importlib

                    import passenger_wsgi

                    importlib.reload(passenger_wsgi)
                    mock_execl.assert_not_called()


def test_os_execl_not_called_when_interp_does_not_exist():
    """os.execl should not be called when INTERP path doesn't exist."""
    mock_execl = MagicMock()
    with patch.dict("os.environ", {"VIRTUAL_ENV": "/nonexistent/venv"}):
        with patch("os.path.exists", return_value=False):
            with patch("sys.executable", "/usr/bin/python3"):
                with patch("os.execl", mock_execl):
                    import importlib

                    import passenger_wsgi

                    importlib.reload(passenger_wsgi)
                    mock_execl.assert_not_called()


def test_application_is_created():
    """Application should be created from create_app factory."""
    with patch("os.path.exists", return_value=False):
        with patch("sys.executable", "/usr/bin/python3"):
            import passenger_wsgi

            assert hasattr(passenger_wsgi, "application")
            assert passenger_wsgi.application is not None


def test_application_is_flask_instance():
    """Application should be a Flask instance."""
    from flask import Flask

    with patch("os.path.exists", return_value=False):
        with patch("sys.executable", "/usr/bin/python3"):
            import passenger_wsgi

            assert isinstance(passenger_wsgi.application, Flask)
