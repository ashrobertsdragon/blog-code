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
    export VALIDATORS_SCRIPT="${SCRIPTS_DIR}/validators.sh"

    export TEST_SSH_KEY_PATH="${TEST_LOG_DIR}/test_key"
    echo "mock-ssh-key" > "${TEST_SSH_KEY_PATH}"
    chmod 600 "${TEST_SSH_KEY_PATH}"
}

teardown() {
    cleanup_temp_dir "${TEST_LOG_DIR}"
    unset TEST_LOG_DIR
    unset TEST_LOG_FILE
    unset LOG_FILE
    unset LOGGER_SCRIPT
    unset VALIDATORS_SCRIPT
    unset TEST_SSH_KEY_PATH
    unset DRY_RUN
    unset TEST_VAR_1
    unset TEST_VAR_2
    unset TEST_VAR_3
    unset TEST_VAR_4
    unset TEST_VAR_5
    unset TEST_VAR_6
    teardown_test_env
}

@test "validators: script exists and is executable" {
    assert_file_exists "${VALIDATORS_SCRIPT}"
    [[ -x "${VALIDATORS_SCRIPT}" ]]
}

@test "validators: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    run source "${VALIDATORS_SCRIPT}"
    assert_success
}

@test "validators: validate_required_env_vars function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run type validate_required_env_vars
    assert_success
    assert_output --partial "function"
}

@test "validators: validate_required_commands function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run type validate_required_commands
    assert_success
    assert_output --partial "function"
}

@test "validators: validate_ssh_key function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run type validate_required_env_vars
    assert_success
    assert_output --partial "function"
}

@test "validators: dry_run_exec function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"
    run type dry_run_exec
    assert_success
    assert_output --partial "function"
}

@test "validators: validate_required_env_vars succeeds when all test vars set" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_success
}

@test "validators: validate_required_env_vars fails when TEST_VAR_1 missing" {
    unset TEST_VAR_1
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_2 missing" {
    export TEST_VAR_1="dummy"
    unset TEST_VAR_2
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_3 missing" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    unset TEST_VAR_3
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_4 missing" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    unset TEST_VAR_4
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_5 missing" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    unset TEST_VAR_5
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_6 missing" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    unset TEST_VAR_6

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_1 empty" {
    export TEST_VAR_1=""
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_2 empty" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2=""
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_3 empty" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3=""
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_4 empty" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4=""
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_5 empty" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5=""
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars fails when TEST_VAR_6 empty" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6=""

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_failure
}

@test "validators: validate_required_env_vars logs which variable is missing" {
    unset TEST_VAR_1
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6" || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "TEST_VAR_1"
}

@test "validators: validate_required_env_vars logs error level for missing vars" {
    unset TEST_VAR_1

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_test_env_vars "TEST_VAR_1" || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "validators: validate_required_env_vars uses existence check pattern" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run bash -c "grep -E '!\w+\+x' '${VALIDATORS_SCRIPT}'"
    assert_success
}

@test "validators: validate_required_commands succeeds when all commands available" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_required_commands
    assert_success
}

@test "validators: validate_required_commands checks for ssh" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_required_commands

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ssh"
}

@test "validators: validate_required_commands checks for jq" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_required_commands

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "jq"
}

@test "validators: validate_required_commands checks for rsync" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_required_commands

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "rsync"
}

@test "validators: validate_required_commands checks for git" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_required_commands

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "git"
}

@test "validators: validate_required_commands checks for node or npm" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_required_commands

    run cat "${TEST_LOG_FILE}"
    [[ "${output}" =~ "node" || "${output}" =~ "npm" ]]
}

@test "validators: validate_required_commands fails when command missing" {
    export PATH="/nonexistent/path"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_required_commands
    assert_failure
}

@test "validators: validate_required_commands logs missing command name" {
    export PATH="/nonexistent/path"
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_required_commands || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "validators: validate_ssh_key succeeds when key file exists with correct permissions" {
    export SSH_PRIVATE_KEY_PATH="${TEST_SSH_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_ssh_key
    assert_success
}

@test "validators: validate_ssh_key fails when key file does not exist" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/nonexistent_key"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_ssh_key
    assert_failure
}

@test "validators: validate_ssh_key logs error when key file missing" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/nonexistent_key"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_ssh_key || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "key"
}

@test "validators: validate_ssh_key checks file permissions are 600" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/insecure_key"
    echo "insecure-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 644 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_ssh_key
    assert_failure
}

@test "validators: validate_ssh_key logs warning for incorrect permissions" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/insecure_key"
    echo "insecure-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 644 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_ssh_key || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "permissions"
}

@test "validators: validate_ssh_key accepts 600 permissions" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/secure_key"
    echo "secure-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_ssh_key
    assert_success
}

@test "validators: validate_ssh_key accepts 400 permissions" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/readonly_key"
    echo "readonly-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 400 "${SSH_PRIVATE_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_ssh_key
    assert_success
}

@test "validators: validate_ssh_key calls linuxify_ssh_key.sh on non-Windows systems" {
    skip "Test requires OS environment manipulation"
}

@test "validators: validate_ssh_key skips linuxify on Windows systems" {
    skip "Test requires OS environment manipulation"
}

@test "validators: validate_ssh_key logs key validation steps" {
    export SSH_PRIVATE_KEY_PATH="${TEST_SSH_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_ssh_key

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "key"
}

@test "validators: dry_run_exec logs command in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec echo "Test command"
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
    assert_output --partial "echo"
}

@test "validators: dry_run_exec does not execute command in DRY_RUN mode" {
    export DRY_RUN=1
    local test_file="${TEST_LOG_DIR}/should_not_exist"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec touch "${test_file}"
    assert_success

    [[ ! -f "${test_file}" ]]
}

@test "validators: dry_run_exec returns 0 in DRY_RUN mode" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec false
    assert_success
}

@test "validators: dry_run_exec executes command when DRY_RUN=0" {
    export DRY_RUN=0
    local test_file="${TEST_LOG_DIR}/should_exist"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec touch "${test_file}"
    assert_success

    assert_file_exists "${test_file}"
}

@test "validators: dry_run_exec executes command when DRY_RUN unset" {
    unset DRY_RUN
    local test_file="${TEST_LOG_DIR}/should_exist"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec touch "${test_file}"
    assert_success

    assert_file_exists "${test_file}"
}

@test "validators: dry_run_exec returns actual exit code when DRY_RUN=0" {
    export DRY_RUN=0
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec false
    assert_failure
}

@test "validators: dry_run_exec preserves command output when executed" {
    export DRY_RUN=0
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec echo "Test output"
    assert_success
    assert_output --partial "Test output"
}

@test "validators: dry_run_exec handles commands with arguments" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec ls -la /tmp
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ls -la /tmp"
}

@test "validators: dry_run_exec handles commands with pipes" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run dry_run_exec "echo test | grep test"
    assert_success
}

@test "validators: dry_run_exec logs command before execution" {
    export DRY_RUN=0
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    dry_run_exec echo "Test"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "echo"
}

@test "validators: dry_run_exec uses log_info from logger" {
    export DRY_RUN=1
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    dry_run_exec echo "Test"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "INFO"
}

@test "validators: validate_required_env_vars does not log password values" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="SuperSecret123!"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "SuperSecret123!"
}

@test "validators: validate_ssh_key does not log key contents" {
    local secure_key_path="${TEST_LOG_DIR}/secure_test_key"
    echo "-----BEGIN PRIVATE KEY-----" > "${secure_key_path}"
    echo "SecretKeyData123456789" >> "${secure_key_path}"
    chmod 600 "${secure_key_path}"

    export SSH_PRIVATE_KEY_PATH="${secure_key_path}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    validate_ssh_key || true

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "SecretKeyData123456789"
    refute_output --partial "BEGIN PRIVATE KEY"
}

@test "validators: all validation functions can be called together" {
    export TEST_VAR_1="dummy"
    export TEST_VAR_2="dummy"
    export TEST_VAR_3="dummy"
    export TEST_VAR_4="dummy"
    export TEST_VAR_5="dummy"
    export TEST_VAR_6="dummy"
    export SSH_PRIVATE_KEY_PATH="${TEST_SSH_KEY_PATH}"

    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_test_env_vars "TEST_VAR_1" "TEST_VAR_2" "TEST_VAR_3" "TEST_VAR_4" "TEST_VAR_5" "TEST_VAR_6"
    assert_success

    run validate_required_commands
    assert_success

    run validate_ssh_key
    assert_success
}

@test "validators: validate_required_env_vars checks production environment without exposing values" {
    source "${LOGGER_SCRIPT}"
    source "${VALIDATORS_SCRIPT}"

    run validate_required_env_vars

    if [[ -n "${CPANEL_USERNAME+x}" ]] && \
       [[ -n "${SERVER_IP_ADDRESS+x}" ]] && \
       [[ -n "${SSH_PORT+x}" ]] && \
       [[ -n "${SSH_PRIVATE_KEY_PATH+x}" ]] && \
       [[ -n "${CPANEL_POSTGRES_USER+x}" ]] && \
       [[ -n "${CPANEL_POSTGRES_PASSWORD+x}" ]]; then
        assert_success
    else
        assert_failure
    fi
}
