# Logger Implementation Guide (Stage 3)

## Quick Reference for Implementation

This guide provides implementation hints for creating `scripts/logger.sh` that passes all 53 tests.

## Required Functions

### 1. log_debug()

```bash
log_debug() {
    local message="$1"
    _log "DEBUG" "$message" "\x1b[90m"  # Gray color
}
```

### 2. log_info()

```bash
log_info() {
    local message="$1"
    _log "INFO" "$message" ""  # No color (normal)
}
```

### 3. log_warning()

```bash
log_warning() {
    local message="$1"
    _log "WARNING" "$message" "\x1b[33m"  # Yellow color
}
```

### 4. log_error()

```bash
log_error() {
    local message="$1"
    _log "ERROR" "$message" "\x1b[31m"  # Red color
}
```

### 5. log_section()

```bash
log_section() {
    local message="$1"
    # Should output visual separator lines
    # Example: ========================================
    #          Section Title
    #          ========================================
}
```

## Core Implementation Helper

### Internal \_log() Function

```bash
_log() {
    local level="$1"
    local message="$2"
    local color="$3"
    local reset="\x1b[0m"

    # 1. Generate ISO 8601 timestamp
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")

    # 2. Build log entry
    local log_entry="[${timestamp}] [${level}] ${message}"

    # 3. Add DRY_RUN indicator if needed
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_entry="[DRY-RUN] ${log_entry}"
    fi

    # 4. Output to console WITH color
    if [[ -n "${color}" ]]; then
        echo -e "${color}${log_entry}${reset}"
    else
        echo "${log_entry}"
    fi

    # 5. Output to file WITHOUT color
    _log_to_file "${log_entry}"
}
```

## File Operations

### Log File Management

```bash
_log_to_file() {
    local message="$1"

    # Use LOG_FILE env var or default
    local log_file="${LOG_FILE:-/tmp/deployment.log}"

    # Create directory if needed
    local log_dir=$(dirname "${log_file}")
    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}"
    fi

    # Append to file (strip any color codes)
    echo "${message}" | sed 's/\x1b\[[0-9;]*m//g' >> "${log_file}"
}
```

## ANSI Color Codes

```bash
# Color constants
COLOR_RESET="\x1b[0m"
COLOR_RED="\x1b[31m"
COLOR_YELLOW="\x1b[33m"
COLOR_GRAY="\x1b[90m"
```

## Timestamp Format

ISO 8601 format: `YYYY-MM-DDTHH:MM:SS`

```bash
# Generate timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
```

## Section Headers

Visual separator example:

```text
========================================
[2025-12-10T12:34:56] [SECTION] Database Setup
========================================
```

## DRY_RUN Mode

```bash
if [[ "${DRY_RUN:-0}" == "1" ]]; then
    # Add [DRY-RUN] prefix to log entries
    log_entry="[DRY-RUN] ${log_entry}"
fi
```

## Edge Cases to Handle

### 1. Empty Messages

```bash
# Should not fail on empty string
log_info ""
```

### 2. Multiline Messages

```bash
# Should preserve newlines
log_info "Line 1
Line 2
Line 3"
```

### 3. Special Characters

```bash
# Should safely handle shell special chars
log_info "Message with \$special @chars #and !symbols"
```

### 4. Very Long Messages

```bash
# Should not truncate messages
long_message=$(printf 'A%.0s' {1..1000})
log_info "${long_message}"
```

## File Permissions

Log files should be:

- Readable: `-r`
- Writable: `-w`

```bash
# After creating log file, ensure proper permissions
chmod 644 "${log_file}"
```

## Concurrent Write Safety

For basic safety, consider using file locking:

```bash
_log_to_file() {
    local message="$1"
    local log_file="${LOG_FILE:-/tmp/deployment.log}"

    # Use flock for concurrent write safety (if available)
    if command -v flock &> /dev/null; then
        (
            flock -x 200
            echo "${message}" >> "${log_file}"
        ) 200>"${log_file}.lock"
    else
        echo "${message}" >> "${log_file}"
    fi
}
```

## Color Stripping Regex

To remove ANSI color codes from file output:

```bash
# Strip color codes using sed
echo "${message}" | sed 's/\x1b\[[0-9;]*m//g'

# Alternative using parameter expansion (more portable)
message_clean="${message//$'\x1b['[0-9;]*m/}"
```

## Test Execution

After implementation, verify all tests pass:

```bash
cd monorepo
bash scripts/run_tests.sh tests/test_logger.bats
```

Expected output:

```text
1..53
ok 1 logger: script exists and is executable
ok 2 logger: can be sourced without errors
[... 51 more passing tests ...]
ok 53 logger: color codes are properly reset after each log
```

## Common Pitfalls

1. **Forgetting to strip color codes from file output**

   - Console: WITH colors
   - File: WITHOUT colors

1. **Incorrect timestamp format**

   - Must be ISO 8601: `YYYY-MM-DDTHH:MM:SS`
   - Not: `YYYY/MM/DD HH:MM:SS`

1. **Not creating log directory**

   - Use `mkdir -p` to create parent directories

1. **Color codes not reset**

   - Always append `\x1b[0m` after colored output

1. **DRY_RUN indicator placement**

   - Should appear at START of log entry
   - Format: `[DRY-RUN] [timestamp] [level] message`

1. **Appending vs Overwriting**

   - Use `>>` to append to log file
   - Never use `>` (overwrites entire file)

## Implementation Checklist

- [ ] Create `scripts/logger.sh` file
- [ ] Make script executable (`chmod +x`)
- [ ] Add shebang: `#!/usr/bin/env bash`
- [ ] Implement 5 required functions
- [ ] Add `_log()` internal helper
- [ ] Add `_log_to_file()` file writer
- [ ] Implement ISO 8601 timestamp generation
- [ ] Add color code constants
- [ ] Strip colors from file output
- [ ] Handle DRY_RUN mode
- [ ] Create log directory if missing
- [ ] Handle empty messages gracefully
- [ ] Support multiline messages
- [ ] Escape special characters safely
- [ ] Run all 53 tests
- [ ] Verify all tests pass

## Minimal Implementation Size

Target: ~100-150 lines of code

- 5 public functions: ~25 lines
- Internal helpers: ~50 lines
- Constants/setup: ~10 lines
- Error handling: ~15 lines

Keep it simple - avoid premature optimization!

## Success Criteria

Implementation is complete when:

1. All 53 tests pass (Green phase)
1. Smoke tests still pass (no regression)
1. Code is readable and maintainable
1. No unnecessary complexity

---

**Reference:** See `tests/TEST_LOGGER_COVERAGE.md` for full test specifications
**Tests:** See `tests/test_logger.bats` for detailed test cases
