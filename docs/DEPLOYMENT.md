# cPanel Deployment Guide

**Version**: 0.2.0
**Target Environment**: cPanel Shared Hosting with Phusion Passenger
**Deployment Method**: Automated via `monorepo/scripts/deploy.sh`

---

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Automated Deployment](#automated-deployment)
4. [Troubleshooting](#troubleshooting)

---

## Introduction

This document provides deployment instructions for the blog platform to a cPanel shared hosting environment. The deployment is fully automated using the `monorepo/scripts/deploy.sh` bash script. This script handles all infrastructure provisioning, code upload, dependency installation, and application registration, ensuring a consistent and repeatable process.

The script leverages SSH for server access and cPanel's UAPI (Universal API) for provisioning resources like PostgreSQL databases and Passenger applications.

### Deployment Philosophy

The deployment is guided by these principles:

- **Automation**: A single script orchestrates the entire deployment from start to finish.
- **Infrastructure as Code**: The `deploy.sh` script contains all logic for provisioning and configuration.
- **Idempotency**: The script can be re-run safely without causing errors. It checks for existing resources before creating new ones.
- **Security**: Secrets are loaded from environment variables and are not hardcoded. The script includes features to handle SSH keys securely and suppress secrets in logs.

---

## Prerequisites

### Access Requirements

- **cPanel Account**: An active shared hosting account with SSH access enabled.
- **Domain**: A domain name configured in cPanel and pointing to the server's IP address.
- **SSH Key**: A password-less SSH private key configured for access to your cPanel account.

### Local Environment

- **OS**: A Unix-like environment (Linux, macOS, or WSL on Windows).
- **Tools**: `bash`, `ssh`, `rsync`, and `curl` must be installed.
- **Node.js/npm**: Required to build the frontend artifacts locally before deployment.

### Required Environment Variables

The `deploy.sh` script requires the following environment variables to be set. You can add them to a `.env` file in the project root and load them with `source .env` before running the script.

| Variable | Description | Example Value |
| :--- | :--- | :--- |
| `DOMAIN` | Target domain name | `ashlynantrobus.dev` |
| `CPANEL_USERNAME` | cPanel/SSH username | `myuser` |
| `SERVER_IP_ADDRESS` | Server IP address for SSH | `198.51.100.50` |
| `SSH_PRIVATE_KEY_PATH` | Path to your SSH private key | `~/.ssh/id_rsa` |
| `SSH_PORT` | SSH port number | `22` |
| `CPANEL_POSTGRES_USER` | PostgreSQL username | `myuser_blog` |
| `CPANEL_POSTGRES_PASSWORD` | PostgreSQL password | `(sensitive)` |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub PAT for draft repo access | `ghp_...` |
| `RESEND_API_KEY` | Resend email service API key | `re_...` |
| `CLERK_PUBLISHABLE_KEY` | Clerk auth publishable key | `pk_test_...` |
| `CLERK_SECRET_KEY` | Clerk auth secret key | `sk_test_...` |
| `PRODUCTION_DOMAIN` | Production domain for confirmation prompt | `example.com` |

**Note**: The script will validate that all these variables are set before starting the deployment.

---

## Automated Deployment

The entire deployment process is handled by a single script.

### Step 1: Build Frontend Artifacts

The deployment script uploads the frontend, but does **not** build it. You must build the production-ready frontend artifacts first. You may use the build script for this.

```bash
# Run the build script
./scripts/build.sh
```

This will create a `monorepo/build` directory containing the static HTML, CSS, and JavaScript files.

### Step 2: Run the Deployment Script

From the `monorepo` directory, execute the `deploy.sh` script.

```bash
# Run the script
./scripts/deploy.sh
```

If your domain is set to the production domain, the script will prompt for confirmation before deploying to production. Type `yes` to proceed.

### Script Workflow

The script will perform the following steps automatically:

1. **Validate Environment**: Checks that all required environment variables are set and that the SSH key file exists and has the correct (`600`) permissions.
2. **Provision Database**:
    - Connects to the server via SSH.
    - Uses cPanel UAPI to create the PostgreSQL database (`{CPANEL_USERNAME}_blogdb`) if it doesn't exist.
    - Creates the PostgreSQL user (`{CPANEL_POSTGRES_USER}`) if it doesn't exist.
    - Grants all privileges on the database to the user.
3. **Upload Code**:
    - Uploads the `monorepo/backend` directory to `~/blog/` on the server using `rsync`.
    - Uploads the `monorepo/frontend/build` directory to `~/blog/build/` on the server.
4. **Install Dependencies**:
    - Ensures `uv` (the Python package manager) is installed on the server.
    - Runs `uv sync --frozen` in the `~/blog` directory to install all Python dependencies listed in `uv.lock`.
5. **Create Database Schema**:
    - Executes the `create-schema` script (defined in `pyproject.toml`) on the server to create all necessary database tables.
6. **Register Passenger Application**:
    - Uses cPanel UAPI to create or update the Phusion Passenger application registration named `MarkdownBlog`.
    - Injects all necessary secrets (database credentials, API keys) as environment variables into the application's runtime.
7. **Verify Deployment**:
    - Performs health checks by sending HTTP requests to the `/health`, `/health/db`, and `/health/github` endpoints.
    - Uses a retry mechanism with exponential backoff to wait for the application to start.

Upon successful completion, the script will print the application URL.

---

## Troubleshooting

### Deployment Fails at "validate_environment"

- **Error**: `Required environment variable is not set`
  - **Cause**: One of the variables listed in the "Prerequisites" section is missing.
  - **Solution**: Ensure all required environment variables are exported in your shell.

- **Error**: `SSH key file not found` or `Failed to set or verify proper permissions (600) on SSH key`
  - **Cause**: The path in `SSH_PRIVATE_KEY_PATH` is incorrect, or the script could not set `chmod 600` on the key. This is common when running in WSL with a key stored on the Windows filesystem.
  - **Solution**: Verify the key path. If using WSL, copy the key to the Linux filesystem (e.g., `~/.ssh/`) and update `SSH_PRIVATE_KEY_PATH`.

### Deployment Fails at "provision_database"

- **Cause**: The cPanel user may not have permission to create PostgreSQL databases or users.
- **Solution**: Log in to the cPanel web interface and verify that you can create a database manually. Check your hosting plan's features.

### Deployment Fails at "upload_code"

- **Cause**: `rsync` or `ssh` command failed. This could be due to a network issue or an SSH connection problem.
  - **Solution**: Check your internet connection and ensure you can connect to the server manually with `ssh -i $SSH_PRIVATE_KEY_PATH -p $SSH_PORT $CPANEL_USERNAME@$SERVER_IP_ADDRESS`.

### Deployment Fails at "verify_deployment"

- **Error**: `Health check failed for endpoint...`
  - **Cause**: The application started but is not healthy. This is most likely due to a runtime error.
  - **Solution**: SSH into the server and check the application's error logs. The logs for the Passenger application are typically found in a `logs` or `stderr.log` file within the application directory on the server. Common issues include missing dependencies or incorrect environment variables. The script handles injecting variables, but a typo in a variable name could be the cause.
