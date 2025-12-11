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
    export PROVISION_DB_SCRIPT="${FUNCTIONS_DIR}/provision_database.sh"

    export CPANEL_POSTGRES_USER="test_blog_user"
    export CPANEL_POSTGRES_PASSWORD="test_password"
    export DATABASE_NAME="test_blog_db"

    export CPANEL_USERNAME="testuser"
    export SERVER_IP_ADDRESS="192.168.1.100"
    export SSH_PORT="22"
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/test_key"
    echo "mock-ssh-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

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
    unset PROVISION_DB_SCRIPT
    unset CPANEL_POSTGRES_USER
    unset CPANEL_POSTGRES_PASSWORD
    unset DATABASE_NAME
    unset CPANEL_USERNAME
    unset SERVER_IP_ADDRESS
    unset SSH_PORT
    unset SSH_PRIVATE_KEY_PATH
    unset MOCK_SSH_RESPONSE_FILE
    unset DRY_RUN
    teardown_test_env
}

@test "provision_database: script exists and is executable" {
    assert_file_exists "${PROVISION_DB_SCRIPT}"
    [[ -x "${PROVISION_DB_SCRIPT}" ]]
}

@test "provision_database: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run source "${PROVISION_DB_SCRIPT}"
    assert_success
}

@test "provision_database: function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"
    run type provision_database
    assert_success
    assert_output --partial "function"
}

@test "provision_database: checks if database exists before creating" {
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Checking|check).*database"
}

@test "provision_database: creates database when it does not exist" {
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Creating|create).*database"
}

@test "provision_database: skips database creation when it already exists" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(already exists|skip)"
}

@test "provision_database: checks if database user exists before creating" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Checking|check).*user"
}

@test "provision_database: creates user when it does not exist" {
    mock_uapi "uapi_mysql_list_users_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Creating|create).*user"
}

@test "provision_database: skips user creation when it already exists" {
    mock_uapi "uapi_mysql_list_users_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(already exists|skip)"
}

@test "provision_database: grants privileges to user on database" {
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Grant|privileges)"
}

@test "provision_database: grants privileges idempotently" {
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_success

    run provision_database
    assert_success
}

@test "provision_database: respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "provision_database: logs all operations in DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "database"
    assert_output --partial "user"
    assert_output --partial "privileges"
}

@test "provision_database: uses DATABASE_NAME environment variable" {
    export DATABASE_NAME="custom_blog_db"
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_blog_db"
}

@test "provision_database: uses CPANEL_POSTGRES_USER environment variable" {
    export CPANEL_POSTGRES_USER="custom_user"
    mock_uapi "uapi_mysql_list_users_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_user"
}

@test "provision_database: does not log password in plaintext" {
    export CPANEL_POSTGRES_PASSWORD="SuperSecret123!"
    mock_uapi "uapi_mysql_create_user_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "SuperSecret123!"
}

@test "provision_database: fails when DATABASE_NAME is not set" {
    unset DATABASE_NAME
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_failure
}

@test "provision_database: fails when CPANEL_POSTGRES_USER is not set" {
    unset CPANEL_POSTGRES_USER
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_failure
}

@test "provision_database: fails when CPANEL_POSTGRES_PASSWORD is not set" {
    unset CPANEL_POSTGRES_PASSWORD
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_failure
}

@test "provision_database: logs error when database creation fails" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "provision_database: returns non-zero on failure" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_failure
}

@test "provision_database: creates database before creating user" {
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    local db_line user_line
    db_line=$(grep -n "database" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)
    user_line=$(grep -n "user" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)

    [[ "${db_line}" -lt "${user_line}" ]]
}

@test "provision_database: creates user before granting privileges" {
    mock_uapi "uapi_mysql_list_users_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    local user_line priv_line
    user_line=$(grep -n "user" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)
    priv_line=$(grep -n "privileges" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)

    [[ "${user_line}" -lt "${priv_line}" ]]
}

@test "provision_database: logs section header for database provisioning" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Database Provisioning|Provision Database)"
}

@test "provision_database: calls uapi_db_exists with correct database name" {
    export DATABASE_NAME="test_db_name"
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "test_db_name"
}

@test "provision_database: calls uapi_db_user_exists with correct user name" {
    export CPANEL_POSTGRES_USER="test_user_name"
    mock_uapi "uapi_mysql_list_users_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "test_user_name"
}

@test "provision_database: calls uapi_grant_privileges with correct database and user" {
    export DATABASE_NAME="test_db"
    export CPANEL_POSTGRES_USER="test_user"
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "test_db"
    assert_output --partial "test_user"
}

@test "provision_database: is idempotent on repeated calls" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_success

    run provision_database
    assert_success

    run provision_database
    assert_success
}

@test "provision_database: logs info level for successful operations" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "INFO"
}

@test "provision_database: validates required environment variables before proceeding" {
    unset DATABASE_NAME
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    provision_database || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DATABASE_NAME"
}

@test "provision_database: handles database names with underscores" {
    export DATABASE_NAME="test_blog_db_v2"
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_success
}

@test "provision_database: handles user names with underscores" {
    export CPANEL_POSTGRES_USER="test_blog_user_v2"
    mock_uapi "uapi_mysql_list_users_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${PROVISION_DB_SCRIPT}"

    run provision_database
    assert_success
}
