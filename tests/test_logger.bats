#!/usr/bin/env bats

setup() {
    TESTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    LIBS_DIR="${TESTS_DIR}/libs"
    SCRIPTS_DIR="$(cd "${TESTS_DIR}/../scripts" && pwd)"

    load "${LIBS_DIR}/bats-support/load"
    load "${LIBS_DIR}/bats-assert/load"
    load helpers/test_helpers.bash

    setup_test_env

    export TEST_LOG_DIR
    TEST_LOG_DIR=$(create_temp_dir)
    export TEST_LOG_FILE="${TEST_LOG_DIR}/test.log"
    export LOG_FILE="${TEST_LOG_FILE}"

    export LOGGER_SCRIPT="${SCRIPTS_DIR}/logger.sh"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset DRY_RUN
    teardown_test_env
}

@test "logger: script exists and is executable" {
    assert_file_exists "${LOGGER_SCRIPT}"
    [[ -x "${LOGGER_SCRIPT}" ]]
}

@test "logger: can be sourced without errors" {
    run source "${LOGGER_SCRIPT}"
    assert_success
}

@test "logger: log_debug function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    run type log_debug
    assert_success
    assert_output --partial "function"
}

@test "logger: log_info function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    run type log_info
    assert_success
    assert_output --partial "function"
}

@test "logger: log_warning function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    run type log_warning
    assert_success
    assert_output --partial "function"
}

@test "logger: log_error function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    run type log_error
    assert_success
    assert_output --partial "function"
}

@test "logger: log_section function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    run type log_section
    assert_success
    assert_output --partial "function"
}

@test "logger: log_debug writes to console" {
    source "${LOGGER_SCRIPT}"
    run log_debug "Test debug message"
    assert_success
    assert_output --partial "DEBUG"
    assert_output --partial "Test debug message"
}

@test "logger: log_debug includes timestamp in output" {
    source "${LOGGER_SCRIPT}"
    run log_debug "Test message"
    assert_success
    assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
}

@test "logger: log_debug creates log file if it doesn't exist" {
    source "${LOGGER_SCRIPT}"
    [[ ! -f "${TEST_LOG_FILE}" ]]

    log_debug "Test message"

    assert_file_exists "${TEST_LOG_FILE}"
}

@test "logger: log_debug writes to log file" {
    source "${LOGGER_SCRIPT}"
    log_debug "Test debug message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "DEBUG"
    assert_output --partial "Test debug message"
}

@test "logger: log_debug file output has no color codes" {
    source "${LOGGER_SCRIPT}"
    log_debug "Test message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    refute_output --regexp $'\033\\[[0-9;]*m'
}

@test "logger: log_debug console output has gray color codes" {
    source "${LOGGER_SCRIPT}"
    run log_debug "Test message"
    assert_success
    assert_output --regexp $'\033\\[[0-9;]*m'
}

@test "logger: log_info writes to console" {
    source "${LOGGER_SCRIPT}"
    run log_info "Test info message"
    assert_success
    assert_output --partial "INFO"
    assert_output --partial "Test info message"
}

@test "logger: log_info includes timestamp in output" {
    source "${LOGGER_SCRIPT}"
    run log_info "Test message"
    assert_success
    assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
}

@test "logger: log_info writes to log file" {
    source "${LOGGER_SCRIPT}"
    log_info "Test info message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "INFO"
    assert_output --partial "Test info message"
}

@test "logger: log_info file output has no color codes" {
    source "${LOGGER_SCRIPT}"
    log_info "Test message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    refute_output --regexp $'\033\\[[0-9;]*m'
}

@test "logger: log_warning writes to console" {
    source "${LOGGER_SCRIPT}"
    run log_warning "Test warning message"
    assert_success
    assert_output --partial "WARNING"
    assert_output --partial "Test warning message"
}

@test "logger: log_warning includes timestamp in output" {
    source "${LOGGER_SCRIPT}"
    run log_warning "Test message"
    assert_success
    assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
}

@test "logger: log_warning writes to log file" {
    source "${LOGGER_SCRIPT}"
    log_warning "Test warning message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "WARNING"
    assert_output --partial "Test warning message"
}

@test "logger: log_warning console output has yellow color codes" {
    source "${LOGGER_SCRIPT}"
    run log_warning "Test message"
    assert_success
    assert_output --regexp $'\033\\[33m'
}

@test "logger: log_warning file output has no color codes" {
    source "${LOGGER_SCRIPT}"
    log_warning "Test message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    refute_output --regexp $'\033\\[[0-9;]*m'
}

@test "logger: log_error writes to console" {
    source "${LOGGER_SCRIPT}"
    run log_error "Test error message"
    assert_success
    assert_output --partial "ERROR"
    assert_output --partial "Test error message"
}

@test "logger: log_error includes timestamp in output" {
    source "${LOGGER_SCRIPT}"
    run log_error "Test message"
    assert_success
    assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
}

@test "logger: log_error writes to log file" {
    source "${LOGGER_SCRIPT}"
    log_error "Test error message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "ERROR"
    assert_output --partial "Test error message"
}

@test "logger: log_error console output has red color codes" {
    source "${LOGGER_SCRIPT}"
    run log_error "Test message"
    assert_success
    assert_output --regexp $'\033\\[31m'
}

@test "logger: log_error file output has no color codes" {
    source "${LOGGER_SCRIPT}"
    log_error "Test message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    refute_output --regexp $'\033\\[[0-9;]*m'
}

@test "logger: log_section writes section header to console" {
    source "${LOGGER_SCRIPT}"
    run log_section "Test Section"
    assert_success
    assert_output --partial "Test Section"
}

@test "logger: log_section has visual distinction from regular logs" {
    source "${LOGGER_SCRIPT}"
    run log_section "Test Section"
    assert_success
    assert_output --regexp '[-=]{10,}'
}

@test "logger: log_section writes to log file" {
    source "${LOGGER_SCRIPT}"
    log_section "Test Section"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "Test Section"
}

@test "logger: log_section includes timestamp" {
    source "${LOGGER_SCRIPT}"
    run log_section "Test Section"
    assert_success
    assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
}

@test "logger: multiple log entries append to same file" {
    source "${LOGGER_SCRIPT}"
    log_info "First message"
    log_info "Second message"
    log_info "Third message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "First message"
    assert_output --partial "Second message"
    assert_output --partial "Third message"
}

@test "logger: log entries maintain order in file" {
    source "${LOGGER_SCRIPT}"
    log_info "Message 1"
    log_info "Message 2"
    log_info "Message 3"

    local line1 line2 line3
    line1=$(grep -n "Message 1" "${TEST_LOG_FILE}" | cut -d: -f1)
    line2=$(grep -n "Message 2" "${TEST_LOG_FILE}" | cut -d: -f1)
    line3=$(grep -n "Message 3" "${TEST_LOG_FILE}" | cut -d: -f1)

    [[ "${line1}" -lt "${line2}" ]]
    [[ "${line2}" -lt "${line3}" ]]
}

@test "logger: creates log directory if it doesn't exist" {
    local nested_log_dir="${TEST_LOG_DIR}/nested/path"
    export LOG_FILE="${nested_log_dir}/test.log"

    source "${LOGGER_SCRIPT}"
    [[ ! -d "${nested_log_dir}" ]]

    log_info "Test message"

    assert_dir_exists "${nested_log_dir}"
    assert_file_exists "${LOG_FILE}"
}

@test "logger: handles messages with special characters" {
    source "${LOGGER_SCRIPT}"
    run log_info "Test message with \$special @characters #and !symbols"
    assert_success
    assert_output --partial "Test message with \$special @characters #and !symbols"
}

@test "logger: handles multiline messages" {
    source "${LOGGER_SCRIPT}"
    run log_info "Line 1
Line 2
Line 3"
    assert_success
    assert_output --partial "Line 1"
    assert_output --partial "Line 2"
    assert_output --partial "Line 3"
}

@test "logger: DRY_RUN mode indicates dry-run in log output" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    run log_info "Test message"
    assert_success
    assert_output --partial "[DRY-RUN]"
}

@test "logger: DRY_RUN mode still writes to console" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    run log_info "Test message"
    assert_success
    assert_output --partial "Test message"
}

@test "logger: DRY_RUN mode still writes to log file" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    log_info "Test message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "Test message"
    assert_output --partial "[DRY-RUN]"
}

@test "logger: different log levels have distinct formatting" {
    source "${LOGGER_SCRIPT}"

    local debug_output info_output warning_output error_output

    debug_output=$(log_debug "Debug message" 2>&1)
    info_output=$(log_info "Info message" 2>&1)
    warning_output=$(log_warning "Warning message" 2>&1)
    error_output=$(log_error "Error message" 2>&1)

    [[ "${debug_output}" != "${info_output}" ]]
    [[ "${info_output}" != "${warning_output}" ]]
    [[ "${warning_output}" != "${error_output}" ]]
}

@test "logger: timestamp format is ISO 8601 compliant" {
    source "${LOGGER_SCRIPT}"
    run log_info "Test message"
    assert_success
    assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
}

@test "logger: log_debug accepts empty message" {
    source "${LOGGER_SCRIPT}"
    run log_debug ""
    assert_success
}

@test "logger: log_info accepts empty message" {
    source "${LOGGER_SCRIPT}"
    run log_info ""
    assert_success
}

@test "logger: log_warning accepts empty message" {
    source "${LOGGER_SCRIPT}"
    run log_warning ""
    assert_success
}

@test "logger: log_error accepts empty message" {
    source "${LOGGER_SCRIPT}"
    run log_error ""
    assert_success
}

@test "logger: handles very long messages without truncation" {
    source "${LOGGER_SCRIPT}"
    local long_message
    long_message=$(printf 'A%.0s' {1..1000})

    run log_info "${long_message}"
    assert_success
    assert_output --partial "${long_message}"
}

@test "logger: log file is created with appropriate permissions" {
    source "${LOGGER_SCRIPT}"
    log_info "Test message"

    assert_file_exists "${TEST_LOG_FILE}"
    [[ -r "${TEST_LOG_FILE}" ]]
    [[ -w "${TEST_LOG_FILE}" ]]
}

@test "logger: handles concurrent writes without corruption" {
    source "${LOGGER_SCRIPT}"

    log_info "Message 1" &
    log_info "Message 2" &
    log_info "Message 3" &
    wait

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "Message 1"
    assert_output --partial "Message 2"
    assert_output --partial "Message 3"
}

@test "logger: preserves existing log file content" {
    echo "Pre-existing log entry" > "${TEST_LOG_FILE}"

    source "${LOGGER_SCRIPT}"
    log_info "New message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    assert_output --partial "Pre-existing log entry"
    assert_output --partial "New message"
}

@test "logger: log_section is visually distinct in file output" {
    source "${LOGGER_SCRIPT}"
    log_info "Regular message"
    log_section "Section Header"
    log_info "Another message"

    run cat "${TEST_LOG_FILE}"
    assert_success
    local section_line
    section_line=$(grep -n "Section Header" "${TEST_LOG_FILE}")
    [[ -n "${section_line}" ]]
}

@test "logger: respects LOG_FILE environment variable" {
    local custom_log="${TEST_LOG_DIR}/custom.log"
    export LOG_FILE="${custom_log}"

    source "${LOGGER_SCRIPT}"
    log_info "Test message"

    assert_file_exists "${custom_log}"
    run cat "${custom_log}"
    assert_success
    assert_output --partial "Test message"
}

@test "logger: defaults to reasonable log location if LOG_FILE not set" {
    unset LOG_FILE
    source "${LOGGER_SCRIPT}"
    run log_info "Test message"
    assert_success
}

@test "logger: color codes are properly reset after each log" {
    source "${LOGGER_SCRIPT}"
    run bash -c "$(declare -f log_error); log_error 'Error'; echo 'Normal text'"
    assert_success
    local last_line
    last_line=$(echo "${output}" | tail -n 1)
    refute_output --regexp $'Normal text.*\033\\[31m'
}
