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
    export UPLOAD_CODE_SCRIPT="${FUNCTIONS_DIR}/upload_code.sh"

    export CPANEL_USERNAME="testuser"
    export SERVER_IP_ADDRESS="192.168.1.100"
    export SSH_PORT="22"
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/test_key"
    echo "mock-ssh-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    export BACKEND_DIR="${TEST_LOG_DIR}/backend"
    export FRONTEND_DIR="${TEST_LOG_DIR}/frontend"
    export REMOTE_APP_PATH="/home/testuser/blog"
    export BUILD_DIR="${FRONTEND_DIR}/dist"

    mkdir -p "${BACKEND_DIR}"
    mkdir -p "${FRONTEND_DIR}"
    mkdir -p "${BUILD_DIR}"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset VALIDATORS_SCRIPT
    unset UPLOAD_CODE_SCRIPT
    unset CPANEL_USERNAME
    unset SERVER_IP_ADDRESS
    unset SSH_PORT
    unset SSH_PRIVATE_KEY_PATH
    unset BACKEND_DIR
    unset FRONTEND_DIR
    unset REMOTE_APP_PATH
    unset BUILD_DIR
    unset DRY_RUN
    unset OS
    teardown_test_env
}

@test "upload_code: script exists and is executable" {
    assert_file_exists "${UPLOAD_CODE_SCRIPT}"
    [[ -x "${UPLOAD_CODE_SCRIPT}" ]]
}

@test "upload_code: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run source "${UPLOAD_CODE_SCRIPT}"
    assert_success
}

@test "upload_code: function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"
    run type upload_code
    assert_success
    assert_output --partial "function"
}

@test "upload_code: builds frontend before uploading" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(npm run build|Building frontend)"
}

@test "upload_code: checks if build directory exists before upload" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(build.*directory|dist.*directory)"
}

@test "upload_code: fails if build directory does not exist" {
    rm -rf "${BUILD_DIR}"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_failure
}

@test "upload_code: logs error when build directory missing" {
    rm -rf "${BUILD_DIR}"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(build|dist)"
}

@test "upload_code: uploads backend via rsync over SSH" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "rsync"
    assert_output --regexp "(backend|Uploading.*backend)"
}

@test "upload_code: uploads frontend build directory via rsync" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "rsync"
    assert_output --regexp "(frontend|build|dist)"
}

@test "upload_code: uses correct SSH key path for rsync" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/custom_key"
    echo "custom-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "custom_key"
}

@test "upload_code: uses correct SSH port for rsync" {
    export SSH_PORT="2222"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "2222"
}

@test "upload_code: uses correct remote path for upload" {
    export REMOTE_APP_PATH="/custom/path/blog"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "/custom/path/blog"
}

@test "upload_code: calls linuxify_ssh_key.sh when OS is not Windows_NT" {
    export OS="Linux"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "linuxify"
}

@test "upload_code: skips linuxify_ssh_key.sh when OS is Windows_NT" {
    export OS="Windows_NT"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "linuxify"
}

@test "upload_code: respects DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "upload_code: does not execute rsync in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --partial "rsync"
}

@test "upload_code: does not execute npm build in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --regexp "(npm|build)"
}

@test "upload_code: fails when frontend build fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    export MOCK_NPM_BUILD_FAILURE=1

    run upload_code
    assert_failure
}

@test "upload_code: logs error when frontend build fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    export MOCK_NPM_BUILD_FAILURE=1

    upload_code || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --regexp "(build.*fail|npm.*fail)"
}

@test "upload_code: fails when backend rsync fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    export MOCK_RSYNC_FAILURE=1

    run upload_code
    assert_failure
}

@test "upload_code: logs error when rsync fails" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    export MOCK_RSYNC_FAILURE=1

    upload_code || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "rsync"
}

@test "upload_code: validates required environment variables before proceeding" {
    unset CPANEL_USERNAME
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "CPANEL_USERNAME"
}

@test "upload_code: fails when BACKEND_DIR is not set" {
    unset BACKEND_DIR
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_failure
}

@test "upload_code: fails when FRONTEND_DIR is not set" {
    unset FRONTEND_DIR
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_failure
}

@test "upload_code: fails when REMOTE_APP_PATH is not set" {
    unset REMOTE_APP_PATH
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_failure
}

@test "upload_code: logs section header for code upload" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Code Upload|Upload.*Code|Uploading)"
}

@test "upload_code: uses rsync with archive flag for preserving permissions" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "rsync.*-a"
}

@test "upload_code: uses rsync with verbose flag for logging" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "rsync.*-v"
}

@test "upload_code: uses rsync with compress flag for efficiency" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "rsync.*-z"
}

@test "upload_code: excludes node_modules from backend upload" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(exclude.*node_modules|--exclude.*node_modules)"
}

@test "upload_code: excludes .git directory from backend upload" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(exclude.*\.git|--exclude.*\.git)"
}

@test "upload_code: excludes __pycache__ from backend upload" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(exclude.*__pycache__|--exclude.*__pycache__)"
}

@test "upload_code: uploads backend before frontend" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    local backend_line frontend_line
    backend_line=$(grep -n "backend" "${TEST_LOG_FILE}" | grep -i "upload" | head -1 | cut -d: -f1)
    frontend_line=$(grep -n "frontend" "${TEST_LOG_FILE}" | grep -i "upload" | head -1 | cut -d: -f1)

    [[ "${backend_line}" -lt "${frontend_line}" ]]
}

@test "upload_code: builds frontend before uploading frontend" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    local build_line upload_line
    build_line=$(grep -n "build" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)
    upload_line=$(grep -n "upload.*frontend" "${TEST_LOG_FILE}" | head -1 | cut -d: -f1)

    [[ "${build_line}" -lt "${upload_line}" ]]
}

@test "upload_code: uses SSH connection string with username and server" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "testuser@192.168.1.100"
}

@test "upload_code: logs successful upload completion" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(Upload.*complete|Successfully uploaded)"
}

@test "upload_code: returns success when all operations complete" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_success
}

@test "upload_code: creates remote directories if they do not exist" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(mkdir|create.*director)"
}

@test "upload_code: handles spaces in file paths correctly" {
    export BACKEND_DIR="${TEST_LOG_DIR}/backend with spaces"
    mkdir -p "${BACKEND_DIR}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    run upload_code
    assert_success
}

@test "upload_code: uses correct npm command for build" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "npm run (build|prod)"
}

@test "upload_code: changes directory to frontend before building" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    source "${UPLOAD_CODE_SCRIPT}"

    upload_code

    run cat "${TEST_LOG_FILE}"
    assert_output --regexp "(cd.*frontend|Changing.*directory)"
}
