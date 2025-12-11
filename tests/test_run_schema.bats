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
    export RUN_SCHEMA_SCRIPT="${FUNCTIONS_DIR}/run_schema.sh"

    export CPANEL_USERNAME="testuser"
    export SERVER_IP_ADDRESS="192.168.1.100"
    export SSH_PORT="22"
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/test_key"
    echo "mock-ssh-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    export REMOTE_APP_PATH="/home/testuser/blog"
    export DATABASE_NAME="test_blog_db"
    export CPANEL_POSTGRES_USER="test_blog_user"
    export CPANEL_POSTGRES_PASSWORD="test_password"
    export DB_HOST="localhost"
    export DB_PORT="5432"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset VALIDATORS_SCRIPT
    unset RUN_SCHEMA_SCRIPT
    unset CPANEL_USERNAME
    unset SERVER_IP_ADDRESS
    unset SSH_PORT
    unset SSH_PRIVATE_KEY_PATH
    unset REMOTE_APP_PATH
    unset DATABASE_NAME
    unset CPANEL_POSTGRES_USER
    unset CPANEL_POSTGRES_PASSWORD
    unset DB_HOST
    unset DB_PORT
    unset DRY_RUN
    teardown_test_env
}

@test "run_schema: script exists and is executable" {
    assert_file_exists "${RUN_SCHEMA_SCRIPT}"
    [[ -x "${RUN_SCHEMA_SCRIPT}" ]]
}

@test "run_schema: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run source "${RUN_SCHEMA_SCRIPT}"
    assert_success
}

@test "run_schema: function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"
    run type run_schema
    assert_success
    assert_output --partial "function"
}

@test "run_schema: executes database initialization script" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(init.*database|database.*init|schema.*init)"
}

@test "run_schema: uses correct database connection parameters" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "test_blog_db"
}

@test "run_schema: uses database name from environment variable" {
    export DATABASE_NAME="custom_db_name"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_db_name"
}

@test "run_schema: uses database user from environment variable" {
    export CPANEL_POSTGRES_USER="custom_user"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_user"
}

@test "run_schema: does not log database password in plaintext" {
    export CPANEL_POSTGRES_PASSWORD="SuperSecret123!"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "SuperSecret123!"
}

@test "run_schema: uses database host from environment variable" {
    export DB_HOST="192.168.1.200"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "192.168.1.200"
}

@test "run_schema: uses database port from environment variable" {
    export DB_PORT="5433"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "5433"
}

@test "run_schema: handles schema initialization errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    export MOCK_SCHEMA_FAILURE=1

    run_schema || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "run_schema: returns non-zero on schema initialization failure" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    export MOCK_SCHEMA_FAILURE=1

    run run_schema
    assert_failure
}

@test "run_schema: SQLModel create_all is idempotent" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_success

    run run_schema
    assert_success
}

@test "run_schema: respects DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "run_schema: does not execute schema in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --regexp "(schema|init)"
}

@test "run_schema: logs database operations" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(database|schema|table)"
}

@test "run_schema: uses environment variables for DB credentials" {
    export DATABASE_NAME="env_db"
    export CPANEL_POSTGRES_USER="env_user"
    export CPANEL_POSTGRES_PASSWORD="env_pass"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "env_db"
    assert_output --partial "env_user"
    refute_output --partial "env_pass"
}

@test "run_schema: validates required environment variables before proceeding" {
    unset DATABASE_NAME
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "DATABASE_NAME"
}

@test "run_schema: fails when DATABASE_NAME is not set" {
    unset DATABASE_NAME
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_failure
}

@test "run_schema: fails when CPANEL_POSTGRES_USER is not set" {
    unset CPANEL_POSTGRES_USER
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_failure
}

@test "run_schema: fails when CPANEL_POSTGRES_PASSWORD is not set" {
    unset CPANEL_POSTGRES_PASSWORD
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_failure
}

@test "run_schema: logs section header for schema initialization" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Database Schema|Schema Init|Initialize.*Schema)"
}

@test "run_schema: executes via SSH on remote server" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ssh"
}

@test "run_schema: uses correct SSH connection string" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "testuser@192.168.1.100"
}

@test "run_schema: uses correct SSH key for remote connection" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/custom_key"
    echo "custom-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_key"
}

@test "run_schema: uses correct SSH port for remote connection" {
    export SSH_PORT="2222"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "2222"
}

@test "run_schema: runs Python script from backend directory" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(cd.*backend|backend.*directory)"
}

@test "run_schema: activates virtualenv before running script" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(source.*activate|venv.*activate)"
}

@test "run_schema: uses uv run to execute Python script" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "uv run"
}

@test "run_schema: runs database initialization Python module" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(python.*init|init.*database\.py|db_init)"
}

@test "run_schema: passes database connection string to script" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(postgresql://|connection.*string|DATABASE_URL)"
}

@test "run_schema: constructs PostgreSQL connection URL correctly" {
    export CPANEL_POSTGRES_USER="myuser"
    export DATABASE_NAME="mydb"
    export DB_HOST="myhost"
    export DB_PORT="5433"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "myuser"
    assert_output --partial "mydb"
    assert_output --partial "myhost"
    assert_output --partial "5433"
}

@test "run_schema: logs successful schema initialization" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Schema.*initialized|Successfully.*schema|Database.*ready)"
}

@test "run_schema: logs info level for successful operations" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "INFO"
}

@test "run_schema: handles PostgreSQL connection errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    export MOCK_DB_CONNECTION_FAILURE=1

    run_schema || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(connection|database)"
}

@test "run_schema: creates tables if they do not exist" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(create.*table|Creating.*table)"
}

@test "run_schema: skips table creation if tables already exist" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_success

    run run_schema
    assert_success
}

@test "run_schema: uses SQLModel metadata for schema creation" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(SQLModel|metadata|create_all)"
}

@test "run_schema: defaults DB_HOST to localhost if not set" {
    unset DB_HOST
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "localhost"
}

@test "run_schema: defaults DB_PORT to 5432 if not set" {
    unset DB_PORT
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run_schema

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "5432"
}

@test "run_schema: handles spaces in database name correctly" {
    export DATABASE_NAME="my blog db"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${RUN_SCHEMA_SCRIPT}"

    run run_schema
    assert_success
}
