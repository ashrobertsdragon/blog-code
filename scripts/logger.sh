#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${LOGGER_SH_LOADED:-}" ]]; then
    return 0
fi
readonly LOGGER_SH_LOADED=1

readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[31m'
readonly COLOR_YELLOW='\033[33m'
readonly COLOR_GRAY='\033[90m'

_get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S"
}

_strip_color_codes() {
    local message="$1"
    local clean="${message}"

    while [[ "${clean}" =~ $'\033'\[([0-9]{1,3}(;[0-9]{1,3})*)?m ]]; do
        clean="${clean//${BASH_REMATCH[0]}/}"
    done

    printf '%s\n' "${clean}"
}

_log_to_file() {
    local message="$1"
    local log_file="${LOG_FILE:-./deploy.log}"
    local log_dir
    log_dir=$(dirname "${log_file}")

    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}"
    fi

    local clean_message
    clean_message=$(_strip_color_codes "${message}")

    if command -v flock &> /dev/null; then
        (
            flock -x 200
            echo "${clean_message}" >> "${log_file}"
        ) 200>"${log_file}.lock"
    else
        echo "${clean_message}" >> "${log_file}"
    fi
}

_log() {
    local level="$1"
    local message="$2"
    local color="$3"

    local timestamp
    timestamp=$(_get_timestamp)

    local log_entry="[${timestamp}] [${level}] ${message}"

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_entry="[DRY-RUN] ${log_entry}"
    fi

    if [[ -n "${color}" ]]; then
        echo -e "${color}${log_entry}${COLOR_RESET}"
    else
        echo "${log_entry}"
    fi

    _log_to_file "${log_entry}"
}

log_debug() {
    local message="${1:-}"
    _log "DEBUG" "${message}" "${COLOR_GRAY}"
}

log_info() {
    local message="${1:-}"
    _log "INFO" "${message}" ""
}

log_warning() {
    local message="${1:-}"
    _log "WARNING" "${message}" "${COLOR_YELLOW}"
}

log_error() {
    local message="${1:-}"
    _log "ERROR" "${message}" "${COLOR_RED}"
}

log_section() {
    local message="${1:-}"
    local timestamp
    timestamp=$(_get_timestamp)

    local separator="========================================"
    local section_header="${separator}
[${timestamp}] [SECTION] ${message}
${separator}"

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        section_header="[DRY-RUN] ${separator}
[DRY-RUN] [${timestamp}] [SECTION] ${message}
[DRY-RUN] ${separator}"
    fi

    echo "${section_header}"

    _log_to_file "${section_header}"
}
