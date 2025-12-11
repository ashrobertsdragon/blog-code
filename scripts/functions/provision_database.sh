#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${PARENT_DIR}/logger.sh" ]]; then
    source "${PARENT_DIR}/logger.sh"
elif [[ -n "${LOGGER_SCRIPT:-}" ]] && [[ -f "${LOGGER_SCRIPT}" ]]; then
    source "${LOGGER_SCRIPT}"
else
    echo "ERROR: logger.sh not found" >&2
    exit 1
fi

if [[ -f "${PARENT_DIR}/uapi.sh" ]]; then
    source "${PARENT_DIR}/uapi.sh"
elif [[ -n "${UAPI_SCRIPT:-}" ]] && [[ -f "${UAPI_SCRIPT}" ]]; then
    source "${UAPI_SCRIPT}"
else
    log_error "uapi.sh not found"
    exit 1
fi

if [[ -f "${PARENT_DIR}/validators.sh" ]]; then
    source "${PARENT_DIR}/validators.sh"
elif [[ -n "${VALIDATORS_SCRIPT:-}" ]] && [[ -f "${VALIDATORS_SCRIPT}" ]]; then
    source "${VALIDATORS_SCRIPT}"
else
    log_error "validators.sh not found"
    exit 1
fi

provision_database() {
    log_section "Database Provisioning"

    local required_vars=(
        "DATABASE_NAME"
        "CPANEL_POSTGRES_USER"
        "CPANEL_POSTGRES_PASSWORD"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable ${var} is not set"
            return 1
        fi
    done

    local db_name="${DATABASE_NAME}"
    local db_user="${CPANEL_POSTGRES_USER}"
    local db_password="${CPANEL_POSTGRES_PASSWORD}"

    log_info "Checking if database ${db_name} exists"
    if uapi_db_exists "${db_name}"; then
        log_info "Database ${db_name} already exists, skipping creation"
    else
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log_info "[DRY-RUN] Would create database: ${db_name}"
        else
            log_info "Creating database ${db_name}"
            if ! uapi_create_database "${db_name}"; then
                log_error "Failed to create database ${db_name}"
                return 1
            fi
        fi
    fi

    log_info "Checking if database user ${db_user} exists"
    if uapi_db_user_exists "${db_user}"; then
        log_info "Database user ${db_user} already exists, skipping creation"
    else
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log_info "[DRY-RUN] Would create database user: ${db_user}"
        else
            log_info "Creating database user ${db_user}"
            if ! uapi_create_db_user "${db_user}" "${db_password}"; then
                log_error "Failed to create database user ${db_user}"
                return 1
            fi
        fi
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would grant privileges on ${db_name} to ${db_user}"
    else
        log_info "Granting privileges on ${db_name} to ${db_user}"
        if ! uapi_grant_privileges "${db_name}" "${db_user}"; then
            log_error "Failed to grant privileges on ${db_name} to ${db_user}"
            return 1
        fi
    fi

    log_info "Database provisioning completed successfully"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
