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
- **Task 4**: Initialized backend project structure with uv
  - Created complete DDD/Hexagonal Architecture directory structure
  - Set up Python 3.13.5+ requirement in pyproject.toml
  - Created domain, application, infrastructure, and api layers
  - Set up test directories (unit, integration, e2e)
  - Generated uv.lock file
  - Added placeholder files (main.py, config.py, schema.sql, passenger_wsgi.py)

### Infrastructure

- Established monorepo structure with backend/ and frontend/ directories
- Configured uv as Python package manager
- Set up pre-commit hooks for code quality enforcement
