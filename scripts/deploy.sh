#!/usr/bin/env bash

set -euo pipefail

readonly DEPLOY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${DEPLOY_SCRIPT_DIR}/logger.sh"
source "${DEPLOY_SCRIPT_DIR}/uapi.sh"
source "${DEPLOY_SCRIPT_DIR}/validators.sh"

source "${DEPLOY_SCRIPT_DIR}/functions/provision_database.sh"
source "${DEPLOY_SCRIPT_DIR}/functions/upload_code.sh"
source "${DEPLOY_SCRIPT_DIR}/functions/setup_venv.sh"
source "${DEPLOY_SCRIPT_DIR}/functions/run_schema.sh"
source "${DEPLOY_SCRIPT_DIR}/functions/register_passenger.sh"
source "${DEPLOY_SCRIPT_DIR}/functions/verify_deployment.sh"

show_help() {
    cat << EOF
Usage: ./deploy.sh [OPTIONS]

Deploy blog application to cPanel shared hosting.

OPTIONS:
    --dry-run    Simulate deployment without making changes
    --help       Show this help message

ENVIRONMENT VARIABLES:
    Required:
        CPANEL_USERNAME          cPanel username
        SERVER_IP_ADDRESS        Server IP address
        SSH_PORT                 SSH port
        SSH_PRIVATE_KEY_PATH     Path to SSH private key
        CPANEL_POSTGRES_USER     Database username
        CPANEL_POSTGRES_PASSWORD Database password
        DOMAIN                   Application domain
        DATABASE_NAME            Database name

EXAMPLES:
    # Normal deployment
    ./deploy.sh

    # Dry-run (test without changes)
    ./deploy.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            export DRY_RUN=1
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code $exit_code"
    fi
    exit $exit_code
}
trap cleanup EXIT

main() {
    log_section "Starting deployment to ${DOMAIN:-<not set>}"

    log_section "Validating environment"
    log_info "Validating required environment variables..."
    validate_required_env_vars

    log_info "Validating required commands..."
    validate_required_commands

    log_info "Validating SSH key..."
    validate_ssh_key

    log_section "Step 1: Provisioning database"
    provision_database

    log_section "Step 2: Uploading code"
    upload_code

    log_section "Step 3: Setting up virtual environment"
    setup_venv

    log_section "Step 4: Initializing database schema"
    run_schema

    log_section "Step 5: Registering Passenger application"
    register_passenger

    log_section "Step 6: Verifying deployment"
    verify_deployment

    log_section "Deployment completed successfully!"
}

main "$@"
