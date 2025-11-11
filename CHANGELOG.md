# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Foundation Stage - Infrastructure Setup

- **Task 1**: Created git repository with .gitignore (Python, Flask, Node, React, SSH, VSCode templates)
- **Task 2**: Configured pre-commit hooks with Ruff, mypy, Biome, and general checks
- **Task 3**: Configured Biome for frontend linting and formatting
  - Created frontend/biome.json with React/JSX rules and a11y accessibility checks
  - Configured formatter with 2-space indentation and 100-character line width
  - Enabled hooks rules (useExhaustiveDependencies, useHookAtTopLevel, useJsxKeyInIterable)
  - Updated pre-commit hook to use explicit config path for Biome
- **Task 4**: Initialized backend project structure with uv
  - Created complete DDD/Hexagonal Architecture directory structure
  - Set up Python 3.13.5+ requirement in pyproject.toml
  - Created domain, application, infrastructure, and api layers
  - Set up test directories (unit, integration, e2e)
  - Generated uv.lock file
  - Added placeholder files (main.py, config.py, schema.sql, passenger_wsgi.py)
- **Task 5**: Configured Ruff for backend linting and formatting
  - Added [tool.ruff] configuration to backend/pyproject.toml
  - Set line-length to 80 characters, target-version to py313
  - Enabled lint rules: A (builtins), ANN (annotations), D (docstrings), DOC (docstrings), E (pycodestyle errors), F (pyflakes), I (isort), N (pep8-naming), UP (pyupgrade), W (pycodestyle warnings)
  - Configured flake8-annotations with allow-star-arg-any and mypy-init-return
  - Set pydocstyle convention to Google style with ignore-decorators for typing.overload
  - Added per-file-ignores for tests/docs/tools and **init**.py files
  - Verified uvx ruff check and uvx ruff format commands work correctly
- **Task 6**: Configured mypy for type checking
  - Added [tool.mypy] configuration to backend/pyproject.toml
  - Set python_version to "3.13" for Python 3.13 target compatibility
  - Enabled warn_return_any for strict return type checking
  - Enabled check_untyped_defs to require type hints on function definitions
  - Set ignore_missing_imports to allow third-party libraries without type stubs
  - Verified uv run mypy . runs successfully with no issues found in 16 source files
- **Task 8**: Created frontend CI workflow
  - Created .github/workflows/frontend-ci.yml with matrix strategy for Node 22.18 and 24.6
  - Configured triggers for push to main/foundation branches and pull requests to main
  - Added steps: checkout, setup Node.js with npm caching, install dependencies, lint, test, build
  - Uses actions/checkout@v3 and actions/setup-node@v3
  - Linting with Biome (npx biome check .)
  - Testing with coverage reporting (npm test -- --coverage --run)
  - Coverage threshold check placeholder (70% will be enforced when tests exist)
  - Production build step (npm run build)
  - All steps run in blog-code/frontend/ directory with fail-fast behavior

### Infrastructure

- Established monorepo structure with backend/ and frontend/ directories
- Configured uv as Python package manager
- Set up pre-commit hooks for code quality enforcement
