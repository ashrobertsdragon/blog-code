"""Flask application factory.

This module contains the Flask app initialization and configuration,
including SPA routing, CORS handling, and blueprint registration.
"""

import logging
import os
from pathlib import Path
from urllib.parse import unquote

from flask import Flask, Response, jsonify, send_from_directory
from flask_cors import CORS

from backend.api.routes.health import health_bp
from backend.config import FlaskEnv

logger = logging.getLogger(__name__)


def create_app(config: dict | None = None) -> Flask:
    """Create and configure the Flask application.

    Args:
        config: Optional dictionary of configuration overrides.

    Returns:
        Configured Flask application instance.

    Raises:
        RuntimeError: If build directory is missing in production environment.
    """
    build_dir = Path(__file__).parent.parent.parent / "build"
    static_dir = build_dir / "static"

    app = Flask(
        __name__,
        static_folder=str(static_dir),
        static_url_path="/static",
        template_folder=str(build_dir),
    )

    app.config["TESTING"] = False

    if config:
        app.config.update(config)

    flask_env = os.environ.get("FLASK_ENV", FlaskEnv.PRODUCTION)

    if not build_dir.exists():
        if flask_env == FlaskEnv.PRODUCTION:
            raise RuntimeError(
                "Frontend build directory not found. Run 'npm run build' first."
            )
        logger.warning(
            "Frontend build directory not found. SPA routes will return 503."
        )

    if flask_env == FlaskEnv.DEVELOPMENT:
        CORS(app)

    app.register_blueprint(health_bp, url_prefix="")

    @app.route("/", defaults={"path": ""})
    @app.route("/<path:path>")
    def serve_spa(path: str) -> Response | tuple[Response, int]:
        r"""Serve React SPA for all non-API routes.

        Args:
            path: The requested URL path.

        Returns:
            - 400 with error JSON if path contains ".." or "\\"
            - 404 with error JSON if path starts with "api/"
            - 200 with file if path matches existing file in build_dir
            - 200 with index.html for SPA routes (default)
            - 503 with error JSON if index.html doesn't exist

        Raises:
            None (all exceptions handled internally)
        """
        decoded_path = unquote(unquote(path))
        if ".." in decoded_path or "\\" in decoded_path:
            logger.warning(f"Path traversal attempt blocked: {path}")
            return jsonify({"error": "Invalid path"}), 400

        if path.startswith("api/"):
            return jsonify({"error": "Not found"}), 404

        if path:
            file_path = build_dir / path
            try:
                if file_path.is_file():
                    return send_from_directory(str(build_dir), path)
            except (OSError, ValueError) as e:
                logger.debug(f"File access error for path '{path}': {e}")

        index_path = build_dir / "index.html"
        if not index_path.exists():
            return jsonify({"error": "Service unavailable"}), 503

        return send_from_directory(str(build_dir), "index.html")

    return app
