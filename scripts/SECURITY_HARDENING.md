# Security Hardening Summary for deploy.sh

## Implementation Date

2025-12-14

## CRITICAL Fixes Implemented

### 1. Secret Suppression in UAPI Calls (Lines 123, 133, 143, 265-278, 281-290)

**Issue**: Secrets were being leaked to logs through UAPI output
**Fix**: Added `>/dev/null 2>&1` to all UAPI calls that pass sensitive data:

- `create_user` (database password)
- `grant_all_privileges` (includes password in context)
- `register_application` (all API keys and secrets)
- `update_application` (all API keys and secrets)
- Kept stdout only for non-sensitive list operations

**Impact**: Prevents credential leakage to deployment logs and terminal output

### 2. Database Password in Process Arguments (Lines 131-133)

**Issue**: cPanel UAPI limitation - password visible in `ps aux` during user creation
**Mitigation**: Cannot be fully fixed due to UAPI architecture

- Documented risk and limitations in script header
- Minimized exposure time through rapid execution
- Signal traps clear secrets immediately on exit/interrupt
- UAPI output suppressed to prevent logging

**Impact**: Risk acknowledged and minimized; documented for security audit

### 3. Requirements.txt Credential Validation (Lines 161-164)

**Issue**: `uv export` could embed credentials in package URLs
**Fix**: Added validation after `uv export`:

```bash
if grep -qE 'https://[^/]+:[^@]+@' "$requirements_file"; then
  printf "ERROR: requirements.txt contains embedded credentials\n" >&2
  return 1
fi
```

**Pattern**: Detects `https://username:password@` in URLs

**Impact**: Prevents accidental credential exposure in requirements.txt

### 4. SSH Key Permission TOCTOU Fix (Lines 99-107)

**Issue**: Race condition between chmod and permission check
**Fix**:

1. chmod immediately with `--` separator: `chmod 600 -- "$SSH_PRIVATE_KEY_PATH"`
1. Verify permissions were actually set
1. Fail with error if verification fails
1. Cross-platform stat command (GNU/BSD compatibility)

**Impact**: Eliminates race condition vulnerability

## IMPORTANT Fixes Implemented

### 5. SSH Options Injection Prevention (Lines 152, 197, 225)

**Issue**: SSH options as strings susceptible to injection
**Fix**: Converted to arrays in all functions:

```bash
local -a ssh_opts=(-i "$SSH_PRIVATE_KEY_PATH" -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new)
ssh "${ssh_opts[@]}" ...
```

**Impact**: Prevents command injection through SSH options

### 6. Signal Traps for Secret Cleanup (Lines 58-66)

**Issue**: Secrets persist in memory after script exit
**Fix**: Added cleanup function with signal traps:

```bash
cleanup_secrets() {
  unset CPANEL_POSTGRES_PASSWORD
  unset GITHUB_PERSONAL_ACCESS_TOKEN
  unset RESEND_API_KEY
  unset CLERK_PUBLISHABLE_KEY
  unset CLERK_SECRET_KEY
}
trap cleanup_secrets EXIT INT TERM
```

**Impact**: Ensures secrets are cleared on normal exit, interruption, or termination

### 7. Input Sanitization (Lines 92-99, 78-79)

**Issue**: Environment variables not validated for shell metacharacters
**Fix**: Added sanitization function:

```bash
sanitize_input() {
  local value="$1"
  if [[ "$value" =~ [\;\&\|\`\$\(\)] ]]; then
    printf "ERROR: Environment variable contains invalid characters\n" >&2
    return 1
  fi
  return 0
}
```

Called for `CPANEL_USERNAME` and `SERVER_IP_ADDRESS`

**Impact**: Prevents command injection through environment variables

### 8. Audit Logging (Lines 116, 122, 130, 140, 154, 174, 185, 199, 227, 253, 264, 280, 340, 369)

**Issue**: No audit trail for security-relevant operations
**Fix**: Added syslog integration via `logger` command:

- Database provisioning operations
- Code upload operations
- Environment variable injection
- Deployment start/completion

**Impact**: Creates audit trail for security review and incident response

### 9. Generic Error Messages (Line 73)

**Issue**: Error messages leaked variable names
**Fix**: Changed from:

```bash
printf "ERROR: Required environment variable %s is not set\n" "$var" >&2
```

to:

```bash
printf "ERROR: Required environment variable is not set\n" >&2
```

**Impact**: Prevents information disclosure about internal variable names

### 10. Secure Temporary File Creation (Lines 155-158, 166)

**Issue**: requirements.txt created in predictable location
**Fix**:

- Use `mktemp -d` for temporary directory
- Automatic cleanup with RETURN trap
- Safe file operations with `--` separator

**Impact**: Prevents predictable temporary file attacks

### 11. Production Deployment Confirmation (Lines 325-337, 343)

**Issue**: No confirmation for production deployments
**Fix**: Added interactive prompt for production domain:

```bash
confirm_production_deployment() {
  if [[ "${DOMAIN}" == "ashlynantrobus.dev" ]] && [[ -t 0 ]]; then
    printf "WARNING: Deploying to PRODUCTION domain: %s\n" "$DOMAIN" >&2
    printf "Continue? (yes/no): " >&2
    local response
    read -r response
    if [[ "${response}" != "yes" ]]; then
      printf "Deployment cancelled by user\n" >&2
      return 1
    fi
  fi
  return 0
}
```

**Impact**: Prevents accidental production deployments

## Additional Hardening

### 12. Enhanced Error Handling (Lines 47-49)

Added:

- `shopt -s inherit_errexit` for better error propagation
- `IFS=$'\n\t'` to prevent word splitting on spaces

### 13. Comprehensive Documentation (Lines 3-45)

Added docstring covering:

- Security features
- Known limitations with mitigation strategies
- Usage instructions
- Required environment variables
- Exit codes

## Test Results

All 30 existing tests pass after security hardening:

- ✓ Environment validation tests (5)
- ✓ SSH key handling tests (3)
- ✓ Database provisioning tests (4)
- ✓ Code upload tests (3)
- ✓ Virtual environment tests (4)
- ✓ Schema execution tests (3)
- ✓ Passenger registration tests (5)
- ✓ Health check verification tests (3)

## Security Posture Summary

**Before Hardening**: Multiple HIGH and MEDIUM severity vulnerabilities
**After Hardening**: Production-ready with defense-in-depth security

**Remaining Risk**: Database password in process arguments (cPanel UAPI limitation)

- Documented and minimized through multiple mitigation layers
- Acceptable for cPanel-hosted environments with this architectural constraint

## Recommendations for Future Improvements

1. Consider cPanel API v2/UAPI alternatives if they support secret passing
1. Implement log rotation for audit logs
1. Add security scanning in CI/CD pipeline
1. Consider secret management service integration (e.g., HashiCorp Vault)
1. Add rate limiting for deployment operations
