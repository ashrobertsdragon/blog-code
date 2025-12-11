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

if [[ -f "${PARENT_DIR}/validators.sh" ]]; then
    source "${PARENT_DIR}/validators.sh"
elif [[ -n "${VALIDATORS_SCRIPT:-}" ]] && [[ -f "${VALIDATORS_SCRIPT}" ]]; then
    source "${VALIDATORS_SCRIPT}"
else
    log_error "validators.sh not found"
    exit 1
fi

run_schema() {
    log_section "Database Schema Initialization"

    local required_vars=(
        "CPANEL_USERNAME"
        "SERVER_IP_ADDRESS"
        "SSH_PORT"
        "SSH_PRIVATE_KEY_PATH"
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

    local db_host="${DB_HOST:-localhost}"
    local db_port="${DB_PORT:-5432}"
    local remote_app_path="${REMOTE_APP_PATH:-/home/${CPANEL_USERNAME}/blog}"
    local backend_path="${remote_app_path}/backend"
    local venv_path="${remote_app_path}/venv"

    log_info "Database: ${DATABASE_NAME}"
    log_info "User: ${CPANEL_POSTGRES_USER}"
    log_info "Host: ${db_host}"
    log_info "Port: ${db_port}"

    local connection_string="postgresql://${CPANEL_POSTGRES_USER}:***@${db_host}:${db_port}/${DATABASE_NAME}"
    log_info "Connection string: ${connection_string}"

    local database_url="postgresql://${CPANEL_POSTGRES_USER}:${CPANEL_POSTGRES_PASSWORD}@${db_host}:${db_port}/${DATABASE_NAME}"

    local ssh_cmd="ssh -i \"${SSH_PRIVATE_KEY_PATH}\" -p ${SSH_PORT} ${CPANEL_USERNAME}@${SERVER_IP_ADDRESS}"

    log_info "Initializing database schema"
    log_info "Running database initialization Python script"
    log_info "cd ${backend_path} && source ${venv_path}/bin/activate && DATABASE_URL=${connection_string} uv run python -c 'from src.backend.infrastructure.persistence.database import init_db; init_db()'"

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute database initialization script"
    else
        if [[ "${MOCK_SCHEMA_FAILURE:-0}" == "1" ]] || [[ "${MOCK_DB_CONNECTION_FAILURE:-0}" == "1" ]]; then
            log_error "Failed to initialize database schema"
            return 1
        fi

        if [[ "${TEST_MODE:-false}" != "true" ]]; then
            if ! ${ssh_cmd} "cd \"${backend_path}\" && source \"${venv_path}/bin/activate\" && export DATABASE_URL=\"${database_url}\" && uv run python -c 'from src.backend.infrastructure.persistence.database import init_db; init_db()'" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                log_error "Failed to initialize database schema"
                return 1
            fi
        else
            log_info "Test mode: Simulating database schema initialization using SQLModel metadata create_all"
            log_info "Creating tables if they do not exist"
        fi
    fi

    log_info "Database schema initialized successfully"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
