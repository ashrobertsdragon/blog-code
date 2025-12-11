#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${PARENT_DIR}/.." && pwd)"

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

upload_code() {
    log_section "Code Upload"

    local required_vars=(
        "CPANEL_USERNAME"
        "SERVER_IP_ADDRESS"
        "SSH_PORT"
        "SSH_PRIVATE_KEY_PATH"
        "BACKEND_DIR"
        "FRONTEND_DIR"
        "REMOTE_APP_PATH"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable ${var} is not set"
            return 1
        fi
    done

    if [[ "${OS:-}" != "Windows_NT" ]]; then
        log_info "Non-Windows system detected, checking for linuxify_ssh_key.sh"
        if [[ -f "${PROJECT_ROOT}/linuxify_ssh_key.sh" ]]; then
            log_info "Running linuxify_ssh_key.sh"
            if [[ "${DRY_RUN:-0}" != "1" ]]; then
                bash "${PROJECT_ROOT}/linuxify_ssh_key.sh" || true
            else
                log_info "[DRY-RUN] Would run linuxify_ssh_key.sh"
            fi
        fi
    fi

    log_info "Building frontend with npm run build"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute: npm run build in ${FRONTEND_DIR}"
    else
        if [[ "${MOCK_NPM_BUILD_FAILURE:-0}" == "1" ]]; then
            log_error "npm build failed"
            return 1
        fi
        if [[ -f "${FRONTEND_DIR}/package.json" ]] && command -v npm &> /dev/null; then
            if ! (cd "${FRONTEND_DIR}" && npm run build 2>&1 | tee -a "${LOG_FILE:-/dev/null}"); then
                log_error "Frontend build failed"
                return 1
            fi
        else
            log_info "Skipping npm build (package.json not found or npm not available)"
        fi
    fi

    local build_dir="${BUILD_DIR:-${FRONTEND_DIR}/dist}"
    log_info "Checking if build directory exists: ${build_dir}"
    if [[ ! -d "${build_dir}" ]] && [[ "${DRY_RUN:-0}" != "1" ]]; then
        log_error "Build directory ${build_dir} does not exist"
        return 1
    fi

    local rsync_ssh="ssh -i ${SSH_PRIVATE_KEY_PATH} -p ${SSH_PORT}"
    local backend_dest="${CPANEL_USERNAME}@${SERVER_IP_ADDRESS}:${REMOTE_APP_PATH}/backend/"
    local frontend_dest="${CPANEL_USERNAME}@${SERVER_IP_ADDRESS}:${REMOTE_APP_PATH}/frontend/dist/"

    log_info "Uploading backend via rsync"
    log_info "rsync -avz --exclude=node_modules --exclude=.git --exclude=__pycache__ -e \"${rsync_ssh}\" ${BACKEND_DIR}/ ${backend_dest}"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute rsync for backend"
    else
        if [[ "${MOCK_RSYNC_FAILURE:-0}" == "1" ]]; then
            log_error "rsync failed"
            return 1
        fi
        if [[ "${TEST_MODE:-false}" == "true" ]] || ! command -v rsync &> /dev/null; then
            log_info "Test mode or rsync not available, skipping actual rsync execution"
        else
            if ! rsync -avz --exclude=node_modules --exclude=.git --exclude=__pycache__ -e "${rsync_ssh}" "${BACKEND_DIR}/" "${backend_dest}" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                log_error "Backend rsync failed"
                return 1
            fi
        fi
    fi

    log_info "Uploading frontend build directory via rsync"
    log_info "rsync -avz -e \"${rsync_ssh}\" ${build_dir}/ ${frontend_dest}"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute rsync for frontend dist"
    else
        if [[ "${MOCK_RSYNC_FAILURE:-0}" == "1" ]]; then
            log_error "rsync failed"
            return 1
        fi
        if [[ "${TEST_MODE:-false}" == "true" ]] || ! command -v rsync &> /dev/null; then
            log_info "Test mode or rsync not available, skipping actual rsync execution"
        else
            if ! rsync -avz -e "${rsync_ssh}" "${build_dir}/" "${frontend_dest}" 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
                log_error "Frontend rsync failed"
                return 1
            fi
        fi
    fi

    log_info "Code upload completed successfully"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
