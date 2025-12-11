#!/usr/bin/env bats

setup() {
    TESTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    LIBS_DIR="${TESTS_DIR}/libs"

    load "${LIBS_DIR}/bats-support/load"
    load "${LIBS_DIR}/bats-assert/load"
    load helpers/test_helpers.bash

    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "bats-core is installed and working" {
    run echo "Hello, BATS!"
    assert_success
    assert_output "Hello, BATS!"
}

@test "bats-assert library is loaded" {
    run true
    assert_success

    run false
    assert_failure
}

@test "test helpers are available" {
    run setup_test_env
    assert_success

    [[ "${TEST_MODE}" == "true" ]]
}

@test "test fixtures directory exists" {
    assert_dir_exists "${FIXTURES_DIR}"
}

@test "can load SSH success fixture" {
    run load_fixture "ssh_success.txt"
    assert_success
    assert_output --partial "Command executed successfully"
}

@test "can load UAPI success fixture" {
    run load_fixture "uapi_success.json"
    assert_success
    assert_output --partial '"status": 1'
}

@test "temp directory utilities work" {
    local temp_dir
    temp_dir=$(create_temp_dir)

    assert_dir_exists "${temp_dir}"

    cleanup_temp_dir "${temp_dir}"

    [[ ! -d "${temp_dir}" ]]
}

@test "SSH mocking utilities work" {
    mock_ssh "test_output"
    [[ "${SSH_MOCK_ENABLED}" == "true" ]]
    [[ "${SSH_MOCK_OUTPUT}" == "test_output" ]]

    unmock_ssh
    [[ -z "${SSH_MOCK_ENABLED:-}" ]]
}

@test "UAPI mocking utilities work" {
    mock_uapi "test_response"
    [[ "${UAPI_MOCK_ENABLED}" == "true" ]]
    [[ "${UAPI_MOCK_RESPONSE}" == "test_response" ]]

    unmock_uapi
    [[ -z "${UAPI_MOCK_ENABLED:-}" ]]
}
