#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${UAPI_SH_LOADED:-}" ]]; then
    return 0
fi
readonly UAPI_SH_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/logger.sh" ]]; then
    source "${SCRIPT_DIR}/logger.sh"
elif [[ -n "${LOGGER_SCRIPT:-}" ]] && [[ -f "${LOGGER_SCRIPT}" ]]; then
    source "${LOGGER_SCRIPT}"
else
    echo "ERROR: logger.sh not found" >&2
    exit 1
fi

_uapi_call() {
    local module="$1"
    local function="$2"
    shift 2
    local args=("$@")

    if [[ "${UAPI_MOCK_ENABLED:-false}" == "true" ]]; then
        local fixture_file="${UAPI_MOCK_RESPONSE:-}"

        if [[ -z "${fixture_file}" ]]; then
            log_error "UAPI_MOCK_RESPONSE not set when UAPI_MOCK_ENABLED=true" >&2
            return 1
        fi

        local fixture_path=""
        if [[ -n "${FIXTURES_DIR:-}" ]] && [[ -f "${FIXTURES_DIR}/${fixture_file}" ]]; then
            fixture_path="${FIXTURES_DIR}/${fixture_file}"
        elif [[ -f "tests/fixtures/${fixture_file}" ]]; then
            fixture_path="tests/fixtures/${fixture_file}"
        elif [[ -f "${fixture_file}" ]]; then
            fixture_path="${fixture_file}"
        else
            log_error "Mock fixture not found: ${fixture_file}" >&2
            return 1
        fi

        cat "${fixture_path}"
        return 0
    fi

    log_debug "SSH connecting to ${CPANEL_USERNAME}@${SERVER_IP_ADDRESS}:${SSH_PORT}" >&2

    local ssh_cmd="uapi --output=json ${module} ${function}"
    for arg in "${args[@]}"; do
        ssh_cmd="${ssh_cmd} ${arg}"
    done

    local response
    if ! response=$(ssh -i "${SSH_PRIVATE_KEY_PATH}" -p "${SSH_PORT}" \
        "${CPANEL_USERNAME}@${SERVER_IP_ADDRESS}" \
        "${ssh_cmd}" 2>&1); then
        log_error "SSH command failed: ${response}" >&2
        return 1
    fi

    printf '%s\n' "${response}"
    return 0
}

_parse_uapi_response() {
    local response="$1"
    local status

    status=$(printf '%s\n' "${response}" | jq -r '.result.status' 2>&1)
    if [[ $? -ne 0 ]] || [[ -z "${status}" ]] || [[ "${status}" == "null" ]]; then
        log_error "Failed to parse JSON response: ${status}"
        return 1
    fi

    if [[ "${status}" != "1" ]]; then
        local errors
        errors=$(printf '%s\n' "${response}" | jq -r '.result.errors[]' 2>/dev/null || echo "Unknown error")
        local error_lower
        error_lower=$(echo "${errors}" | tr '[:upper:]' '[:lower:]')
        if [[ "${error_lower}" == *"authentication"* ]] || [[ "${error_lower}" == *"auth"* ]]; then
            log_error "UAPI authentication error: ${errors}"
        else
            log_error "UAPI call failed: ${errors}"
        fi
        return 1
    fi

    return 0
}

_get_uapi_data() {
    local response="$1"
    printf '%s\n' "${response}" | jq '.result.data'
}

uapi_db_exists() {
    local db_name="${1:-}"

    if [[ -z "${db_name}" ]]; then
        log_error "Database name is required"
        return 1
    fi

    log_debug "Checking if database ${db_name} exists"

    local response
    if ! response=$(_uapi_call "Mysql" "list_databases"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    local databases
    databases=$(_get_uapi_data "${response}")

    if printf '%s\n' "${databases}" | jq -e --arg db "${db_name}" '.[] | select(. == $db)' > /dev/null 2>&1; then
        log_debug "Database ${db_name} exists"
        return 0
    else
        log_debug "Database ${db_name} does not exist"
        return 1
    fi
}

uapi_db_user_exists() {
    local user_name="${1:-}"

    if [[ -z "${user_name}" ]]; then
        log_error "User name is required"
        return 1
    fi

    log_debug "Checking if database user ${user_name} exists"

    local response
    if ! response=$(_uapi_call "Mysql" "list_users"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    local users
    users=$(_get_uapi_data "${response}")

    if printf '%s\n' "${users}" | jq -e --arg user "${user_name}" '.[] | select(. == $user)' > /dev/null 2>&1; then
        log_debug "Database user ${user_name} exists"
        return 0
    else
        log_debug "Database user ${user_name} does not exist"
        return 1
    fi
}

uapi_passenger_app_exists() {
    local domain="${1:-}"
    local base_uri="${2:-}"

    if [[ -z "${domain}" ]]; then
        log_error "Domain is required"
        return 1
    fi

    if [[ -z "${base_uri}" ]]; then
        log_error "Base URI is required"
        return 1
    fi

    log_debug "Checking if Passenger app exists for ${domain}${base_uri}"

    local response
    if ! response=$(_uapi_call "PassengerApps" "list_apps"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    local apps
    apps=$(_get_uapi_data "${response}")

    if [[ "${apps}" == "[]" ]] || [[ "${apps}" == "null" ]]; then
        log_debug "Passenger app does not exist for ${domain}${base_uri}"
        return 1
    fi

    local found=0
    local app
    while IFS= read -r app; do
        local app_domain
        local app_uri
        app_domain=$(printf '%s\n' "${app}" | jq -r '.domain')
        app_uri=$(printf '%s\n' "${app}" | jq -r '.base_uri')

        if [[ "${app_domain}" == "${domain}" ]] && [[ "${app_uri}" == "${base_uri}" ]]; then
            found=1
            break
        fi
    done < <(printf '%s\n' "${apps}" | jq -c '.[]')

    if [[ "${found}" -eq 1 ]]; then
        log_debug "Passenger app exists for ${domain}${base_uri}"
        return 0
    else
        log_debug "Passenger app does not exist for ${domain}${base_uri}"
        return 1
    fi
}

uapi_create_database() {
    local db_name="${1:-}"

    if [[ $# -eq 0 ]]; then
        log_error "Database name parameter is required"
        return 1
    fi

    if [[ -z "${db_name}" ]]; then
        log_error "Database name cannot be empty"
        return 1
    fi

    if uapi_db_exists "${db_name}"; then
        log_info "Database ${db_name} already exists, skipping creation"
        return 0
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would create database: ${db_name}"
        return 0
    fi

    log_info "Creating database ${db_name}"

    local response
    if ! response=$(_uapi_call "Mysql" "create_database" "name=${db_name}"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    log_info "Database ${db_name} created successfully"
    return 0
}

uapi_create_db_user() {
    local user_name="${1:-}"
    local password="${2:-}"

    if [[ $# -eq 0 ]]; then
        log_error "Username parameter is required"
        return 1
    fi

    if [[ $# -lt 2 ]]; then
        log_error "Password parameter is required"
        return 1
    fi

    if [[ -z "${user_name}" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi

    if [[ -z "${password}" ]]; then
        log_error "Password cannot be empty"
        return 1
    fi

    if uapi_db_user_exists "${user_name}"; then
        log_info "Database user ${user_name} already exists, skipping creation"
        return 0
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would create database user: ${user_name}"
        return 0
    fi

    log_info "Creating database user ${user_name}"

    local response
    if ! response=$(_uapi_call "Mysql" "create_user" "name=${user_name}" "password=***"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    log_info "Database user ${user_name} created successfully"
    return 0
}

uapi_grant_privileges() {
    local db_name="${1:-}"
    local user_name="${2:-}"

    if [[ $# -eq 0 ]]; then
        log_error "Database name parameter is required"
        return 1
    fi

    if [[ $# -lt 2 ]]; then
        log_error "User name parameter is required"
        return 1
    fi

    if [[ -z "${db_name}" ]]; then
        log_error "Database name cannot be empty"
        return 1
    fi

    if [[ -z "${user_name}" ]]; then
        log_error "User name cannot be empty"
        return 1
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would grant privileges on ${db_name} to ${user_name}"
        return 0
    fi

    log_info "Granting privileges on ${db_name} to ${user_name}"

    local response
    if ! response=$(_uapi_call "Mysql" "set_privileges_on_database" \
        "user=${user_name}" "database=${db_name}" "privileges=ALL PRIVILEGES"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    log_info "Privileges granted on ${db_name} to ${user_name} successfully"
    return 0
}

uapi_register_passenger_app() {
    local domain="${1:-}"
    local base_uri="${2:-}"
    local app_path="${3:-}"

    if [[ $# -eq 0 ]]; then
        log_error "Domain parameter is required"
        return 1
    fi

    if [[ $# -lt 2 ]]; then
        log_error "Base URI parameter is required"
        return 1
    fi

    if [[ $# -lt 3 ]]; then
        log_error "App path parameter is required"
        return 1
    fi

    if [[ -z "${domain}" ]]; then
        log_error "Domain cannot be empty"
        return 1
    fi

    if [[ -z "${base_uri}" ]]; then
        log_error "Base URI cannot be empty"
        return 1
    fi

    if [[ -z "${app_path}" ]]; then
        log_error "App path cannot be empty"
        return 1
    fi

    if uapi_passenger_app_exists "${domain}" "${base_uri}"; then
        log_info "Passenger app for ${domain}${base_uri} already registered, skipping"
        return 0
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would register Passenger app for ${domain}${base_uri}"
        return 0
    fi

    log_info "Registering Passenger app for ${domain}${base_uri}"

    local response
    if ! response=$(_uapi_call "PassengerApps" "register_application" \
        "domain=${domain}" "base_uri=${base_uri}" "app_root=${app_path}"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    log_info "Passenger app registered for ${domain}${base_uri} successfully"
    return 0
}

uapi_restart_passenger_app() {
    local domain="${1:-}"
    local base_uri="${2:-}"

    if [[ $# -eq 0 ]]; then
        log_error "Domain parameter is required"
        return 1
    fi

    if [[ $# -lt 2 ]]; then
        log_error "Base URI parameter is required"
        return 1
    fi

    if [[ -z "${domain}" ]]; then
        log_error "Domain cannot be empty"
        return 1
    fi

    if [[ -z "${base_uri}" ]]; then
        log_error "Base URI cannot be empty"
        return 1
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would restart Passenger app for ${domain}${base_uri}"
        return 0
    fi

    log_info "Restarting Passenger app for ${domain}${base_uri}"

    local response
    if ! response=$(_uapi_call "PassengerApps" "restart_application" \
        "domain=${domain}" "base_uri=${base_uri}"); then
        return 1
    fi

    if ! _parse_uapi_response "${response}"; then
        return 1
    fi

    log_info "Passenger app restarted for ${domain}${base_uri} successfully"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
