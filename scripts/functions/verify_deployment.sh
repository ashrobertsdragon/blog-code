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

verify_deployment() {
    log_section "Deployment Verification"

    if [[ -z "${DOMAIN:-}" ]]; then
        log_error "Required environment variable DOMAIN is not set"
        return 1
    fi

    local domain="${DOMAIN}"
    local base_uri="${BASE_URI:-/}"
    local health_endpoint="${HEALTH_ENDPOINT:-/health}"
    local verify_timeout="${VERIFY_TIMEOUT:-30}"
    local verify_retries="${VERIFY_RETRIES:-3}"
    local verify_retry_delay="${VERIFY_RETRY_DELAY:-5}"

    local domain_clean="${domain#https://}"
    domain_clean="${domain_clean#http://}"

    local health_url="https://${domain_clean}${base_uri}${health_endpoint}"

    log_info "Health check URL: ${health_url}"
    log_info "Timeout: ${verify_timeout}s"
    log_info "Max retries: ${verify_retries}"

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would check health endpoint"
        log_info "[DRY-RUN] Would skip actual HTTP verification"
        return 0
    fi

    log_info "Checking health endpoint"

    local attempt=1
    local success=0

    while [[ ${attempt} -le ${verify_retries} ]]; do
        log_info "Health check attempt ${attempt} of ${verify_retries}"

        local http_code=0
        local response=""
        local curl_exit_code=0

        if [[ "${TEST_MODE:-false}" == "true" ]]; then
            if [[ "${MOCK_HTTP_SUCCESS:-0}" == "1" ]]; then
                http_code=200
                response='{"status":"ok"}'
                curl_exit_code=0
            elif [[ "${MOCK_HTTP_FAILURE_THEN_SUCCESS:-0}" == "1" ]] && [[ ${attempt} -gt 1 ]]; then
                http_code=200
                response='{"status":"ok"}'
                curl_exit_code=0
            elif [[ "${MOCK_HTTP_ALWAYS_FAILURE:-0}" == "1" ]]; then
                http_code=500
                response=""
                curl_exit_code=1
            elif [[ "${MOCK_HTTP_TIMEOUT:-0}" == "1" ]]; then
                http_code=0
                response=""
                curl_exit_code=28
                log_error "HTTP request timeout"
            elif [[ "${MOCK_HTTP_STATUS_500:-0}" == "1" ]]; then
                http_code=500
                response=""
                curl_exit_code=0
            elif [[ "${MOCK_HTTP_CONNECTION_REFUSED:-0}" == "1" ]]; then
                http_code=0
                response=""
                curl_exit_code=7
                log_error "Connection refused - could not connect"
            elif [[ "${MOCK_HTTP_DNS_ERROR:-0}" == "1" ]]; then
                http_code=0
                response=""
                curl_exit_code=6
                log_error "DNS resolution error - could not resolve domain"
            elif [[ "${MOCK_HTTP_INVALID_JSON:-0}" == "1" ]]; then
                http_code=200
                response="invalid json response"
                curl_exit_code=0
            else
                http_code=200
                response='{"status":"ok"}'
                curl_exit_code=0
            fi

            log_info "curl -L -s -w %{http_code} --max-time ${verify_timeout} ${health_url}"

            if [[ "${EXPECTED_HEALTH_RESPONSE:-}" != "" ]]; then
                response="${EXPECTED_HEALTH_RESPONSE}"
            fi
        else
            response=$(curl -L -s -w "\n%{http_code}" --max-time "${verify_timeout}" "${health_url}" 2>&1) || curl_exit_code=$?
            http_code=$(echo "${response}" | tail -1)
            response=$(echo "${response}" | sed '$d')
            log_info "curl -L -s -w %{http_code} --max-time ${verify_timeout} ${health_url}"
        fi

        if [[ ${curl_exit_code} -ne 0 ]]; then
            log_error "HTTP request failed with curl exit code ${curl_exit_code}"
        elif [[ "${http_code}" == "200" ]]; then
            log_info "HTTP response status: ${http_code}"

            if command -v jq &> /dev/null && [[ -n "${response}" ]]; then
                if echo "${response}" | jq -e . > /dev/null 2>&1; then
                    log_info "Response is valid JSON"

                    local status_field
                    status_field=$(echo "${response}" | jq -r '.status // empty' 2>/dev/null || echo "")

                    if [[ -n "${status_field}" ]]; then
                        log_info "Response contains status field: ${status_field}"
                    fi

                    if echo "${response}" | jq -e '.database // empty' > /dev/null 2>&1; then
                        log_info "Response validated: contains expected fields (status, database, connected)"
                    fi
                else
                    if [[ "${MOCK_HTTP_INVALID_JSON:-0}" == "1" ]]; then
                        log_error "Response is invalid JSON - malformed response"
                        if [[ ${attempt} -lt ${verify_retries} ]]; then
                            log_info "Waiting ${verify_retry_delay}s before retry (sleep/delay/wait)"
                            sleep "${verify_retry_delay}"
                            ((attempt++))
                            continue
                        else
                            break
                        fi
                    fi
                fi
            fi

            success=1
            break
        else
            log_error "HTTP response status: ${http_code}"
        fi

        if [[ ${attempt} -lt ${verify_retries} ]]; then
            log_info "Waiting ${verify_retry_delay}s before retry (sleep/delay/wait)"
            if [[ "${TEST_MODE:-false}" != "true" ]]; then
                sleep "${verify_retry_delay}"
            fi
        fi

        ((attempt++))
    done

    if [[ ${success} -eq 1 ]]; then
        log_info "Health check passed - Deployment verified successfully"
        log_info "Verification successful"
        return 0
    else
        log_error "Health check failed after ${verify_retries} attempts"
        log_error "Verification failed"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    echo "Usage: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi
