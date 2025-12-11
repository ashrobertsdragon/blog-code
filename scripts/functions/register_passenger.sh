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

register_passenger() {
    log_section "Passenger App Registration"

    local required_vars=(
        "DOMAIN"
        "BASE_URI"
        "REMOTE_APP_PATH"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable ${var} is not set"
            return 1
        fi
    done

    local domain="${DOMAIN}"
    local base_uri="${BASE_URI}"
    local app_path="${REMOTE_APP_PATH}/backend"

    log_info "Domain: ${domain}"
    log_info "Base URI: ${base_uri}"
    log_info "App Path: ${app_path}"

    log_info "Environment variables to inject:"
    log_info "  DATABASE_NAME: ${DATABASE_NAME:-}"
    log_info "  CPANEL_POSTGRES_USER: ${CPANEL_POSTGRES_USER:-}"
    log_info "  CPANEL_POSTGRES_PASSWORD: ***"
    log_info "  DB_HOST: ${DB_HOST:-localhost}"
    log_info "  DB_PORT: ${DB_PORT:-5432}"

    log_info "Checking if Passenger app already registered"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would check Passenger app existence"
        log_info "[DRY-RUN] Would register or restart Passenger app"
        return 0
    fi

    local app_exists=0
    if uapi_passenger_app_exists "${domain}" "${base_uri}"; then
        app_exists=1
    fi

    if [[ ${app_exists} -eq 1 ]]; then
        log_info "Passenger app for ${domain}${base_uri} is already registered, skipping registration"
        log_info "Restarting existing Passenger app"

        if [[ "${MOCK_RESTART_FAILURE:-0}" == "1" ]]; then
            log_error "Failed to restart Passenger app"
            return 1
        fi

        if ! uapi_restart_passenger_app "${domain}" "${base_uri}"; then
            log_error "Failed to restart Passenger app"
            return 1
        fi

        log_info "Passenger app restarted successfully for ${domain}${base_uri}"
        log_info "Restart complete"
    else
        log_info "Passenger app not registered, registering new Python application"
        log_info "Application type: python"

        if ! uapi_register_passenger_app "${domain}" "${base_uri}" "${app_path}"; then
            log_error "Failed to register Passenger app"
            return 1
        fi

        log_info "Registration complete successfully"
    fi

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
