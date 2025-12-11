# Deployment Functions Test Suite - Stage 6 (Red Phase)

## Overview

Created comprehensive BATS test suite for all 6 deployment functions following TDD methodology. Tests are written BEFORE implementation to define expected behavior.

## Test Files Created

### 1. test_provision_db.bats (32 tests)

Tests for `scripts/functions/provision_database.sh`

**Coverage:**

- Database existence checking (idempotent)
- Database creation only when missing
- User existence checking (idempotent)
- User creation only when missing
- Privilege granting (idempotent)
- DRY_RUN mode support
- Environment variable validation
- Error handling and logging
- Password security (not logged)
- Execution order verification

### 2. test_upload_code.bats (48 tests)

Tests for `scripts/functions/upload_code.sh`

**Coverage:**

- Frontend build execution
- Build directory validation
- Backend upload via rsync
- Frontend upload via rsync
- SSH key linuxification (OS detection)
- Correct rsync flags (archive, verbose, compress)
- Exclusion patterns (node_modules, .git, **pycache**)
- DRY_RUN mode support
- Build failure handling
- Rsync failure handling
- SSH connection parameters
- Path handling (including spaces)
- Execution order (build before upload)

### 3. test_setup_venv.bats (44 tests)

Tests for `scripts/functions/setup_venv.sh`

**Coverage:**

- Virtualenv existence checking (idempotent)
- Virtualenv creation only when missing
- uv installation checking (idempotent)
- uv installation via pip only when missing
- Dependency sync with uv sync (idempotent)
- DRY_RUN mode support
- Remote SSH execution
- Environment variable validation
- Error handling for each operation
- Execution order (venv -> uv -> sync)
- Python3 venv module usage
- Virtualenv activation before operations

### 4. test_run_schema.bats (43 tests)

Tests for `scripts/functions/run_schema.sh`

**Coverage:**

- Database initialization script execution
- Database connection parameter usage
- SQLModel create_all idempotency
- DRY_RUN mode support
- Environment variable validation
- PostgreSQL connection string construction
- Password security (not logged)
- Remote SSH execution
- uv run for script execution
- Virtualenv activation
- Error handling (connection, schema)
- Default values (DB_HOST, DB_PORT)
- Table creation idempotency

### 5. test_register_passenger.bats (53 tests)

Tests for `scripts/functions/register_passenger.sh`

**Coverage:**

- Passenger app existence checking
- New app registration only when missing
- Existing app restart instead of registration
- Environment variable injection (all CPANEL\_\*)
- Domain and base_uri usage
- App path configuration
- DRY_RUN mode support
- UAPI function calls (register, restart)
- Error handling (registration, restart)
- Password security (not logged)
- Idempotency (repeated calls)
- Python application type
- Execution order (check before register/restart)

### 6. test_verify.bats (62 tests)

Tests for `scripts/functions/verify_deployment.sh`

**Coverage:**

- Health endpoint HTTP checking
- Retry logic (configurable attempts)
- HTTP status validation (200 OK)
- Response content validation
- DRY_RUN mode (skips actual check)
- Timeout handling
- Non-200 response handling
- URL construction (domain + base_uri + endpoint)
- HTTPS by default
- curl usage with proper flags
- Environment variable validation
- Default values (endpoint, retries, timeout)
- Retry delay between attempts
- Error types (timeout, connection refused, DNS)
- JSON response validation
- Follow redirects
- Success/failure logging

## Test Statistics

**Total Tests Created:** 242 tests across 6 files

**Test Distribution:**

- test_provision_db.bats: 32 tests (13%)
- test_upload_code.bats: 48 tests (20%)
- test_setup_venv.bats: 44 tests (18%)
- test_run_schema.bats: 43 tests (18%)
- test_register_passenger.bats: 53 tests (22%)
- test_verify.bats: 62 tests (26%)

## Testing Patterns Used

### 1. Idempotency Testing

All deployment functions are tested for idempotent behavior - safe to run multiple times:

```bash
run provision_database
assert_success

run provision_database  # Second call should also succeed
assert_success
```

### 2. DRY_RUN Mode Testing

Every function supports dry-run mode for safe testing:

```bash
export DRY_RUN=1
run upload_code
assert_success

run cat "${TEST_LOG_FILE}"
assert_output --partial "[DRY-RUN]"
```

### 3. Error Handling Testing

All failure scenarios are tested:

```bash
export MOCK_RSYNC_FAILURE=1
run upload_code
assert_failure

run cat "${TEST_LOG_FILE}"
assert_output --partial "ERROR"
```

### 4. Security Testing

Password values are never logged:

```bash
export CPANEL_POSTGRES_PASSWORD="SuperSecret123!"
provision_database

run cat "${TEST_LOG_FILE}"
refute_output --partial "SuperSecret123!"
```

### 5. Execution Order Testing

Operations happen in correct sequence:

```bash
provision_database

local db_line user_line
db_line=$(grep -n "database" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)
user_line=$(grep -n "user" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)

[[ "${db_line}" -lt "${user_line}" ]]
```

## Dependencies

All test files properly source required dependencies:

- `logger.sh` - Logging functions
- `uapi.sh` - cPanel UAPI operations
- `validators.sh` - Validation and dry-run helpers
- `test_helpers.bash` - Testing utilities

## Mocking Strategy

Tests use environment variables to mock external dependencies:

- `MOCK_HTTP_SUCCESS=1` - Mock successful HTTP response
- `MOCK_VENV_MISSING=1` - Mock missing virtualenv
- `MOCK_UV_MISSING=1` - Mock missing uv installation
- `UAPI_MOCK_ENABLED=1` - Enable UAPI mocking
- `SSH_MOCK_ENABLED=1` - Enable SSH mocking

## Current Status: RED PHASE

All tests currently FAIL because implementation files do not exist:

```text
❌ scripts/functions/provision_database.sh - NOT IMPLEMENTED
❌ scripts/functions/upload_code.sh - NOT IMPLEMENTED
❌ scripts/functions/setup_venv.sh - NOT IMPLEMENTED
❌ scripts/functions/run_schema.sh - NOT IMPLEMENTED
❌ scripts/functions/register_passenger.sh - NOT IMPLEMENTED
❌ scripts/functions/verify_deployment.sh - NOT IMPLEMENTED
```

## Next Steps (Stage 7)

Implementation agent will create all 6 deployment function scripts to make tests pass (GREEN phase).

Expected implementation order:

1. provision_database.sh
1. upload_code.sh
1. setup_venv.sh
1. run_schema.sh
1. register_passenger.sh
1. verify_deployment.sh

## Test Execution

Run all deployment tests:

```bash
cd monorepo
bats tests/test_provision_db.bats
bats tests/test_upload_code.bats
bats tests/test_setup_venv.bats
bats tests/test_run_schema.bats
bats tests/test_register_passenger.bats
bats tests/test_verify.bats
```

Run all tests together:

```bash
bats tests/test_provision_db.bats tests/test_upload_code.bats tests/test_setup_venv.bats tests/test_run_schema.bats tests/test_register_passenger.bats tests/test_verify.bats
```

## File Locations

```text
monorepo/
├── tests/
│   ├── test_provision_db.bats (new)
│   ├── test_upload_code.bats (new)
│   ├── test_setup_venv.bats (new)
│   ├── test_run_schema.bats (new)
│   ├── test_register_passenger.bats (new)
│   └── test_verify.bats (new)
└── scripts/
    └── functions/ (to be created in Stage 7)
        ├── provision_database.sh (not yet implemented)
        ├── upload_code.sh (not yet implemented)
        ├── setup_venv.sh (not yet implemented)
        ├── run_schema.sh (not yet implemented)
        ├── register_passenger.sh (not yet implemented)
        └── verify_deployment.sh (not yet implemented)
```
