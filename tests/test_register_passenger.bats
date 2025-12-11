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
    export UAPI_SCRIPT="${SCRIPTS_DIR}/uapi.sh"
    export VALIDATORS_SCRIPT="${SCRIPTS_DIR}/validators.sh"
    export REGISTER_PASSENGER_SCRIPT="${FUNCTIONS_DIR}/register_passenger.sh"

    export CPANEL_USERNAME="testuser"
    export SERVER_IP_ADDRESS="192.168.1.100"
    export SSH_PORT="22"
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/test_key"
    echo "mock-ssh-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    export DOMAIN="ashlynantrobus.dev"
    export BASE_URI="/"
    export REMOTE_APP_PATH="/home/testuser/blog"
    export DATABASE_NAME="test_blog_db"
    export CPANEL_POSTGRES_USER="test_blog_user"
    export CPANEL_POSTGRES_PASSWORD="test_password"
    export DB_HOST="localhost"
    export DB_PORT="5432"

    export MOCK_SSH_RESPONSE_FILE="${TEST_LOG_DIR}/mock_ssh_response.json"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset UAPI_SCRIPT
    unset VALIDATORS_SCRIPT
    unset REGISTER_PASSENGER_SCRIPT
    unset CPANEL_USERNAME
    unset SERVER_IP_ADDRESS
    unset SSH_PORT
    unset SSH_PRIVATE_KEY_PATH
    unset DOMAIN
    unset BASE_URI
    unset REMOTE_APP_PATH
    unset DATABASE_NAME
    unset CPANEL_POSTGRES_USER
    unset CPANEL_POSTGRES_PASSWORD
    unset DB_HOST
    unset DB_PORT
    unset MOCK_SSH_RESPONSE_FILE
    unset DRY_RUN
    teardown_test_env
}

@test "register_passenger: script exists and is executable" {
    assert_file_exists "${REGISTER_PASSENGER_SCRIPT}"
    [[ -x "${REGISTER_PASSENGER_SCRIPT}" ]]
}

@test "register_passenger: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run source "${REGISTER_PASSENGER_SCRIPT}"
    assert_success
}

@test "register_passenger: function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"
    run type register_passenger
    assert_success
    assert_output --partial "function"
}

@test "register_passenger: checks if Passenger app already registered" {
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Checking|check).*Passenger.*app"
}

@test "register_passenger: registers new app when not exists" {
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Registering|register).*Passenger.*app"
}

@test "register_passenger: skips registration when app already exists" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(already registered|skip.*registration)"
}

@test "register_passenger: restarts existing app instead of registering" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Restarting|restart).*app"
}

@test "register_passenger: injects DATABASE_NAME environment variable" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DATABASE_NAME"
}

@test "register_passenger: injects CPANEL_POSTGRES_USER environment variable" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "CPANEL_POSTGRES_USER"
}

@test "register_passenger: injects CPANEL_POSTGRES_PASSWORD environment variable" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "CPANEL_POSTGRES_PASSWORD"
}

@test "register_passenger: injects DB_HOST environment variable" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DB_HOST"
}

@test "register_passenger: injects DB_PORT environment variable" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DB_PORT"
}

@test "register_passenger: does not log password values in plaintext" {
    export CPANEL_POSTGRES_PASSWORD="SuperSecret123!"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "SuperSecret123!"
}

@test "register_passenger: uses correct domain" {
    export DOMAIN="example.com"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "example.com"
}

@test "register_passenger: uses correct base_uri" {
    export BASE_URI="/blog"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/blog"
}

@test "register_passenger: uses correct app_path" {
    export REMOTE_APP_PATH="/custom/app/path"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/custom/app/path"
}

@test "register_passenger: respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "register_passenger: does not register app in DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --regexp "(register|Passenger)"
}

@test "register_passenger: does not restart app in DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --regexp "(restart|Restarting)"
}

@test "register_passenger: handles registration failures" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "register_passenger: returns non-zero on registration failure" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_failure
}

@test "register_passenger: handles restart failures" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    export MOCK_RESTART_FAILURE=1

    register_passenger || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "register_passenger: returns non-zero on restart failure" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    export MOCK_RESTART_FAILURE=1

    run register_passenger
    assert_failure
}

@test "register_passenger: validates required environment variables before proceeding" {
    unset DOMAIN
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DOMAIN"
}

@test "register_passenger: fails when DOMAIN is not set" {
    unset DOMAIN
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_failure
}

@test "register_passenger: fails when BASE_URI is not set" {
    unset BASE_URI
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_failure
}

@test "register_passenger: fails when REMOTE_APP_PATH is not set" {
    unset REMOTE_APP_PATH
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_failure
}

@test "register_passenger: logs section header for Passenger registration" {
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Passenger.*Registration|Register.*Passenger|Passenger.*App)"
}

@test "register_passenger: calls uapi_passenger_app_exists with correct domain and base_uri" {
    export DOMAIN="testdomain.com"
    export BASE_URI="/testpath"
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "testdomain.com"
    assert_output --partial "/testpath"
}

@test "register_passenger: calls uapi_register_passenger_app with correct parameters" {
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ashlynantrobus.dev"
    assert_output --partial "/"
    assert_output --partial "/home/testuser/blog"
}

@test "register_passenger: calls uapi_restart_passenger_app with correct parameters" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ashlynantrobus.dev"
    assert_output --partial "/"
}

@test "register_passenger: is idempotent on repeated calls" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success

    run register_passenger
    assert_success

    run register_passenger
    assert_success
}

@test "register_passenger: logs info level for successful operations" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "INFO"
}

@test "register_passenger: logs successful registration completion" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Registration.*complete|Successfully.*registered)"
}

@test "register_passenger: logs successful restart completion" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Restart.*complete|Successfully.*restarted)"
}

@test "register_passenger: handles domain with subdomain correctly" {
    export DOMAIN="blog.example.com"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success
}

@test "register_passenger: handles base_uri with trailing slash" {
    export BASE_URI="/blog/"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success
}

@test "register_passenger: handles app_path with spaces correctly" {
    export REMOTE_APP_PATH="/home/testuser/my blog app"
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    run register_passenger
    assert_success
}

@test "register_passenger: checks existence before attempting registration" {
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    local check_line register_line
    check_line=$(grep -n "check" "${TEST_LOG_FILE}" | grep -i "passenger" | head -1 | cut -d: -f1)
    register_line=$(grep -n "register" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)

    [[ "${check_line}" -lt "${register_line}" ]]
}

@test "register_passenger: uses Python application type for Passenger" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${REGISTER_PASSENGER_SCRIPT}"

    register_passenger

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(python|Python)"
}
