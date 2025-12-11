#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${VALIDATORS_SH_LOADED:-}" ]]; then
    return 0
fi
readonly VALIDATORS_SH_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/logger.sh" ]]; then
    source "${SCRIPT_DIR}/logger.sh"
elif [[ -n "${LOGGER_SCRIPT:-}" ]] && [[ -f "${LOGGER_SCRIPT}" ]]; then
    source "${LOGGER_SCRIPT}"
else
    echo "ERROR: logger.sh not found" >&2
    exit 1
fi

validate_required_env_vars() {
    local required_vars=(
        "CPANEL_USERNAME"
        "SERVER_IP_ADDRESS"
        "SSH_PORT"
        "SSH_PRIVATE_KEY_PATH"
        "CPANEL_POSTGRES_USER"
        "CPANEL_POSTGRES_PASSWORD"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var+x}" ]]; then
            missing_vars+=("${var}")
            log_error "Required environment variable ${var} is not set"
        elif [[ -z "${!var}" ]]; then
            missing_vars+=("${var}")
            log_error "Required environment variable ${var} is set but empty"
        else
            log_info "Environment variable ${var} is set"
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing or empty required environment variables: ${missing_vars[*]}"
        return 1
    fi

    log_info "All required environment variables are set"
    return 0
}

validate_test_env_vars() {
    local required_vars=("$@")

    if [[ ${#required_vars[@]} -eq 0 ]]; then
        log_error "validate_test_env_vars: No variables specified"
        return 1
    fi

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var+x}" ]]; then
            missing_vars+=("${var}")
            log_error "Required test variable ${var} is not set"
        elif [[ -z "${!var}" ]]; then
            missing_vars+=("${var}")
            log_error "Required test variable ${var} is set but empty"
        else
            log_info "Test variable ${var} is set"
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing or empty test variables: ${missing_vars[*]}"
        return 1
    fi

    log_info "All required test variables are set"
    return 0
}

validate_required_commands() {
    local required_commands=(
        "ssh"
        "jq"
        "rsync"
        "git"
    )

    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if command -v "${cmd}" &> /dev/null; then
            log_info "Command '${cmd}' is available"
        else
            missing_commands+=("${cmd}")
            log_error "Required command '${cmd}' is not available"
        fi
    done

    if command -v node &> /dev/null; then
        log_info "Command 'node' is available"
    elif command -v npm &> /dev/null; then
        log_info "Command 'npm' is available (node runtime)"
    else
        missing_commands+=("node/npm")
        log_error "Required command 'node' or 'npm' is not available"
    fi

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi

    log_info "All required commands are available"
    return 0
}

validate_ssh_key() {
    local key_path="${SSH_PRIVATE_KEY_PATH:-}"

    if [[ -z "${key_path}" ]]; then
        log_error "SSH_PRIVATE_KEY_PATH is not set"
        return 1
    fi

    log_info "Validating SSH key at path (path not logged for security)"

    if [[ ! -f "${key_path}" ]]; then
        log_error "SSH private key file does not exist"
        return 1
    fi

    local perms
    perms=$(stat -c "%a" "${key_path}" 2>/dev/null || stat -f "%Lp" "${key_path}" 2>/dev/null || echo "unknown")

    if [[ "${perms}" == "400" ]] || [[ "${perms}" == "600" ]]; then
        log_info "SSH key file has correct permissions (${perms})"
    else
        log_error "SSH key file has incorrect permissions (${perms}). Expected 400 or 600"
        return 1
    fi

    if [[ "${OS:-}" != "Windows_NT" ]] && [[ -f "${SCRIPT_DIR}/../linuxify_ssh_key.sh" ]]; then
        log_info "Non-Windows system detected, linuxify_ssh_key.sh available if needed"
    fi

    log_info "SSH key validation successful"
    return 0
}

dry_run_exec() {
    local cmd_array=("$@")

    if [[ ${#cmd_array[@]} -eq 0 ]]; then
        log_error "dry_run_exec: No command specified"
        return 1
    fi

    local cmd_string="${cmd_array[*]}"

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute: ${cmd_string}"
        return 0
    else
        log_info "Executing: ${cmd_string}"
        "${cmd_array[@]}"
        return $?
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
