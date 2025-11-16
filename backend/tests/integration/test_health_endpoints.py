"""Integration tests for health check endpoints.

Tests health monitoring API endpoints for application and dependency health.
"""

from unittest.mock import MagicMock, patch

from requests.exceptions import RequestException
from sqlmodel import Session


def test_health_endpoint_returns_200(client):
    """GET /health should return 200 OK with healthy status."""
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json == {"status": "healthy"}


def test_health_endpoint_returns_json(client):
    """GET /health should return JSON content type."""
    response = client.get("/health")

    assert response.content_type == "application/json"


def test_health_db_success_returns_200(client, dev_settings):
    """GET /health/db should return 200 when database is reachable."""
    # Mock database session that successfully executes query
    mock_session = MagicMock(spec=Session)
    mock_session.exec.return_value = MagicMock()

    with patch("api.routes.health.get_db", return_value=iter([mock_session])):
        response = client.get("/health/db")

    assert response.status_code == 200
    assert response.json == {"status": "healthy", "database": "connected"}
    mock_session.exec.assert_called_once()


def test_health_db_failure_returns_503(client):
    """GET /health/db should return 503 when database is unreachable."""
    # Mock database session that raises an exception
    mock_session = MagicMock(spec=Session)
    mock_session.exec.side_effect = Exception("Connection refused")

    with patch("api.routes.health.get_db", return_value=iter([mock_session])):
        response = client.get("/health/db")

    assert response.status_code == 503
    assert response.json["status"] == "unhealthy"
    assert "database" in response.json
    assert response.json["database"] == "unreachable"


def test_health_db_returns_json(client, dev_settings):
    """GET /health/db should return JSON content type."""
    mock_session = MagicMock(spec=Session)
    mock_session.exec.return_value = MagicMock()

    with patch("api.routes.health.get_db", return_value=iter([mock_session])):
        response = client.get("/health/db")

    assert response.content_type == "application/json"


def test_health_github_success_returns_200(client):
    """GET /health/github should return 200 when GitHub API is reachable."""
    # Mock successful GitHub API response
    mock_response = MagicMock()
    mock_response.status_code = 200

    with patch("api.routes.health.requests.get") as mock_get:
        mock_get.return_value = mock_response
        response = client.get("/health/github")

    assert response.status_code == 200
    assert response.json == {"status": "healthy", "github": "reachable"}
    mock_get.assert_called_once_with(
        "https://api.github.com/rate_limit", timeout=5
    )


def test_health_github_failure_returns_503(client):
    """GET /health/github should return 503 when GitHub API is unreachable."""
    # Mock failed GitHub API request

    with patch("api.routes.health.requests.get") as mock_get:
        mock_get.side_effect = RequestException("Connection timeout")
        response = client.get("/health/github")

    assert response.status_code == 503
    assert response.json["status"] == "unhealthy"
    assert "github" in response.json
    assert response.json["github"] == "unreachable"


def test_health_github_non_200_response_returns_503(client):
    """GET /health/github returns 503 when GitHub API returns non-200."""
    # Mock GitHub API returning 500 Internal Server Error
    mock_response = MagicMock()
    mock_response.status_code = 500
    mock_response.raise_for_status.side_effect = RequestException(
        "500 Server Error"
    )

    with patch("api.routes.health.requests.get") as mock_get:
        mock_get.return_value = mock_response
        response = client.get("/health/github")

    assert response.status_code == 503
    assert response.json["status"] == "unhealthy"
    assert "github" in response.json
    assert response.json["github"] == "unreachable"


def test_health_github_returns_json(client):
    """GET /health/github should return JSON content type."""
    mock_response = MagicMock()
    mock_response.status_code = 200

    with patch("api.routes.health.requests.get") as mock_get:
        mock_get.return_value = mock_response
        response = client.get("/health/github")

    assert response.content_type == "application/json"


def test_health_github_uses_timeout(client):
    """GET /health/github should use reasonable timeout for external call."""
    mock_response = MagicMock()
    mock_response.status_code = 200

    with patch("api.routes.health.requests.get") as mock_get:
        mock_get.return_value = mock_response
        client.get("/health/github")

    # Verify timeout was passed to requests.get
    call_kwargs = mock_get.call_args[1]
    assert "timeout" in call_kwargs
    assert call_kwargs["timeout"] <= 10  # Reasonable timeout
