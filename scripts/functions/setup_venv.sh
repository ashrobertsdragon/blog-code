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

setup_venv() {
    log_section "Virtual Environment Setup"

    local required_vars=(
        "CPANEL_USERNAME"
        "SERVER_IP_ADDRESS"
        "SSH_PORT"
        "SSH_PRIVATE_KEY_PATH"
        "REMOTE_APP_PATH"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable ${var} is not set"
            return 1
        fi
    done

    local venv_path="${VENV_PATH:-${REMOTE_APP_PATH}/venv}"
    local backend_path="${BACKEND_PATH:-${REMOTE_APP_PATH}/backend}"

    local ssh_cmd="ssh -i \"${SSH_PRIVATE_KEY_PATH}\" -p ${SSH_PORT} ${CPANEL_USERNAME}@${SERVER_IP_ADDRESS}"

    log_info "Checking if virtualenv exists at ${venv_path}"
    log_info "ssh ${CPANEL_USERNAME}@${SERVER_IP_ADDRESS} -p ${SSH_PORT} -i ${SSH_PRIVATE_KEY_PATH}"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would check virtualenv existence via ssh"
    else
        local venv_exists=0
        if [[ "${TEST_MODE:-false}" == "true" ]]; then
            if [[ "${MOCK_VENV_EXISTS:-0}" == "1" ]]; then
                venv_exists=1
            elif [[ "${MOCK_VENV_MISSING:-0}" == "1" ]]; then
                venv_exists=0
            else
                venv_exists=1
            fi
        else
            if ${ssh_cmd} "[ -d \"${venv_path}\" ]" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                venv_exists=1
            fi
        fi

        if [[ ${venv_exists} -eq 1 ]]; then
            log_info "Virtualenv already exists at ${venv_path}, skipping virtualenv creation"
        else
            log_info "Creating virtualenv at ${venv_path}"
            log_info "python3 -m venv ${venv_path}"
            if [[ "${MOCK_VENV_CREATION_FAILURE:-0}" == "1" ]]; then
                log_error "Failed to create virtualenv"
                return 1
            fi
            if [[ "${TEST_MODE:-false}" != "true" ]]; then
                if ! ${ssh_cmd} "python3 -m venv \"${venv_path}\"" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                    log_error "Failed to create virtualenv"
                    return 1
                fi
            fi
        fi
    fi

    log_info "Checking if uv is installed"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would check uv installation via ssh"
    else
        local uv_exists=0
        if [[ "${TEST_MODE:-false}" == "true" ]]; then
            if [[ "${MOCK_UV_EXISTS:-0}" == "1" ]]; then
                uv_exists=1
            elif [[ "${MOCK_UV_MISSING:-0}" == "1" ]]; then
                uv_exists=0
            else
                uv_exists=1
            fi
        else
            if ${ssh_cmd} "which uv" &> /dev/null; then
                uv_exists=1
            fi
        fi

        if [[ ${uv_exists} -eq 1 ]]; then
            log_info "uv is already installed, skipping uv installation"
        else
            log_info "Installing uv via pip install"
            log_info "source ${venv_path}/bin/activate && pip install uv"
            if [[ "${MOCK_UV_INSTALLATION_FAILURE:-0}" == "1" ]]; then
                log_error "Failed to install uv"
                return 1
            fi
            if [[ "${TEST_MODE:-false}" != "true" ]]; then
                if ! ${ssh_cmd} "source \"${venv_path}/bin/activate\" && pip install uv" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                    log_error "Failed to install uv"
                    return 1
                fi
            fi
        fi
    fi

    log_info "Syncing dependencies with uv sync"
    log_info "Changing directory to backend: cd ${backend_path}"
    log_info "cd ${backend_path} && uv sync"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute uv sync in backend directory"
    else
        if [[ "${MOCK_UV_SYNC_FAILURE:-0}" == "1" ]]; then
            log_error "uv sync failed"
            return 1
        fi
        if [[ "${TEST_MODE:-false}" != "true" ]]; then
            if ! ${ssh_cmd} "cd \"${backend_path}\" && \"${venv_path}/bin/uv\" sync" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                log_error "uv sync failed"
                return 1
            fi
        fi
    fi

    log_info "Virtual environment setup completed successfully"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
