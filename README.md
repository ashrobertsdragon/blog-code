# Flask + React Blog Platform

[![Backend CI](https://github.com/yourusername/blog2/workflows/Backend%20CI/badge.svg)](https://github.com/yourusername/blog2/actions)
[![Frontend CI](https://github.com/yourusername/blog2/workflows/Frontend%20CI/badge.svg)](https://github.com/yourusername/blog2/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A modern blog platform combining Domain-Driven Design principles with dual storage architecture. Draft posts live as version-controlled markdown files synced to GitHub, while published content is cached in PostgreSQL for performance.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Development](#development)
- [Testing](#testing)
- [Architecture](#architecture)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [CI/CD](#cicd)
- [Contributing](#contributing)

## Overview

### Key Features

- **Dual Storage Architecture**: Markdown drafts on filesystem + GitHub sync, published HTML in PostgreSQL
- **Domain-Driven Design**: 5 bounded contexts (Content, Version Control, Discussion, Notification, Identity)
- **Hexagonal Architecture**: Clean separation between domain logic and infrastructure
- **Real-time Version Control**: Every save commits to GitHub API for complete revision history
- **Test-Driven Development**: 80%+ coverage target with comprehensive test pyramid
- **Modern Stack**: Flask + React with TypeScript, Tailwind CSS, and Clerk authentication

### Tech Stack

| Layer               | Technology                   | Purpose                                |
| ------------------- | ---------------------------- | -------------------------------------- |
| **Frontend**        | React 18 + Vite              | UI framework and build tool            |
| **Styling**         | Tailwind CSS                 | Utility-first styling                  |
| **Backend**         | Flask 3.0+                   | REST API server                        |
| **Language**        | Python 3.13                  | Backend runtime                        |
| **Database**        | PostgreSQL                   | Persistent storage for published posts |
| **Storage**         | Filesystem + GitHub          | Draft markdown version control         |
| **Auth**            | Clerk                        | Authentication and user management     |
| **Email**           | Resend                       | Transactional emails                   |
| **Package Manager** | uv                           | Fast Python dependency resolver        |
| **Linting**         | Ruff + Biome                 | Code quality enforcement               |
| **Testing**         | pytest + Vitest + Playwright | Test automation                        |

## Quick Start

### Prerequisites

Ensure you have the following installed:

- **Python 3.13+** ([Download](https://www.python.org/downloads/))
- **Node.js 22.18+ or 24.6+** ([Download](https://nodejs.org/))
- **PostgreSQL 10.23+** (cPanel production uses 10.23; newer versions OK for local development) ([Download](https://www.postgresql.org/download/))
- **uv** (Python package manager): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Git** for version control

### 15-Minute Setup

#### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/blog2.git
cd blog2/monorepo
```

#### Step 2: Backend Setup

```bash
cd backend

# Install dependencies (uv automatically creates and manages virtual environment)
uv sync

# Create .env file manually using the template in Environment Variables section below
```

#### Step 3: Frontend Setup

```bash
cd ../frontend

# Install dependencies
npm install

# Create .env file manually using the template in Environment Variables section below
```

#### Step 4: Database Setup

```bash
# Create PostgreSQL database
createdb blog_dev

# Database migrations (not yet configured - will be added in authentication stage)
# cd ../backend
# uv run alembic upgrade head
```

#### Step 5: Health Check

Start both services and verify they're running:

```bash
# Terminal 1: Backend (from monorepo/backend)
uv run flask --app src.backend.main run --port 5000

# Terminal 2: Frontend (from monorepo/frontend)
npm run dev

# Terminal 3: Verify health checks
curl http://localhost:5000/api/health
# Expected: {"status": "healthy", "database": "connected", "github": "authenticated"}

curl http://localhost:5173
# Expected: React app loads in browser
```

You should see:

- Backend API running at `http://localhost:5000`
- Frontend dev server at `http://localhost:5173`
- Health check endpoints returning 200 OK

## Development

### Project Structure

```plaintext
monorepo/
├── backend/                      # Flask API (Python 3.13)
│   ├── src/
│   │   ├── passenger_wsgi.py    # Production WSGI entry
│   │   ├── scripts/             # Cron jobs (notifications, sync, cleanup)
│   │   └── backend/
│   │       ├── main.py          # Flask app factory
│   │       ├── config.py        # Environment configuration
│   │       ├── domain/          # Business logic (aggregates, value objects, events)
│   │       ├── application/     # Use cases (commands, queries, handlers)
│   │       ├── infrastructure/  # External adapters (DB, GitHub, email, auth)
│   │       └── api/             # HTTP layer (routes, middleware)
│   ├── tests/                   # Test suite (unit, integration, e2e)
│   ├── pyproject.toml           # uv project definition
│   └── uv.lock                  # Dependency lockfile
├── frontend/                     # React SPA (Node.js 22+)
│   ├── src/
│   │   ├── components/          # Reusable UI (post, comment, admin, common)
│   │   ├── pages/               # Route pages (Home, PostPage, AdminPage)
│   │   ├── hooks/               # Custom hooks (useAuth, usePostMutation)
│   │   ├── services/            # API clients (postService, commentService)
│   │   ├── context/             # React context (AuthContext)
│   │   ├── App.jsx              # Root component
│   │   └── main.jsx             # Vite entry point
│   ├── tests/                   # Vitest unit + Playwright e2e
│   ├── package.json             # npm dependencies
│   ├── vite.config.js           # Vite configuration
│   ├── biome.json               # Linter/formatter config
│   └── tailwind.config.js       # Tailwind CSS config
├── shared/
│   └── openapi.yaml             # API contract specification
├── .github/workflows/           # CI/CD (backend-ci.yml, frontend-ci.yml)
├── .pre-commit-config.yaml      # Pre-commit hooks
└── README.md                    # This file
```

### Environment Variables

#### Backend (.env)

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/blog_dev

# GitHub API (for draft sync)
GITHUB_TOKEN=your_github_personal_access_token
GITHUB_REPO_OWNER=yourusername
GITHUB_REPO_NAME=blog-drafts

# Resend (email notifications)
RESEND_API_KEY=re_your_resend_api_key
NOTIFICATION_FROM_EMAIL=notifications@yourdomain.com

# Clerk (authentication)
CLERK_SECRET_KEY=sk_test_your_clerk_secret_key

# Flask
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=your_secret_key_for_sessions
```

#### Frontend (.env)

```bash
# API Configuration
VITE_API_BASE_URL=http://localhost:5000

# Clerk (authentication)
VITE_CLERK_PUBLISHABLE_KEY=pk_test_your_clerk_publishable_key
```

### Common Development Commands

#### Backend (Python + uv)

```bash
cd backend

# Dependency management
uv add package-name              # Add production dependency
uv add --dev package-name        # Add development dependency
uv remove package-name           # Remove dependency
uv sync                          # Install/update all dependencies from lockfile

# Run Flask development server
uv run flask --app src.backend.main run --port 5000

# Run background jobs (cron scripts)
uv run python scripts/process_notifications.py
uv run python scripts/sync_repo_changes.py
uv run python scripts/cleanup_revisions.py

# Code quality
uvx ruff check --fix .           # Lint and auto-fix
uvx ruff format .                # Format code
uv run mypy src/                 # Type checking with mypy
uvx ty check                     # Type checking with ty (faster alternative)

# Database migrations
uv run alembic revision --autogenerate -m "description"
uv run alembic upgrade head
uv run alembic downgrade -1
```

**CRITICAL**: Always use `uv run` to execute Python commands. Never use `pip`, `uv pip`, or manually activate virtual environments. The `uv run` command automatically manages the virtual environment for you.

#### Frontend (React + Vite)

```bash
cd frontend

# Development
npm run dev                      # Start dev server (http://localhost:5173)
npm run build                    # Production build
npm run preview                  # Preview production build

# Code quality (Biome does both linting and formatting)
biome check --write              # Lint and format in one step
biome check                      # Check only (no fixes)

# Package management
npm install package-name         # Add dependency
npm install -D package-name      # Add dev dependency
npm uninstall package-name       # Remove dependency
```

## Testing

### Test Pyramid

The project follows a testing pyramid with higher coverage in unit tests and lower in e2e tests:

```text
         /\
        /e2e\        10% - Full user workflows (Playwright)
       /------\
      /  int.  \     30% - API + DB integration (pytest/Vitest)
     /----------\
    /    unit    \   60% - Domain logic + components (pytest/Vitest)
   /--------------\
```

### Coverage Targets

| Layer                              | Target | Tools  |
| ---------------------------------- | ------ | ------ |
| Domain (aggregates, value objects) | 90%+   | pytest |
| Application (commands, queries)    | 85%+   | pytest |
| Infrastructure (repos, services)   | 70%+   | pytest |
| API (routes, middleware)           | 80%+   | pytest |
| Frontend (components, hooks)       | 70%+   | Vitest |

### Backend Testing

```bash
cd backend

# Run all tests
uv run pytest

# Run by test type
uv run pytest tests/unit                    # Unit tests only
uv run pytest tests/integration             # Integration tests
uv run pytest tests/e2e                     # End-to-end tests

# Run specific test file or function
uv run pytest tests/unit/test_post.py
uv run pytest tests/unit/test_post.py::test_draft_created_with_valid_slug

# Coverage report
uv run pytest --cov=src/backend --cov-report=html
# Open htmlcov/index.html in browser

# Watch mode (auto-rerun on file changes)
uv run pytest-watch

# Verbose output
uv run pytest -v
```

### Frontend Testing

```bash
cd frontend

# Run all tests
npm test                         # Vitest unit tests
npm run test:watch               # Watch mode
npm run test:ui                  # Vitest UI (browser-based)
npm run test:coverage            # Coverage report

# Run Playwright e2e tests
npm run test:e2e                 # Headless mode
npm run test:e2e:ui              # Interactive UI mode
npm run test:e2e:debug           # Debug mode with browser
```

### Pre-commit Hooks

The project uses pre-commit hooks to enforce code quality before commits. Hooks automatically run on `git commit` and will block commits if checks fail.

**Installed hooks:**

- **Python**: Ruff linting/formatting, mypy type checking
- **JavaScript/TypeScript**: Biome linting/formatting
- **General**: Trailing whitespace removal, YAML validation, merge conflict detection

**Setup:**

```bash
# Install pre-commit (one-time setup)
pip install pre-commit
pre-commit install

# Manual run (tests all files)
pre-commit run --all-files

# Skip hooks (emergency only - NOT recommended)
git commit --no-verify
```

**Common hook failures:**

| Error                 | Fix                                    |
| --------------------- | -------------------------------------- |
| `Ruff format failed`  | Run `uvx ruff format .` in backend/    |
| `Biome check failed`  | Run `biome check --write` in frontend/ |
| `mypy type errors`    | Fix type annotations in flagged files  |
| `Trailing whitespace` | Auto-fixed by hook, re-stage files     |

## Architecture

### Domain-Driven Design

The system is organized into 5 bounded contexts, each with clear boundaries and responsibilities:

1. **Content Management** - Draft creation, markdown processing, publishing
1. **Version Control** - GitHub integration, revision tracking, revert operations
1. **Discussion** - Flat comment structure with @mentions for replies
1. **Notification** - Email queue with retry logic via Resend
1. **Identity & Access** - User management via Clerk, role-based authorization

### Hexagonal Architecture

The codebase follows hexagonal (ports and adapters) architecture:

```text
┌─────────────────────────────────────────────────┐
│              API Layer (HTTP)                   │
│         Flask Routes + Middleware               │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│         Application Layer (Use Cases)           │
│    Commands, Queries, Handlers                  │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│          Domain Layer (Business Logic)          │
│  Aggregates, Value Objects, Domain Events       │
│         NO external dependencies                 │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│      Infrastructure Layer (Adapters)            │
│  Database, GitHub API, Email, Filesystem        │
└─────────────────────────────────────────────────┘
```

**Key principles:**

- **Domain layer has NO external dependencies** - Pure business logic
- **Infrastructure adapters implement domain interfaces** - Dependency inversion
- **Application layer orchestrates use cases** - Coordinates domain and infrastructure
- **API layer translates HTTP to domain commands** - Presentation concern

For detailed architecture documentation, see [docs/architecture.md](docs/architecture.md) *(planned)*.

## Deployment

### Quick Deployment to cPanel

Deployment script is planned for future implementation. See [docs/deployment.md](docs/deployment.md) *(planned)* for manual deployment steps.

### Cron Jobs

Background tasks run on cPanel via cron:

| Schedule      | Script                     | Purpose                                 |
| ------------- | -------------------------- | --------------------------------------- |
| `* * * * *`   | `process_notifications.py` | Send queued emails every minute         |
| `*/5 * * * *` | `sync_repo_changes.py`     | Sync GitHub changes every 5 minutes     |
| `0 3 * * 0`   | `cleanup_revisions.py`     | Clean old revisions weekly (Sunday 3am) |

### Production Environment

**PostgreSQL Database:**

- Create via cPanel PostgreSQL manager
- Configure `DATABASE_URL` in `.env`

**Environment Variables:**
Set via SSH or cPanel terminal:

```bash
# Set in ~/.bashrc or cPanel environment manager
export DATABASE_URL=postgresql://user:pass@host/dbname
export GITHUB_TOKEN=ghp_your_token
export RESEND_API_KEY=re_your_key
export CLERK_SECRET_KEY=sk_live_your_key
```

**Health Checks:**

After deployment, verify:

```bash
curl https://yourdomain.com/api/health
# Expected: {"status": "healthy", "database": "connected", "github": "authenticated"}
```

For detailed deployment instructions, see [docs/deployment.md](docs/deployment.md) *(planned)*.

## Troubleshooting

### Common Issues

| Problem                                           | Cause                          | Solution                                                                                              |
| ------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `ModuleNotFoundError` when running Python scripts | Not using `uv run`             | Always prefix commands with `uv run` (e.g., `uv run pytest`)                                          |
| `uv pip` command blocked by pre-commit hook       | Direct pip usage not allowed   | Use `uv add package-name` instead of `uv pip install`                                                 |
| PostgreSQL connection refused                     | Database not running           | Start PostgreSQL: `sudo service postgresql start` (Linux) or `brew services start postgresql` (macOS) |
| `GITHUB_TOKEN` authentication failed              | Invalid or expired token       | Generate new PAT at github.com/settings/tokens with `repo` scope                                      |
| Frontend 404 on API calls                         | Backend not running            | Start Flask: `cd backend && uv run flask run`                                                         |
| `CORS error` in browser console                   | Missing CORS configuration     | Ensure `CORS(app)` is configured in `backend/src/backend/main.py`                                     |
| Clerk authentication fails                        | Wrong publishable key          | Verify `VITE_CLERK_PUBLISHABLE_KEY` matches Clerk dashboard                                           |
| Pre-commit hooks fail on commit                   | Code quality issues            | Run `uvx ruff format .` and `biome check --write`, then re-commit                                     |
| Tests fail with database errors                   | Test database not created      | Create test DB: `createdb blog_test` and set `TEST_DATABASE_URL` in `.env`                            |
| `alembic revision` creates empty migration        | Models not imported            | Import all models in `backend/src/backend/infrastructure/persistence/models.py`                       |
| Vite build fails with memory error                | Insufficient Node memory       | Increase limit: `NODE_OPTIONS=--max_old_space_size=4096 npm run build`                                |
| Email notifications not sending                   | Resend API key invalid         | Verify key at resend.com/api-keys and update `RESEND_API_KEY`                                         |
| GitHub sync script fails with 403                 | Rate limit exceeded            | Check `X-RateLimit-Remaining` header, implement backoff in code                                       |
| SSH deployment fails with key error               | Wrong key permissions          | Run `chmod 600 ~/.ssh/id_rsa` (Linux) or use `linuxify_ssh_key.sh` (WSL/Git Bash)                     |
| Passenger WSGI not restarting                     | passenger_wsgi.py syntax error | Check logs at `~/logs/passenger.log` on cPanel                                                        |

### Debug Mode

**Backend debugging:**

```bash
# Enable Flask debug mode
export FLASK_DEBUG=1
uv run flask run

# Enable verbose logging
export LOG_LEVEL=DEBUG
```

**Frontend debugging:**

```bash
# Enable React dev tools
npm run dev

# Open browser console and check Network tab for API calls
```

### Logs

**Backend logs:**

```bash
# Flask development server logs (stdout)
uv run flask run

# Production logs on cPanel
ssh user@host
tail -f ~/logs/passenger.log
```

**Frontend logs:**

```bash
# Browser console (F12 in Chrome/Firefox)
# Vite dev server logs (stdout)
npm run dev
```

## CI/CD

### GitHub Actions Workflows

Two workflows run automatically on push and pull requests to `main`:

#### Backend CI (`backend-ci.yml`)

- **Python version:** 3.13
- **Steps:**
  1. Install uv and sync dependencies
  1. Run Ruff linting and formatting checks
  1. Run mypy type checking
  1. Run pytest with coverage (must be 80%+)
  1. Upload coverage report to Codecov
  1. Build backend artifacts

#### Frontend CI (`frontend-ci.yml`)

- **Node versions:** 22.18, 24.6 (matrix)
- **Steps:**
  1. Install npm dependencies
  1. Run Biome linting and formatting checks
  1. Run Vitest tests with coverage (must be 70%+)
  1. Run Playwright e2e tests
  1. Upload test artifacts and coverage
  1. Build production bundle

**Branch protection:**

Both CI workflows must pass before merging to `main`. Configure in GitHub repository settings under `Branches > Branch protection rules`.

### Pre-deployment Checklist

Before deploying to production:

- [ ] All CI checks pass (green checkmarks on GitHub)
- [ ] Coverage targets met (80% backend, 70% frontend)
- [ ] Manual smoke test on staging environment
- [ ] Database migrations tested
- [ ] Environment variables configured on production
- [ ] Backup current production database
- [ ] Monitor logs for 1 hour post-deployment

## Contributing

### Development Workflow

1. **Create feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

1. **Write failing tests (TDD)**

   ```bash
   # Backend
   cd backend && uv run pytest tests/unit/test_new_feature.py

   # Frontend
   cd frontend && npm test -- tests/NewComponent.test.jsx
   ```

1. **Implement feature**

   - Follow existing patterns in codebase
   - Keep domain logic in `domain/` layer
   - Infrastructure concerns in `infrastructure/`

1. **Ensure tests pass**

   ```bash
   uv run pytest          # Backend
   npm test               # Frontend
   ```

1. **Run quality checks**

   ```bash
   uvx ruff check --fix . # Backend lint
   biome check --write    # Frontend lint/format
   uv run mypy src/       # Type checking
   ```

1. **Commit with conventional commits format**

   ```bash
   git add .
   git commit -m "feat: add post revision comparison API"
   ```

1. **Push and create PR**

   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code restructuring (no behavior change)
- `test`: Add or modify tests
- `chore`: Build process or auxiliary tool changes

**Examples:**

```text
feat(comments): add reply functionality with @mentions
fix(auth): resolve Clerk session timeout issue
docs(readme): update deployment instructions
test(posts): add integration tests for publish workflow
```

### Code Review Guidelines

PRs must meet these criteria before merging:

- [ ] All CI checks pass (backend-ci and frontend-ci)
- [ ] Coverage targets met (no decrease in coverage)
- [ ] Pre-commit hooks pass
- [ ] At least one approving review
- [ ] No merge conflicts with `main`
- [ ] Conventional commit message format
- [ ] Tests added for new functionality
- [ ] Documentation updated if API changes

## Resources & Links

### Documentation

- [Architecture Guide](docs/architecture.md) *(planned)* - Detailed system design and patterns
- [Deployment Guide](docs/deployment.md) *(planned)* - Production deployment instructions
- [API Reference](docs/api.md) *(planned)* - REST API endpoints documentation
- [cPanel Deployment Patterns](../cpanel-deployment-patterns.md) - Research on cPanel strategies

### External Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [React Documentation](https://react.dev/)
- [uv Documentation](https://docs.astral.sh/uv/)
- [Clerk Authentication](https://clerk.com/docs)
- [Resend Email API](https://resend.com/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)

### Development Tools

- [Ruff](https://docs.astral.sh/ruff/) - Python linter and formatter
- [Biome](https://biomejs.dev/) - JavaScript/TypeScript linter and formatter
- [pytest](https://docs.pytest.org/) - Python testing framework
- [Vitest](https://vitest.dev/) - Vite-native test framework
- [Playwright](https://playwright.dev/) - End-to-end testing

### Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/blog2/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/blog2/discussions)
- **Email:** <support@yourdomain.com>

---

**License:** MIT

**Maintainers:** Your Team Name

**Last Updated:** 2025-12-21
