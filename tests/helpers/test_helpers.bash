#!/usr/bin/env bash

setup_test_env() {
    export TEST_MODE=true
    export BATS_TEST_DIRNAME="${BATS_TEST_DIRNAME:-$(pwd)}"
    export FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"
}

teardown_test_env() {
    unset TEST_MODE
    unset BATS_TEST_DIRNAME
    unset FIXTURES_DIR
}

mock_ssh() {
    export SSH_MOCK_ENABLED=true
    export SSH_MOCK_OUTPUT="${1:-success}"
}

unmock_ssh() {
    unset SSH_MOCK_ENABLED
    unset SSH_MOCK_OUTPUT
}

mock_uapi() {
    export UAPI_MOCK_ENABLED=true
    export UAPI_MOCK_RESPONSE="${1:-success}"
}

unmock_uapi() {
    unset UAPI_MOCK_ENABLED
    unset UAPI_MOCK_RESPONSE
}

create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d)
    echo "${temp_dir}"
}

cleanup_temp_dir() {
    local temp_dir="${1}"
    if [[ -d "${temp_dir}" ]]; then
        rm -rf "${temp_dir}"
    fi
}

assert_file_exists() {
    local file="${1}"
    [[ -f "${file}" ]]
}

assert_dir_exists() {
    local dir="${1}"
    [[ -d "${dir}" ]]
}

load_fixture() {
    local fixture_name="${1}"
    local fixture_path="${FIXTURES_DIR}/${fixture_name}"

    if [[ -f "${fixture_path}" ]]; then
        cat "${fixture_path}"
    else
        echo "ERROR: Fixture ${fixture_name} not found" >&2
        return 1
    fi
}
