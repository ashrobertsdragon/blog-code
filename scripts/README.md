# Deployment Scripts

This directory contains production deployment automation for the blog application to cPanel shared hosting.

## Overview

The deployment script (`deploy.sh`) provides end-to-end automation for deploying the blog platform to cPanel hosting with Phusion Passenger. It handles database provisioning, code upload, virtual environment setup, and application registration in a single command.

## Features

- **Idempotent Operations**: Safe to run multiple times - only creates resources that don't exist
- **Database Provisioning**: Automatic PostgreSQL database, user, and privilege setup
- **Code Deployment**: Rsync-based upload with checksum verification and deletion of stale files
- **Virtual Environment Management**: Remote Python venv creation and dependency installation
- **Schema Migration**: Automatic database schema creation from SQLModel models
- **Application Registration**: Passenger WSGI application configuration with environment variables
- **Health Verification**: Post-deployment validation of critical endpoints
- **Error Handling**: Exponential backoff retry logic for network operations
- **Security**: Input sanitization, secret suppression, SSH key permission validation, audit logging
- **Cross-Platform**: Compatible with Windows Git Bash and Linux environments

## Prerequisites

### Local Environment

1. **Operating System**: Windows with Git Bash, Linux, or macOS
1. **Required Tools**:
   - `bash` 4.0+ (included in Git Bash on Windows)
   - `ssh` client (OpenSSH)
   - `rsync` (for Windows: install via Git Bash or WSL)
   - `uv` Python package manager (for exporting requirements.txt)
1. **Frontend Build**: Run `npm run build` in `frontend/` directory before deploying
1. **SSH Access**: SSH private key with access to cPanel server

### Environment Variables

All environment variables must be set before running the deployment script. These are already configured in your local environment:

| Variable                       | Description               | Example                     |
| ------------------------------ | ------------------------- | --------------------------- |
| `CPANEL_USERNAME`              | cPanel/SSH username       | `myuser`                    |
| `SERVER_IP_ADDRESS`            | Server IP address for SSH | `198.51.100.50`             |
| `SSH_PRIVATE_KEY_PATH`         | Path to SSH private key   | `C:/Users/user/.ssh/id_rsa` |
| `SSH_PORT`                     | SSH port number           | `22`                        |
| `CPANEL_POSTGRES_USER`         | PostgreSQL username       | `myuser_pguser`             |
| `CPANEL_POSTGRES_PASSWORD`     | PostgreSQL password       | (sensitive)                 |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub API token          | `ghp_...`                   |
| `RESEND_API_KEY`               | Resend email API key      | `re_...`                    |
| `CLERK_PUBLISHABLE_KEY`        | Clerk auth public key     | `pk_test_...`               |
| `CLERK_SECRET_KEY`             | Clerk auth secret key     | `sk_test_...`               |

**Security Note**: Never commit these values to version control. They should only exist in your local environment or secure secret management system.

### Remote Server Requirements

1. **cPanel Hosting**: Shared hosting account with:
   - PostgreSQL database support
   - SSH access enabled
   - Phusion Passenger available
   - Python 3.13+ installed
1. **Domain Configuration**: DNS pointing to server IP
1. **cPanel UAPI Access**: Enabled for database and Passenger operations

## Usage

### Basic Deployment

```bash
cd monorepo/scripts
./deploy.sh
```

The script will:

1. Validate all required environment variables
1. Configure SSH key with correct permissions
1. Provision PostgreSQL database (idempotent)
1. Upload backend code and frontend build files via rsync
1. Create remote Python virtual environment
1. Install dependencies from requirements.txt
1. Create database schema from SQLModel models
1. Register Passenger application with environment variables
1. Verify deployment via health checks

### Production Deployment Confirmation

When deploying to the production domain (`ashlynantrobus.dev`), the script will prompt for confirmation:

```text
WARNING: Deploying to PRODUCTION domain: ashlynantrobus.dev
Continue? (yes/no):
```

Type `yes` to proceed or `no` to cancel.

### Cross-Platform SSH Key Handling

On **Windows Git Bash**, the script automatically uses the SSH key at `$SSH_PRIVATE_KEY_PATH`.

On **Linux/macOS**, the script will automatically run `linuxify_ssh_key.sh` (if available in project root) to copy the SSH key to a Linux-compatible location before use.

## Idempotency

The deployment script is fully idempotent - safe to run multiple times without side effects:

- **Database Creation**: Only creates database if it doesn't exist
- **User Creation**: Only creates PostgreSQL user if it doesn't exist
- **Privilege Grants**: Only grants privileges if not already granted
- **Application Registration**: Creates new app or updates existing app configuration
- **File Upload**: Rsync uses checksums to only transfer changed files

This means you can safely re-run the deployment after failures without manual cleanup.

## Output and Logging

The script provides progress feedback during deployment:

```text
Starting deployment to ashlynantrobus.dev...
✓ Environment variables validated
✓ SSH key configured
✓ Database provisioned
✓ Code uploaded
✓ Virtual environment configured
✓ Database schema created
✓ Passenger application registered
✓ Deployment verified

Deployment completed successfully!
Application URL: https://ashlynantrobus.dev
```

All security-relevant operations are logged to syslog with the tag `deploy.sh`.

## Error Handling

### Retry Logic

Network operations (health checks) use exponential backoff retry:

- Maximum retries: 5
- Base delay: 2 seconds
- Delay increases: 2s, 4s, 8s, 16s, 32s

### Common Errors

| Error                                      | Cause               | Solution                                 |
| ------------------------------------------ | ------------------- | ---------------------------------------- |
| `Required environment variable is not set` | Missing env var     | Set all required variables               |
| `Backend source directory is empty`        | Missing code        | Ensure `monorepo/backend/` exists        |
| `Frontend build directory is empty`        | Build not run       | Run `npm run build` in frontend/         |
| `SSH connection failed`                    | Invalid key/network | Verify SSH key and server access         |
| `Health check failed`                      | App not responding  | Check Passenger logs on server           |
| `Failed to set restrictive permissions`    | SSH key permissions | Ensure key file is owned by current user |

### Exit Codes

- `0`: Deployment successful
- `1`: Validation failure, deployment error, or user cancellation

## Testing

The deployment script has comprehensive BATS test coverage.

### Running Tests

```bash
cd monorepo/scripts/tests

# Run all tests
bats .

# Run specific test file
bats deploy.bats

# Run tests with specific filter
bats deploy.bats --filter "database"

# Run with verbose output
bats deploy.bats --tap
```

### Test Coverage

- **Environment Validation** (5 tests): Missing variables, invalid input
- **Database Provisioning** (8 tests): Creation, idempotency, error handling
- **User Provisioning** (5 tests): User creation, privilege grants, failures
- **Code Upload** (4 tests): Rsync success/failure, file validation
- **Health Checks** (3 tests): Endpoint verification, retry logic
- **Integration** (5 tests): End-to-end deployment scenarios

All tests use mocks - no actual network calls or database operations.

### Test Documentation

See `tests/README.md` for detailed testing documentation including:

- Mock framework usage
- Writing new tests
- Debugging failed tests
- Best practices

## Security Considerations

### Secret Handling

- Secrets are stored in environment variables (never in code)
- UAPI calls redirect output to `/dev/null` to prevent logging passwords
- Signal traps (`EXIT`, `INT`, `TERM`) automatically unset secrets on script termination
- SSH key permissions validated (must be `600`)

### Known Limitations

**Database password in process arguments**: During PostgreSQL user creation, the password briefly appears in process arguments due to cPanel UAPI design. This is mitigated by:

1. Rapid execution (minimal exposure window)
1. Automatic secret cleanup via signal traps
1. UAPI output suppression

### Input Validation

The script validates environment variables to prevent injection attacks:

- Blocks characters: `;`, `&`, `|`, `` ` ``, `$`, `(`, `)`
- Validates SSH key file permissions
- Scans requirements.txt for embedded credentials

### Audit Logging

All security-relevant operations are logged to syslog:

```bash
logger -t deploy.sh -p user.info "Creating database: cpaneluser_blogdb"
logger -t deploy.sh -p user.notice "Deployment completed successfully"
```

View logs with: `journalctl -t deploy.sh` (Linux) or `/var/log/messages` (cPanel)

## Deployment Architecture

### Remote Directory Structure

```plaintext
/home/$CPANEL_USERNAME/blog/
├── backend/                    # Backend code
│   ├── src/
│   │   ├── passenger_wsgi.py   # WSGI entry point
│   │   └── backend/            # Application code
│   ├── requirements.txt        # Python dependencies
│   └── pyproject.toml         # uv project definition
├── build/                      # Frontend static files
│   ├── index.html
│   ├── static/
│   └── assets/
└── venv/                       # Python virtual environment
    ├── bin/
    ├── lib/
    └── pyvenv.cfg
```

### Database Naming Convention

- Database: `${CPANEL_USERNAME}_blogdb`
- User: Value of `$CPANEL_POSTGRES_USER` environment variable
- Connection: `localhost` (cPanel default)

### Passenger Configuration

The script registers a Passenger application with:

- **Name**: `BlogAppProd`
- **Domain**: `ashlynantrobus.dev`
- **Base URI**: `/` (root)
- **Deployment Mode**: `production`
- **Environment Variables**: All secrets injected at application level

## Rollback

To rollback a deployment:

1. **Database**: PostgreSQL is idempotent - old schema remains intact
1. **Code**: Deploy previous git commit or manually revert files
1. **Passenger**: Use cPanel interface to restart application

**Note**: The script does not currently support automated rollback. Manual intervention required.

## Troubleshooting

### Debugging Failed Deployments

1. **Check SSH connectivity**:

   ```bash
   ssh -i "$SSH_PRIVATE_KEY_PATH" -p "$SSH_PORT" "$CPANEL_USERNAME@$SERVER_IP_ADDRESS"
   ```

1. **Verify remote directory structure**:

   ```bash
   ssh ... "ls -la ~/blog"
   ```

1. **Check Passenger logs** (via cPanel or SSH):

   ```bash
   tail -f ~/blog/passenger.log
   ```

1. **Test health endpoints manually**:

   ```bash
   curl https://ashlynantrobus.dev/health
   curl https://ashlynantrobus.dev/health/db
   curl https://ashlynantrobus.dev/health/github
   ```

1. **Verify database connectivity** (via SSH):

   ```bash
   psql -h localhost -U "$CPANEL_POSTGRES_USER" -d "${CPANEL_USERNAME}_blogdb"
   ```

### Common Issues

**Frontend build missing**: Ensure you run `npm run build` before deploying.

**SSH key permissions error**: The key must be owned by the current user and have `600` permissions. On Windows, this may require administrator privileges.

**Health check timeout**: Passenger may take 30-60 seconds to start the application on first deployment. The script automatically retries with backoff.

**Database connection refused**: Verify PostgreSQL is running in cPanel and credentials are correct.

## Future Enhancements

Potential improvements for future versions:

- Automated rollback capability
- Blue-green deployment support
- Database migration management
- Backup creation before deployment
- Slack/email deployment notifications
- Deployment metrics and timing
- Parallel file upload optimization
- Environment-specific configuration (staging/production)

## Related Documentation

- cPanel deployment strategies: `../../cpanel-deployment-patterns.md`
- Backend configuration: `../backend/README.md`
- WSGI entry point: `../backend/src/passenger_wsgi.py`
- Test documentation: `tests/README.md`
- Project structure: `../../.spec-workflow/steering/structure.md`

## Support

For deployment issues:

1. Review error messages in script output
1. Check syslog for audit trail
1. Verify all prerequisites are met
1. Run BATS tests to validate local environment
1. Consult cPanel documentation for UAPI/Passenger issues

## License

This deployment script is part of the blog platform project and follows the same license.
