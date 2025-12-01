import os
from unittest.mock import patch

import pytest

from passenger_wsgi import (
    bootstrap_virtualenv,
    get_interpreter_path,
    should_bootstrap,
)


@pytest.fixture
def mock_interpreter_path() -> str:
    """Fixture providing a mock interpreter path."""
    return os.path.join(
        "home", "cpaneluser", "virtualenv", "blog", "bin", "python3"
    )


@pytest.fixture
def mock_virtualenv() -> str:
    """Fixture providing a mock virtual environment path."""
    return os.path.join("home", "cpaneluser", "virtualenv", "blog")


def test_get_interpreter_path_custom() -> None:
    """Test that get_interpreter_path returns the provided path."""
    custom_venv_path = "my-venv"
    interpreter_path = get_interpreter_path(custom_venv_path)
    assert interpreter_path == os.path.join(custom_venv_path, "bin", "python3")


def test_should_bootstrap_true(mock_interpreter_path) -> None:
    """Test that should_bootstrap is True when interpreter paths differ."""
    current_executable = "/usr/bin/python3"
    with patch("os.path.exists", return_value=True):
        assert should_bootstrap(mock_interpreter_path, current_executable)


def test_should_bootstrap_false(mock_interpreter_path) -> None:
    """Test that should_bootstrap is False when interpreter paths are same."""
    with patch("os.path.exists", return_value=True):
        assert not should_bootstrap(
            mock_interpreter_path, mock_interpreter_path
        )


def test_bootstrap_virtualenv(mock_interpreter_path):
    """Test that bootstrap_virtualenv re-executes the script."""
    with patch("sys.argv", ["test_script.py"]), patch("os.execl") as mock_execl:
        bootstrap_virtualenv(mock_interpreter_path)
        assert mock_execl.called
        assert mock_execl.call_args[0][0] == mock_interpreter_path
        assert mock_execl.call_args[0][1] == mock_interpreter_path
        assert mock_execl.call_args[0][2] == "test_script.py"


def test_get_interpreter_path_mock_virtualenv(mock_virtualenv):
    """Test that get_interpreter_path returns the correct interpreter path."""
    interpreter_path = get_interpreter_path(mock_virtualenv)
    assert interpreter_path == os.path.join(mock_virtualenv, "bin", "python3")
