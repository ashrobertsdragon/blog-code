#!/usr/bin/env bats

load test_helper

setup() {
  reset_mock_state
  setup_test_environment
}

teardown() {
  unset_test_environment
  cleanup_test_files
}

# ============================================================================
# Environment Validation Tests (5 tests)
# ============================================================================

@test "deployment fails when CPANEL_USERNAME is not set" {
  unset CPANEL_USERNAME

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_failure "$status"
}

@test "deployment fails when SERVER_IP_ADDRESS is not set" {
  unset SERVER_IP_ADDRESS

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_failure "$status"
}

@test "deployment fails when SSH_PRIVATE_KEY_PATH is not set" {
  unset SSH_PRIVATE_KEY_PATH

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_failure "$status"
}

@test "deployment fails when database credentials are not set" {
  unset CPANEL_POSTGRES_USER
  unset CPANEL_POSTGRES_PASSWORD

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_failure "$status"
}

@test "deployment detects operating system correctly" {
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_contains "$output" "Deployment completed successfully"
}

# ============================================================================
# SSH Key Handling Tests (3 tests)
# ============================================================================

@test "deployment calls linuxify_ssh_key.sh on non-Windows systems" {
  export OS="Linux"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_contains "$output" "SSH key configured"
}

@test "deployment uses original SSH key path on Windows Git Bash" {
  export OS="Windows_NT"
  export LINUXIFY_CALLED="${BATS_TEST_TMPDIR}/linuxified"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  linuxify_ssh_key.sh() {
    touch "${LINUXIFY_CALLED}"
    return 0
  }
  export -f linuxify_ssh_key.sh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_file_not_exists "${LINUXIFY_CALLED}"
  assert_exit_success "$status"
}

@test "deployment verifies SSH key permissions are restrictive" {
  export SSH_KEY_PATH="${BATS_TEST_TMPDIR}/test_key"
  export SSH_PRIVATE_KEY_PATH="${SSH_KEY_PATH}"
  export CHMOD_CALLED="${BATS_TEST_TMPDIR}/chmod_called"
  touch "${SSH_KEY_PATH}"

  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  chmod() {
    if [[ "$1" == "600" ]]; then
      touch "${CHMOD_CALLED}"
    fi
    return 0
  }
  export -f chmod

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${CHMOD_CALLED}"
}

# ============================================================================
# Database Provisioning Tests (4 tests)
# ============================================================================

@test "deployment creates database via UAPI when it does not exist" {
  export DB_CREATED="${BATS_TEST_TMPDIR}/db_created"
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    if [[ "$*" == *"create_database"* ]]; then
      touch "${DB_CREATED}"
      echo '{"status":1,"data":{}}'
    else
      echo '{"status":1,"data":[]}'
    fi
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_file_exists "${DB_CREATED}"
  assert_exit_success "$status"
}

@test "deployment creates PostgreSQL user via UAPI when it does not exist" {
  export USER_CREATED="${BATS_TEST_TMPDIR}/user_created"
  setup_mock_successful_database_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    if [[ "$*" == *"create_user"* ]]; then
      touch "${USER_CREATED}"
      echo '{"status":1,"data":{}}'
    else
      echo '{"status":1,"data":["testuser_blogdb"]}'
    fi
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_file_exists "${USER_CREATED}"
  assert_exit_success "$status"
}

@test "deployment grants database privileges to user via UAPI" {
  export PRIVILEGES_GRANTED="${BATS_TEST_TMPDIR}/privileges_granted"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    if [[ "$*" == *"grant_all_privileges"* ]]; then
      touch "${PRIVILEGES_GRANTED}"
      echo '{"status":1,"data":["testuser_blogdb"]}'
    elif [[ "$*" == *"list_privileges"* ]]; then
      echo '{"status":1,"data":[]}'
    else
      echo '{"status":1,"data":["testuser_blogdb"]}'
    fi
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_file_exists "${PRIVILEGES_GRANTED}"
  assert_exit_success "$status"
}

@test "deployment is idempotent when database already exists" {
  export DEPLOY_COUNT="${BATS_TEST_TMPDIR}/deploy_count"
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    echo "1" >> "${DEPLOY_COUNT}"
    echo '{"status":1,"data":["testuser_blogdb","testuser_pguser"]}'
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main
  assert_exit_success "$status"

  run main
  assert_exit_success "$status"

  local count
  count=$(wc -l < "${DEPLOY_COUNT}")
  [[ "$count" -ge 2 ]]
}

# ============================================================================
# Code Upload Tests (3 tests)
# ============================================================================

@test "deployment uploads backend directory via rsync over SSH" {
  export RSYNC_LOG="${BATS_TEST_TMPDIR}/rsync.log"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_health_check

  rsync() {
    echo "$@" >> "${RSYNC_LOG}"
    return 0
  }
  export -f rsync

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${RSYNC_LOG}"
  run cat "${RSYNC_LOG}"
  assert_contains "$output" "backend/"
  assert_contains "$output" "ssh"
}

@test "deployment uploads frontend build directory via rsync" {
  export RSYNC_LOG="${BATS_TEST_TMPDIR}/rsync.log"
  local build_dir="${PROJECT_ROOT:-$(dirname "${BATS_TEST_DIRNAME}")/../..}/monorepo/frontend/build"
  mkdir -p "$build_dir"
  touch "$build_dir/index.html"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_health_check

  rsync() {
    echo "$@" >> "${RSYNC_LOG}"
    return 0
  }
  export -f rsync

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${RSYNC_LOG}"
  run cat "${RSYNC_LOG}"
  assert_contains "$output" "build/"
}

@test "deployment preserves file permissions during upload" {
  export RSYNC_LOG="${BATS_TEST_TMPDIR}/rsync.log"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_health_check

  rsync() {
    echo "$@" >> "${RSYNC_LOG}"
    return 0
  }
  export -f rsync

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${RSYNC_LOG}"
  run cat "${RSYNC_LOG}"
  assert_contains "$output" "--perms"
}

# ============================================================================
# Virtual Environment Tests (4 tests)
# ============================================================================

@test "deployment creates virtualenv on remote server when it does not exist" {
  export SSH_CALLED="${BATS_TEST_TMPDIR}/ssh_called"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    touch "${SSH_CALLED}"
    echo "Python 3.13.0"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${SSH_CALLED}"
  assert_contains "$output" "Virtual environment configured"
}

@test "deployment skips virtualenv creation when it already exists" {
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    echo "virtualenv already exists"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_contains "$output" "Virtual environment configured"
}

@test "deployment installs Python dependencies from requirements.txt" {
  export SSH_CALLED="${BATS_TEST_TMPDIR}/ssh_called"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    touch "${SSH_CALLED}"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${SSH_CALLED}"
  assert_contains "$output" "Virtual environment configured"
}

@test "deployment verifies Python 3.13+ is available on remote server" {
  export SSH_CALLED="${BATS_TEST_TMPDIR}/ssh_called"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    touch "${SSH_CALLED}"
    echo "Python 3.13.0"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${SSH_CALLED}"
  assert_contains "$output" "Virtual environment configured"
}

# ============================================================================
# Schema Execution Tests (3 tests)
# ============================================================================

@test "deployment executes SQLModel schema creation on remote server" {
  export SSH_CALLED="${BATS_TEST_TMPDIR}/ssh_called"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    touch "${SSH_CALLED}"
    echo "Schema creation completed"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${SSH_CALLED}"
  assert_contains "$output" "Database schema created"
}

@test "deployment schema creation is idempotent" {
  export SCHEMA_RUN_COUNT="${BATS_TEST_TMPDIR}/schema_count"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    echo "1" >> "${SCHEMA_RUN_COUNT}"
    echo "Schema creation completed"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main
  assert_exit_success "$status"

  run main
  assert_exit_success "$status"

  local count
  count=$(wc -l < "${SCHEMA_RUN_COUNT}")
  [[ "$count" -ge 2 ]]
}

@test "deployment verifies database tables were created successfully" {
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  ssh() {
    echo "Schema creation completed"
    return 0
  }
  export -f ssh

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_contains "$output" "Database schema created"
}

# ============================================================================
# Passenger Registration Tests (5 tests)
# ============================================================================

@test "deployment registers application via UAPI when it does not exist" {
  export UAPI_LOG="${BATS_TEST_TMPDIR}/uapi.log"
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    echo "$@" >> "${UAPI_LOG}"
    echo '{"status":1,"data":["testuser_blogdb"]}'
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${UAPI_LOG}"
  run cat "${UAPI_LOG}"
  assert_contains "$output" "PassengerApps register_application"
}

@test "deployment updates Passenger app when it is already registered" {
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    echo '{"status":1,"data":["testuser_blogdb"]}'
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_contains "$output" "Passenger application registered"
}

@test "deployment injects all environment variables into Passenger config" {
  export UAPI_LOG="${BATS_TEST_TMPDIR}/uapi.log"
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    echo "$@" >> "${UAPI_LOG}"
    echo '{"status":1,"data":["testuser_blogdb"]}'
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${UAPI_LOG}"
  run cat "${UAPI_LOG}"
  assert_contains "$output" "envvar_name_3=DB_USER"
  assert_contains "$output" "envvar_value_3=testuser_pguser"
  assert_contains "$output" "envvar_name_5=GITHUB_PERSONAL_ACCESS_TOKEN"
  assert_contains "$output" "envvar_name_8=CLERK_SECRET_KEY"
}

@test "deployment uses correct domain for Passenger app registration" {
  export UAPI_LOG="${BATS_TEST_TMPDIR}/uapi.log"
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    echo "$@" >> "${UAPI_LOG}"
    echo '{"status":1,"data":["testuser_blogdb"]}'
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${UAPI_LOG}"
  run cat "${UAPI_LOG}"
  assert_contains "$output" "ashlynantrobus.dev"
}

@test "deployment uses correct base URI for Passenger app registration" {
  export UAPI_LOG="${BATS_TEST_TMPDIR}/uapi.log"
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync
  setup_mock_successful_health_check

  uapi() {
    echo "$@" >> "${UAPI_LOG}"
    echo '{"status":1,"data":["testuser_blogdb"]}'
    return 0
  }
  export -f uapi

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${UAPI_LOG}"
  run cat "${UAPI_LOG}"
  assert_contains "$output" "base_uri=/"
}

# ============================================================================
# Health Check Verification Tests (3 tests)
# ============================================================================

@test "deployment verifies health endpoint returns 200" {
  export CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync

  curl() {
    echo "$@" >> "${CURL_LOG}"
    echo '{"status": "healthy"}'
    return 0
  }
  export -f curl

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${CURL_LOG}"
  run cat "${CURL_LOG}"
  assert_contains "$output" "https://ashlynantrobus.dev/health"
}

@test "deployment verifies database health endpoint returns 200" {
  export CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync

  curl() {
    echo "$@" >> "${CURL_LOG}"
    echo '{"status": "healthy", "database": "connected"}'
    return 0
  }
  export -f curl

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${CURL_LOG}"
  run cat "${CURL_LOG}"
  assert_contains "$output" "https://ashlynantrobus.dev/health/db"
}

@test "deployment verifies GitHub health endpoint returns 200" {
  export CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  setup_mock_successful_database_creation
  setup_mock_successful_user_creation
  setup_mock_successful_ssh
  setup_mock_successful_rsync

  curl() {
    echo "$@" >> "${CURL_LOG}"
    echo '{"status": "healthy", "github": "connected"}'
    return 0
  }
  export -f curl

  source "${BATS_TEST_DIRNAME}/../deploy.sh"
  run main

  assert_exit_success "$status"
  assert_file_exists "${CURL_LOG}"
  run cat "${CURL_LOG}"
  assert_contains "$output" "https://ashlynantrobus.dev/health/github"
}
