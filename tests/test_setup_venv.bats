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
    export SETUP_VENV_SCRIPT="${FUNCTIONS_DIR}/setup_venv.sh"

    export CPANEL_USERNAME="testuser"
    export SERVER_IP_ADDRESS="192.168.1.100"
    export SSH_PORT="22"
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/test_key"
    echo "mock-ssh-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    export REMOTE_APP_PATH="/home/testuser/blog"
    export VENV_PATH="${REMOTE_APP_PATH}/venv"
    export BACKEND_PATH="${REMOTE_APP_PATH}/backend"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset VALIDATORS_SCRIPT
    unset SETUP_VENV_SCRIPT
    unset CPANEL_USERNAME
    unset SERVER_IP_ADDRESS
    unset SSH_PORT
    unset SSH_PRIVATE_KEY_PATH
    unset REMOTE_APP_PATH
    unset VENV_PATH
    unset BACKEND_PATH
    unset DRY_RUN
    teardown_test_env
}

@test "setup_venv: script exists and is executable" {
    assert_file_exists "${SETUP_VENV_SCRIPT}"
    [[ -x "${SETUP_VENV_SCRIPT}" ]]
}

@test "setup_venv: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run source "${SETUP_VENV_SCRIPT}"
    assert_success
}

@test "setup_venv: function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"
    run type setup_venv
    assert_success
    assert_output --partial "function"
}

@test "setup_venv: checks if virtualenv already exists" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Checking|check).*virtualenv"
}

@test "setup_venv: creates virtualenv when it does not exist" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_VENV_MISSING=1

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Creating|create).*virtualenv"
}

@test "setup_venv: skips virtualenv creation when it already exists" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_VENV_EXISTS=1

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(already exists|skip).*virtualenv"
}

@test "setup_venv: checks if uv is installed" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Checking|check).*uv"
}

@test "setup_venv: installs uv when not installed" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_UV_MISSING=1

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Installing|install).*uv"
}

@test "setup_venv: skips uv installation when already installed" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_UV_EXISTS=1

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(already installed|skip).*uv"
}

@test "setup_venv: installs uv via pip in virtualenv" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_UV_MISSING=1

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "pip install"
    assert_output --partial "uv"
}

@test "setup_venv: syncs dependencies with uv sync" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "uv sync"
}

@test "setup_venv: uv sync is idempotent" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success

    run setup_venv
    assert_success
}

@test "setup_venv: respects DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "setup_venv: does not create virtualenv in DRY_RUN mode" {
    export DRY_RUN=1
    export MOCK_VENV_MISSING=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --regexp "(virtualenv|venv)"
}

@test "setup_venv: does not install uv in DRY_RUN mode" {
    export DRY_RUN=1
    export MOCK_UV_MISSING=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --partial "uv"
}

@test "setup_venv: does not sync dependencies in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --partial "uv sync"
}

@test "setup_venv: uses correct virtualenv path" {
    export VENV_PATH="/custom/venv/path"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/custom/venv/path"
}

@test "setup_venv: uses correct backend path for uv sync" {
    export BACKEND_PATH="/custom/backend/path"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/custom/backend/path"
}

@test "setup_venv: validates required environment variables before proceeding" {
    unset REMOTE_APP_PATH
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "REMOTE_APP_PATH"
}

@test "setup_venv: fails when REMOTE_APP_PATH is not set" {
    unset REMOTE_APP_PATH
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_failure
}

@test "setup_venv: fails when CPANEL_USERNAME is not set" {
    unset CPANEL_USERNAME
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_failure
}

@test "setup_venv: logs error when virtualenv creation fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_VENV_CREATION_FAILURE=1

    setup_venv || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "virtualenv"
}

@test "setup_venv: logs error when uv installation fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_UV_INSTALLATION_FAILURE=1

    setup_venv || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "uv"
}

@test "setup_venv: logs error when uv sync fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_UV_SYNC_FAILURE=1

    setup_venv || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "uv sync"
}

@test "setup_venv: returns non-zero on failure" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    export MOCK_VENV_CREATION_FAILURE=1

    run setup_venv
    assert_failure
}

@test "setup_venv: creates virtualenv before installing uv" {
    export MOCK_VENV_MISSING=1
    export MOCK_UV_MISSING=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    local venv_line uv_line
    venv_line=$(grep -n "virtualenv" "${TEST_LOG_FILE}" | grep -i "creat" | head -1 | cut -d: -f1)
    uv_line=$(grep -n "uv" "${TEST_LOG_FILE}" | grep -i "install" | head -1 | cut -d: -f1)

    [[ "${venv_line}" -lt "${uv_line}" ]]
}

@test "setup_venv: installs uv before syncing dependencies" {
    export MOCK_UV_MISSING=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    local uv_install_line sync_line
    uv_install_line=$(grep -n "install.*uv" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)
    sync_line=$(grep -n "uv sync" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)

    [[ "${uv_install_line}" -lt "${sync_line}" ]]
}

@test "setup_venv: logs section header for virtual environment setup" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Virtual Environment|Setup.*venv|Python Environment)"
}

@test "setup_venv: executes commands via SSH on remote server" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ssh"
}

@test "setup_venv: uses correct SSH connection string" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "testuser@192.168.1.100"
}

@test "setup_venv: uses correct SSH key for remote connection" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/custom_key"
    echo "custom-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_key"
}

@test "setup_venv: uses correct SSH port for remote connection" {
    export SSH_PORT="2222"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "2222"
}

@test "setup_venv: uses python3 -m venv for virtualenv creation" {
    export MOCK_VENV_MISSING=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "python3 -m venv"
}

@test "setup_venv: activates virtualenv before installing uv" {
    export MOCK_UV_MISSING=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(source.*activate|bin/activate)"
}

@test "setup_venv: runs uv sync from backend directory" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(cd.*backend|Changing.*backend)"
}

@test "setup_venv: logs successful completion" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Setup.*complete|Successfully.*setup)"
}

@test "setup_venv: is idempotent on repeated calls" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success

    run setup_venv
    assert_success

    run setup_venv
    assert_success
}

@test "setup_venv: handles spaces in remote path correctly" {
    export REMOTE_APP_PATH="/home/testuser/my app"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    run setup_venv
    assert_success
}

@test "setup_venv: uses uv sync without additional flags by default" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "uv sync"
}

@test "setup_venv: logs info level for successful operations" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${SETUP_VENV_SCRIPT}"

    setup_venv

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "INFO"
}
