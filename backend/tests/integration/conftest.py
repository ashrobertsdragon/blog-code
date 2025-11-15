import pytest
from flask import Flask

from api.routes.health import health_bp


@pytest.fixture
def app(dev_settings):
    """Create Flask app with health blueprint for testing."""
    app = Flask(__name__)
    app.config["TESTING"] = True
    app.register_blueprint(health_bp)
    return app


@pytest.fixture
def client(app):
    """Create Flask test client."""
    return app.test_client()
