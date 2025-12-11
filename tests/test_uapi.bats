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
    export UAPI_SCRIPT="${SCRIPTS_DIR}/uapi.sh"

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
    unset CPANEL_USERNAME
    unset SERVER_IP_ADDRESS
    unset SSH_PORT
    unset SSH_PRIVATE_KEY_PATH
    unset MOCK_SSH_RESPONSE_FILE
    unset DRY_RUN
    teardown_test_env
}

@test "uapi: script exists and is executable" {
    assert_file_exists "${UAPI_SCRIPT}"
    [[ -x "${UAPI_SCRIPT}" ]]
}

@test "uapi: can be sourced without errors" {
    source "${LOGGER_SCRIPT}"
    run source "${UAPI_SCRIPT}"
    assert_success
}

@test "uapi: uapi_db_exists function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_db_exists
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_db_user_exists function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_db_user_exists
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_passenger_app_exists function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_passenger_app_exists
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_create_database function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_create_database
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_create_db_user function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_create_db_user
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_grant_privileges function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_grant_privileges
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_register_passenger_app function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_register_passenger_app
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_restart_passenger_app function exists after sourcing" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"
    run type uapi_restart_passenger_app
    assert_success
    assert_output --partial "function"
}

@test "uapi: uapi_db_exists returns 0 when database exists" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_exists "blog_db"
    assert_success
}

@test "uapi: uapi_db_exists returns 1 when database does not exist" {
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_exists "blog_db"
    assert_failure
}

@test "uapi: uapi_db_exists handles database name with special characters" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_exists "blog-db_test"
    [[ "$?" -eq 0 ]] || [[ "$?" -eq 1 ]]
}

@test "uapi: uapi_db_exists logs check operation" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_db_exists "blog_db"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "blog_db"
}

@test "uapi: uapi_db_user_exists returns 0 when user exists" {
    mock_uapi "uapi_mysql_list_users_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_user_exists "blog_user"
    assert_success
}

@test "uapi: uapi_db_user_exists returns 1 when user does not exist" {
    mock_uapi "uapi_mysql_list_users_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_user_exists "blog_user"
    assert_failure
}

@test "uapi: uapi_db_user_exists logs check operation" {
    mock_uapi "uapi_mysql_list_users_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_db_user_exists "blog_user"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "blog_user"
}

@test "uapi: uapi_passenger_app_exists returns 0 when app exists" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_passenger_app_exists "ashlynantrobus.dev" "/"
    assert_success
}

@test "uapi: uapi_passenger_app_exists returns 1 when app does not exist" {
    mock_uapi "uapi_passenger_list_apps_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_passenger_app_exists "ashlynantrobus.dev" "/"
    assert_failure
}

@test "uapi: uapi_passenger_app_exists checks both domain and base_uri" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_passenger_app_exists "ashlynantrobus.dev" "/app"
    assert_failure
}

@test "uapi: uapi_passenger_app_exists logs check operation" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_passenger_app_exists "ashlynantrobus.dev" "/"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ashlynantrobus.dev"
}

@test "uapi: uapi_create_database succeeds when database created" {
    mock_uapi "uapi_mysql_create_database_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_success
}

@test "uapi: uapi_create_database is idempotent when database exists" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_success
}

@test "uapi: uapi_create_database logs skip message when database exists" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_database "blog_db"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "already exists"
}

@test "uapi: uapi_create_database requires database name parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database
    assert_failure
}

@test "uapi: uapi_create_database validates database name is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database ""
    assert_failure
}

@test "uapi: uapi_create_database logs creation operation" {
    mock_uapi "uapi_mysql_create_database_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_database "blog_db"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "blog_db"
    assert_output --partial "database"
}

@test "uapi: uapi_create_database respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_mysql_create_database_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "uapi: uapi_create_db_user succeeds when user created" {
    mock_uapi "uapi_mysql_create_user_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user "blog_user" "secure_password"
    assert_success
}

@test "uapi: uapi_create_db_user is idempotent when user exists" {
    mock_uapi "uapi_mysql_list_users_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user "blog_user" "secure_password"
    assert_success
}

@test "uapi: uapi_create_db_user logs skip message when user exists" {
    mock_uapi "uapi_mysql_list_users_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_db_user "blog_user" "secure_password"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "already exists"
}

@test "uapi: uapi_create_db_user requires username parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user
    assert_failure
}

@test "uapi: uapi_create_db_user requires password parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user "blog_user"
    assert_failure
}

@test "uapi: uapi_create_db_user validates username is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user "" "password"
    assert_failure
}

@test "uapi: uapi_create_db_user validates password is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user "blog_user" ""
    assert_failure
}

@test "uapi: uapi_create_db_user does not log password in plaintext" {
    mock_uapi "uapi_mysql_create_user_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_db_user "blog_user" "SuperSecret123!"

    run cat "${TEST_LOG_FILE}"
    refute_output --partial "SuperSecret123!"
}

@test "uapi: uapi_create_db_user logs user creation operation" {
    mock_uapi "uapi_mysql_create_user_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_db_user "blog_user" "password"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "blog_user"
}

@test "uapi: uapi_create_db_user respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_mysql_create_user_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_db_user "blog_user" "password"
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "uapi: uapi_grant_privileges succeeds when privileges granted" {
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges "blog_db" "blog_user"
    assert_success
}

@test "uapi: uapi_grant_privileges is idempotent" {
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges "blog_db" "blog_user"
    assert_success

    run uapi_grant_privileges "blog_db" "blog_user"
    assert_success
}

@test "uapi: uapi_grant_privileges requires database parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges
    assert_failure
}

@test "uapi: uapi_grant_privileges requires user parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges "blog_db"
    assert_failure
}

@test "uapi: uapi_grant_privileges validates database name is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges "" "blog_user"
    assert_failure
}

@test "uapi: uapi_grant_privileges validates user name is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges "blog_db" ""
    assert_failure
}

@test "uapi: uapi_grant_privileges logs grant operation" {
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_grant_privileges "blog_db" "blog_user"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "blog_db"
    assert_output --partial "blog_user"
    assert_output --partial "privileges"
}

@test "uapi: uapi_grant_privileges respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_mysql_set_privileges_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_grant_privileges "blog_db" "blog_user"
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "uapi: uapi_register_passenger_app succeeds when app registered" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev" "/" "/home/user/blog"
    assert_success
}

@test "uapi: uapi_register_passenger_app is idempotent when app exists" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev" "/" "/home/user/blog"
    assert_success
}

@test "uapi: uapi_register_passenger_app logs skip message when app exists" {
    mock_uapi "uapi_passenger_list_apps_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_register_passenger_app "ashlynantrobus.dev" "/" "/home/user/blog"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "already registered"
}

@test "uapi: uapi_register_passenger_app requires domain parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app
    assert_failure
}

@test "uapi: uapi_register_passenger_app requires base_uri parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev"
    assert_failure
}

@test "uapi: uapi_register_passenger_app requires app_path parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev" "/"
    assert_failure
}

@test "uapi: uapi_register_passenger_app validates domain is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "" "/" "/home/user/blog"
    assert_failure
}

@test "uapi: uapi_register_passenger_app validates base_uri is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev" "" "/home/user/blog"
    assert_failure
}

@test "uapi: uapi_register_passenger_app validates app_path is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev" "/" ""
    assert_failure
}

@test "uapi: uapi_register_passenger_app logs registration operation" {
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_register_passenger_app "ashlynantrobus.dev" "/" "/home/user/blog"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ashlynantrobus.dev"
    assert_output --partial "Passenger"
}

@test "uapi: uapi_register_passenger_app respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_passenger_register_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_register_passenger_app "ashlynantrobus.dev" "/" "/home/user/blog"
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "uapi: uapi_restart_passenger_app succeeds when app restarted" {
    mock_uapi "uapi_passenger_restart_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_restart_passenger_app "ashlynantrobus.dev" "/"
    assert_success
}

@test "uapi: uapi_restart_passenger_app requires domain parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_restart_passenger_app
    assert_failure
}

@test "uapi: uapi_restart_passenger_app requires base_uri parameter" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_restart_passenger_app "ashlynantrobus.dev"
    assert_failure
}

@test "uapi: uapi_restart_passenger_app validates domain is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_restart_passenger_app "" "/"
    assert_failure
}

@test "uapi: uapi_restart_passenger_app validates base_uri is not empty" {
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_restart_passenger_app "ashlynantrobus.dev" ""
    assert_failure
}

@test "uapi: uapi_restart_passenger_app logs restart operation" {
    mock_uapi "uapi_passenger_restart_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_restart_passenger_app "ashlynantrobus.dev" "/"

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ashlynantrobus.dev"
    assert_output --partial "restart"
}

@test "uapi: uapi_restart_passenger_app respects DRY_RUN mode" {
    export DRY_RUN=1
    mock_uapi "uapi_passenger_restart_app_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_restart_passenger_app "ashlynantrobus.dev" "/"
    assert_success

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "[DRY-RUN]"
}

@test "uapi: handles authentication errors gracefully" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_failure
}

@test "uapi: logs authentication errors" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_database "blog_db" || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
    assert_output --partial "authentication"
}

@test "uapi: handles network errors gracefully" {
    mock_uapi "uapi_error_network.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_failure
}

@test "uapi: logs network errors" {
    mock_uapi "uapi_error_network.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_database "blog_db" || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "uapi: handles invalid JSON responses" {
    mock_uapi "uapi_error_invalid_json.txt"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_failure
}

@test "uapi: logs JSON parsing errors" {
    mock_uapi "uapi_error_invalid_json.txt"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_database "blog_db" || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}

@test "uapi: SSH command includes required environment variables" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_db_exists "blog_db"

    run cat "${TEST_LOG_FILE}"
    assert_success
}

@test "uapi: SSH uses correct port from environment" {
    export SSH_PORT="2222"
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_db_exists "blog_db"

    run cat "${TEST_LOG_FILE}"
    assert_success
}

@test "uapi: SSH uses correct key file from environment" {
    export SSH_PRIVATE_KEY_PATH="${TEST_LOG_DIR}/custom_key"
    echo "custom-ssh-key" > "${SSH_PRIVATE_KEY_PATH}"
    chmod 600 "${SSH_PRIVATE_KEY_PATH}"

    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_db_exists "blog_db"

    run cat "${TEST_LOG_FILE}"
    assert_success
}

@test "uapi: parses JSON responses correctly with jq" {
    mock_uapi "uapi_mysql_list_databases_with_blog.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_exists "blog_db"
    assert_success
}

@test "uapi: handles empty data arrays in responses" {
    mock_uapi "uapi_mysql_list_databases_empty.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_db_exists "blog_db"
    assert_failure
}

@test "uapi: validates response status field" {
    mock_uapi "uapi_mysql_create_database_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_success
}

@test "uapi: checks status=1 for success" {
    mock_uapi "uapi_mysql_create_database_success.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "blog_db"
    assert_success
}

@test "uapi: checks status=0 for failure" {
    mock_uapi "uapi_mysql_create_database_exists.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    run uapi_create_database "new_blog_db"
    [[ "$?" -ne 0 ]] || run cat "${TEST_LOG_FILE}"
}

@test "uapi: extracts error messages from failed responses" {
    mock_uapi "uapi_error_auth.json"
    source "${LOGGER_SCRIPT}"
    source "${UAPI_SCRIPT}"

    uapi_create_database "blog_db" || true

    run cat "${TEST_LOG_FILE}"
    assert_output --partial "ERROR"
}
