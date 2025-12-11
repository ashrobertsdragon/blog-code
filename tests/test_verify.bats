#!/usr/bin/env bats

setup() {
    TESTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    LIBS_DIR="${TESTS_DIR}/libs"
    SCRIPTS_DIR="$(cd "${TESTS_DIR}/../scripts" && pwd)"
    FUNCTIONS_DIR="${SCRIPTS_DIR}/functions"

    load "${LIBS_DIR}/bats-support/load"
    load "${LIBS_DIR}/bats-assert/load"
    load helpers/test_helpers.bash

    setup_test_env

    export TEST_LOG_DIR
    TEST_LOG_DIR=$(create_temp_dir)
    export TEST_LOG_FILE="${TEST_LOG_DIR}/test.log"
    export LOG_FILE="${TEST_LOG_FILE}"

    export LOGGER_SCRIPT="${SCRIPTS_DIR}/logger.sh"
    export VALIDATORS_SCRIPT="${SCRIPTS_DIR}/validators.sh"
    export VERIFY_SCRIPT="${FUNCTIONS_DIR}/verify_deployment.sh"

    export DOMAIN="ashlynantrobus.dev"
    export BASE_URI="/"
    export HEALTH_ENDPOINT="/health"
    export VERIFY_TIMEOUT="30"
    export VERIFY_RETRIES="3"
    export VERIFY_RETRY_DELAY="5"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset VALIDATORS_SCRIPT
    unset VERIFY_SCRIPT
    unset DOMAIN
    unset BASE_URI
    unset HEALTH_ENDPOINT
    unset VERIFY_TIMEOUT
    unset VERIFY_RETRIES
    unset VERIFY_RETRY_DELAY
    unset DRY_RUN
    teardown_test_env
}

@test "verify_deployment: script exists and is executable" {
    assert_file_exists "${VERIFY_SCRIPT}"
    [[ -x "${VERIFY_SCRIPT}" ]]
}

@test "verify_deployment: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run source "${VERIFY_SCRIPT}"
    assert_success
}

@test "verify_deployment: function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"
    run type verify_deployment
    assert_success
    assert_output --partial "function"
}

@test "verify_deployment: checks health endpoint" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    run verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Checking|check).*health.*endpoint"
}

@test "verify_deployment: makes HTTP request to health endpoint" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(curl|wget|HTTP request)"
}

@test "verify_deployment: retries on failure" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_FAILURE_THEN_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Retry|retry|attempt)"
}

@test "verify_deployment: retries up to configured maximum" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_ALWAYS_FAILURE=1
    export VERIFY_RETRIES="3"

    verify_deployment || true

    local retry_count
    retry_count=$(grep -c "attempt" "${TEST_LOG_FILE}")
    [[ "${retry_count}" -eq 3 ]]
}

@test "verify_deployment: validates HTTP response status is 200 OK" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "200"
}

@test "verify_deployment: validates response contains expected content" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1
    export EXPECTED_HEALTH_RESPONSE='{"status":"ok"}'

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(status.*ok|healthy|response.*valid)"
}

@test "verify_deployment: respects DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    run verify_deployment
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "verify_deployment: skips actual HTTP check in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    run verify_deployment
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --regexp "(skip.*check|would check)"
}

@test "verify_deployment: handles timeout errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_TIMEOUT=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "timeout"
}

@test "verify_deployment: handles non-200 responses" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_STATUS_500=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "500"
}

@test "verify_deployment: logs verification status" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Verification|verify|Health check)"
}

@test "verify_deployment: uses correct domain for health check" {
    export DOMAIN="example.com"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "example.com"
}

@test "verify_deployment: uses correct base_uri for health check" {
    export BASE_URI="/app"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/app"
}

@test "verify_deployment: uses correct health endpoint path" {
    export HEALTH_ENDPOINT="/api/health"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/api/health"
}

@test "verify_deployment: constructs full URL correctly" {
    export DOMAIN="example.com"
    export BASE_URI="/blog"
    export HEALTH_ENDPOINT="/status"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "example.com"
    assert_output --partial "/blog"
    assert_output --partial "/status"
}

@test "verify_deployment: uses HTTPS by default" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "https://"
}

@test "verify_deployment: validates required environment variables before proceeding" {
    unset DOMAIN
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DOMAIN"
}

@test "verify_deployment: fails when DOMAIN is not set" {
    unset DOMAIN
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    run verify_deployment
    assert_failure
}

@test "verify_deployment: defaults BASE_URI to / if not set" {
    unset BASE_URI
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/"
}

@test "verify_deployment: defaults HEALTH_ENDPOINT to /health if not set" {
    unset HEALTH_ENDPOINT
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/health"
}

@test "verify_deployment: defaults VERIFY_RETRIES to 3 if not set" {
    unset VERIFY_RETRIES
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_ALWAYS_FAILURE=1

    verify_deployment || true

    local retry_count
    retry_count=$(grep -c "attempt" "${TEST_LOG_FILE}")
    [[ "${retry_count}" -eq 3 ]]
}

@test "verify_deployment: defaults VERIFY_TIMEOUT to 30 if not set" {
    unset VERIFY_TIMEOUT
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "30"
}

@test "verify_deployment: uses custom timeout when set" {
    export VERIFY_TIMEOUT="60"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "60"
}

@test "verify_deployment: uses custom retry count when set" {
    export VERIFY_RETRIES="5"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_ALWAYS_FAILURE=1

    verify_deployment || true

    local retry_count
    retry_count=$(grep -c "attempt" "${TEST_LOG_FILE}")
    [[ "${retry_count}" -eq 5 ]]
}

@test "verify_deployment: waits between retries" {
    export VERIFY_RETRY_DELAY="2"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_FAILURE_THEN_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(wait|sleep|delay)"
}

@test "verify_deployment: logs section header for verification" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Deployment Verification|Verify.*Deployment|Health Check)"
}

@test "verify_deployment: uses curl for HTTP requests" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "curl"
}

@test "verify_deployment: uses curl with timeout flag" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "curl.*--max-time"
}

@test "verify_deployment: uses curl with silent flag" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "curl.*-s"
}

@test "verify_deployment: uses curl with write-out for status code" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "curl.*-w.*http_code"
}

@test "verify_deployment: logs successful verification" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Verification.*successful|Deployment.*verified|Health check.*passed)"
}

@test "verify_deployment: logs failed verification after all retries" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_ALWAYS_FAILURE=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(Verification.*failed|Health check.*failed)"
}

@test "verify_deployment: returns success when health check passes" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    run verify_deployment
    assert_success
}

@test "verify_deployment: returns failure when health check fails after retries" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_ALWAYS_FAILURE=1

    run verify_deployment
    assert_failure
}

@test "verify_deployment: logs info level for successful operations" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "INFO"
}

@test "verify_deployment: logs error level for failed verification" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_ALWAYS_FAILURE=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "verify_deployment: handles connection refused errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_CONNECTION_REFUSED=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(connection.*refused|could not connect)"
}

@test "verify_deployment: handles DNS resolution errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_DNS_ERROR=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(DNS|domain.*not.*found|could not resolve)"
}

@test "verify_deployment: logs retry attempt number" {
    export VERIFY_RETRIES="3"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_FAILURE_THEN_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "attempt.*[0-9]"
}

@test "verify_deployment: follows redirects when checking health" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "curl.*-L"
}

@test "verify_deployment: validates JSON response structure" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1
    export EXPECTED_HEALTH_RESPONSE='{"status":"ok","version":"1.0"}'

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(JSON|response.*valid|status.*ok)"
}

@test "verify_deployment: handles invalid JSON response" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_INVALID_JSON=1

    verify_deployment || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(invalid.*JSON|malformed.*response)"
}

@test "verify_deployment: checks response body contains expected fields" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1
    export EXPECTED_HEALTH_RESPONSE='{"status":"healthy","database":"connected"}'

    verify_deployment

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(status|database|connected)"
}

@test "verify_deployment: handles domain with HTTPS correctly" {
    export DOMAIN="https://example.com"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    run verify_deployment
    assert_success
}

@test "verify_deployment: handles domain without protocol correctly" {
    export DOMAIN="example.com"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${VERIFY_SCRIPT}"

    export MOCK_HTTP_SUCCESS=1

    run verify_deployment
    assert_success
}
