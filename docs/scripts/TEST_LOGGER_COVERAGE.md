# Logger Module Test Coverage

## Overview

This document describes the comprehensive test coverage for the logger module (`scripts/logger.sh`).

**Total Tests:** 53
**Current Status:** All tests FAIL (Red phase - no implementation yet)
**Test File:** `tests/test_logger.bats`

## Test Categories

### 1. Basic Functionality (7 tests)

Tests that verify the logger script can be loaded and exposes the required functions.

- **logger: script exists and is executable** - Verifies logger.sh file exists and has execute permissions
- **logger: can be sourced without errors** - Ensures the script can be sourced into other scripts
- **logger: log_debug function exists after sourcing** - Confirms log_debug() function is available
- **logger: log_info function exists after sourcing** - Confirms log_info() function is available
- **logger: log_warning function exists after sourcing** - Confirms log_warning() function is available
- **logger: log_error function exists after sourcing** - Confirms log_error() function is available
- **logger: log_section function exists after sourcing** - Confirms log_section() function is available

### 2. Log Levels - DEBUG (6 tests)

Tests for DEBUG level logging functionality.

- **logger: log_debug writes to console** - Verifies DEBUG messages appear on stdout
- **logger: log_debug includes timestamp in output** - Ensures ISO 8601 timestamp is present
- **logger: log_debug creates log file if it doesn't exist** - Tests automatic log file creation
- **logger: log_debug writes to log file** - Verifies messages are persisted to file
- **logger: log_debug file output has no color codes** - Ensures clean log file (no ANSI codes)
- **logger: log_debug console output has gray color codes** - Verifies DEBUG uses gray/dimmed colors

### 3. Log Levels - INFO (4 tests)

Tests for INFO level logging functionality.

- **logger: log_info writes to console** - Verifies INFO messages appear on stdout
- **logger: log_info includes timestamp in output** - Ensures ISO 8601 timestamp is present
- **logger: log_info writes to log file** - Verifies messages are persisted to file
- **logger: log_info file output has no color codes** - Ensures clean log file (no ANSI codes)

### 4. Log Levels - WARNING (5 tests)

Tests for WARNING level logging functionality.

- **logger: log_warning writes to console** - Verifies WARNING messages appear on stdout
- **logger: log_warning includes timestamp in output** - Ensures ISO 8601 timestamp is present
- **logger: log_warning writes to log file** - Verifies messages are persisted to file
- **logger: log_warning console output has yellow color codes** - Verifies WARNING uses yellow color
- **logger: log_warning file output has no color codes** - Ensures clean log file (no ANSI codes)

### 5. Log Levels - ERROR (5 tests)

Tests for ERROR level logging functionality.

- **logger: log_error writes to console** - Verifies ERROR messages appear on stdout
- **logger: log_error includes timestamp in output** - Ensures ISO 8601 timestamp is present
- **logger: log_error writes to log file** - Verifies messages are persisted to file
- **logger: log_error console output has red color codes** - Verifies ERROR uses red color
- **logger: log_error file output has no color codes** - Ensures clean log file (no ANSI codes)

### 6. Section Headers (4 tests)

Tests for the section header functionality used to mark deployment steps.

- **logger: log_section writes section header to console** - Verifies section headers appear on stdout
- **logger: log_section has visual distinction from regular logs** - Tests visual separators (lines/borders)
- **logger: log_section writes to log file** - Verifies sections are persisted to file
- **logger: log_section includes timestamp** - Ensures ISO 8601 timestamp is present

### 7. File Operations (4 tests)

Tests for log file handling and management.

- **logger: multiple log entries append to same file** - Verifies messages don't overwrite each other
- **logger: log entries maintain order in file** - Tests sequential ordering of log entries
- **logger: creates log directory if it doesn't exist** - Tests automatic directory creation
- **logger: preserves existing log file content** - Ensures new logs don't delete old content

### 8. Message Handling (3 tests)

Tests for special message formats and edge cases.

- **logger: handles messages with special characters** - Tests shell special chars ($, @, #, !)
- **logger: handles multiline messages** - Verifies multi-line log entry support
- **logger: handles very long messages without truncation** - Tests 1000+ character messages

### 9. DRY_RUN Mode (3 tests)

Tests for dry-run mode behavior when DRY_RUN=1 is set.

- **logger: DRY_RUN mode indicates dry-run in log output** - Verifies [DRY-RUN] indicator
- **logger: DRY_RUN mode still writes to console** - Ensures logs still appear in dry-run
- **logger: DRY_RUN mode still writes to log file** - Ensures logs are still persisted in dry-run

### 10. Formatting & Display (2 tests)

Tests for consistent formatting across log levels.

- **logger: different log levels have distinct formatting** - Verifies each level looks different
- **logger: timestamp format is ISO 8601 compliant** - Tests YYYY-MM-DDTHH:MM:SS format

### 11. Edge Cases (4 tests)

Tests for boundary conditions and edge cases.

- **logger: log_debug accepts empty message** - Tests empty string handling for DEBUG
- **logger: log_info accepts empty message** - Tests empty string handling for INFO
- **logger: log_warning accepts empty message** - Tests empty string handling for WARNING
- **logger: log_error accepts empty message** - Tests empty string handling for ERROR

### 12. File Permissions & Concurrency (2 tests)

Tests for file system permissions and concurrent access.

- **logger: log file is created with appropriate permissions** - Verifies readable/writable file
- **logger: handles concurrent writes without corruption** - Tests parallel logging operations

### 13. Configuration & Environment (4 tests)

Tests for environment variable handling and configuration.

- **logger: log_section is visually distinct in file output** - Verifies sections stand out in log files
- **logger: respects LOG_FILE environment variable** - Tests custom log file path via env var
- **logger: defaults to reasonable log location if LOG_FILE not set** - Tests fallback behavior
- **logger: color codes are properly reset after each log** - Ensures colors don't bleed into non-log output

## Test Execution

### Run All Logger Tests

```bash
cd monorepo
bash scripts/run_tests.sh tests/test_logger.bats
```

### Run Individual Test

```bash
cd monorepo
bash scripts/run_tests.sh tests/test_logger.bats --filter "logger: log_info writes to console"
```

## Expected Implementation Contract

Based on these tests, the logger module must:

1. **Export 5 functions:**

   - `log_debug()` - Debug level logging (gray/dimmed)
   - `log_info()` - Info level logging (normal/white)
   - `log_warning()` - Warning level logging (yellow)
   - `log_error()` - Error level logging (red)
   - `log_section()` - Section headers with visual separators

1. **Timestamp Format:**

   - ISO 8601: `YYYY-MM-DDTHH:MM:SS`
   - Present in all log entries

1. **Output Behavior:**

   - Write to both console (stdout) and log file
   - Console output has color codes
   - File output has NO color codes (clean text)

1. **Color Codes:**

   - DEBUG: Gray/dimmed (ANSI escape codes)
   - INFO: Normal/white (no special color)
   - WARNING: Yellow (ANSI code `\x1b[33m`)
   - ERROR: Red (ANSI code `\x1b[31m`)
   - Colors must be reset after each log

1. **File Operations:**

   - Respect `LOG_FILE` environment variable
   - Create log directory if it doesn't exist
   - Create log file if it doesn't exist
   - Append to existing log file (don't overwrite)
   - Maintain log entry order
   - Set appropriate file permissions (readable/writable)

1. **DRY_RUN Mode:**

   - When `DRY_RUN=1`, add `[DRY-RUN]` indicator to logs
   - Still write to both console and file in dry-run mode

1. **Message Handling:**

   - Support empty messages
   - Support multiline messages
   - Support very long messages (1000+ chars)
   - Handle shell special characters safely

1. **Section Headers:**

   - Visual distinction (separator lines)
   - Stand out from regular log entries
   - Used to mark major deployment steps

## Success Criteria

The implementation is complete when:

- [ ] All 53 tests pass (Green phase)
- [ ] No regressions in existing smoke tests
- [ ] Code is properly documented
- [ ] Implementation follows TDD best practices

## Next Steps

1. **Stage 3 (Implementation):** Create `scripts/logger.sh` to satisfy these tests
1. **Stage 4 (Refactor):** Optimize implementation while keeping tests green
1. **Stage 5 (Integration):** Integrate logger into other deployment scripts

## Test Quality Metrics

- **Isolation:** Each test is independent and can run in any order
- **Repeatability:** Tests use temporary directories for log files
- **Cleanup:** All tests clean up after themselves in teardown()
- **Clarity:** Test names clearly describe what is being tested
- **Coverage:** Tests cover happy path, edge cases, and error conditions

## Related Files

- Test implementation: `tests/test_logger.bats`
- Logger script (to be created): `scripts/logger.sh`
- Test helpers: `tests/helpers/test_helpers.bash`
- Test runner: `scripts/run_tests.sh`
