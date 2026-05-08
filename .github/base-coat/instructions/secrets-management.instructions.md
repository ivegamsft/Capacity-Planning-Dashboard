---
description: >
  Secrets management standards — never commit secrets to version control,
  use centralized Vault solutions, implement rotation, and audit all access.
applyTo: agents/secrets-manager.agent.md, agents/devops-engineer.agent.md, agents/infrastructure-deploy.agent.md
---

# Secrets Management Standards

## Core Principle

**NEVER commit secrets to version control.** This is the foundation of secrets management.

## Secrets Classification

### Type 1: Application Secrets (Runtime)
- API keys for external integrations (Stripe, SendGrid, AWS)
- Database credentials (username, password, connection strings)
- Service account credentials
- OAuth2 tokens, JWT secrets
- Encryption keys for data at rest

**Management:** Injected at deployment time, stored in Vault, rotated per policy

### Type 2: Infrastructure Secrets
- SSH private keys
- TLS/SSL certificates and private keys
- VPN credentials
- Container registry credentials
- Code signing certificates

**Management:** Stored in Vault or certificate management service, short-lived leases

### Type 3: Supply Chain Secrets
- Package repository credentials (npm, PyPI)
- Artifact repository tokens
- Git personal access tokens
- CI/CD runner credentials

**Management:** Vault or CI/CD platform secrets store, minimize lifetime

## Secret Storage Patterns

### Pattern 1: Application Secrets (Recommended)

Use centralized Vault with workload identity:

```yaml
Architecture:
  App Container
    ↓ (OIDC or mTLS)
  Kubernetes Service Account
    ↓ (WorkloadIdentity)
  Identity Provider (OIDC)
    ↓
  Vault
    ↓ (issues temporary token)
  App reads secret

Benefits:
  - No long-lived keys in code
  - RBAC integrated with Kubernetes identity
  - Automatic credential rotation
  - Audit trail shows which service accessed secret
  - Token auto-expires (typically 1 hour)
```

**Implementation (Kubernetes + Vault):**

```bash
# 1. Create Kubernetes service account
kubectl create serviceaccount myapp -n default

# 2. Configure Vault auth backend
vault auth enable kubernetes

# 3. Create Vault policy for app
vault policy write myapp -<<EOF
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# 4. Configure Vault role for service account
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=default \
  policies=myapp

# 5. App reads secret at runtime
# SDK: app uses OIDC provider → Vault → temporary token → read secret
```

### Pattern 2: Deployment-Time Injection (CI/CD)

For non-Kubernetes or external services:

```yaml
Deployment Pipeline:
  1. Build image (no secrets)
  2. On deployment:
     - Retrieve secret from Vault
     - Inject as environment variable or mounted file
     - Deploy container with secret
     - Secret exists only in running container memory
```

**Implementation (GitLab CI/CD):**

```yaml
deploy:
  script:
    - export DB_PASSWORD=$(vault kv get -field=password secret/db/prod)
    - docker run -e DB_PASSWORD=$DB_PASSWORD myimage:latest
  secrets:
    VAULT_TOKEN:
      vault: ci/vault-token
```

### Pattern 3: Configuration File (NOT Recommended)

If Vault integration not possible:

```yaml
.env file (development only):
  - Never commit to repo
  - Add .env to .gitignore
  - Document in .env.example (masked values)
  - Use for local dev/testing only

Example .env.example:
  DATABASE_URL=postgresql://user:PASSWORD@host:5432/db
  API_KEY=CHANGE_ME_IN_PRODUCTION
```

## Secret Rotation

### Rotation Policies

| Secret Type | Frequency | Trigger | Automation |
|---|---|---|---|
| API Keys | 90 days | Scheduled + on request | High (Vault native) |
| Database Passwords | 60 days | Scheduled | High (Vault rotation templates) |
| OAuth/JWT Tokens | 30 days | Before expiry | Automatic (built-in TTL) |
| TLS Certificates | 365 days | Day 30 before expiry | Medium (cert automation tools) |
| SSH Keys | 180 days | Scheduled | Manual (requires rollover process) |
| Container Registry Tokens | 30 days | Scheduled | High (registry-native) |

### Rotation Workflow

```
1. SCHEDULE
   - Calendar reminder 7 days before rotation due
   - Automated trigger at scheduled time
   
2. GENERATE NEW SECRET
   - Create new secret in Vault
   - Maintain N+1 versions (old still active, new ready)
   
3. DEPLOY NEW SECRET
   - Stage new secret in production infrastructure
   - Validate new secret works (health checks)
   - Monitor for errors
   
4. RETIRE OLD SECRET
   - After verification, disable old secret in Vault
   - Monitor for stale connections (will fail and reconnect)
   - After grace period (24 hours), delete old secret
   
5. DOCUMENT
   - Record rotation timestamp in audit log
   - Email stakeholders if high-risk secret
   - Update runbook if manual steps required
```

**Automation Example (HashiCorp Vault):**

```hcl
# Configure automatic rotation for database password
resource "vault_generic_secret" "db_password" {
  path      = "secret/database/prod"
  data_json = jsonencode({
    username = "dbuser"
    password = random_password.db_password.result
  })
}

# Rotate every 60 days
resource "vault_pki_secret_backend_role" "db_rotation" {
  backend            = vault_pki_secret_backend.pki.path
  name               = "database-rotation"
  max_ttl            = "2160h"  # 90 days
  generate_lease     = true
  rotation_period    = "1440h"  # 60 days
}
```

## Expiry Scanning

### Automated Monitoring

**Daily Scans:**

```bash
# 1. Vault secrets expiry
vault list secret/
vault read secret/my-api-key | grep "lease_duration"

# 2. TLS Certificate expiry
openssl s_client -connect api.example.com:443 -servername api.example.com | \
  openssl x509 -noout -dates

# 3. Dependency vulnerabilities
trivy scan --severity HIGH,CRITICAL

# 4. Supply chain secrets (GitHub/GitLab)
gh secret list --repo owner/repo
```

**Alerting:**

```yaml
Alerts:
  - Certificate expires in 30 days: Warning
  - Certificate expires in 7 days: Alert
  - Certificate expires in 1 day: Critical
  - Secret access denied (revoked): Critical
```

## Emergency Revocation

### Break-Glass Procedure

**When a secret is compromised:**

```
1. REVOKE IMMEDIATELY (0-5 min)
   vault revoke secret/my-api-key
   
2. ALERT STAKEHOLDERS (0-5 min)
   - Email: Affected team, security team
   - Slack: #security channel (public notification)
   - Incident: Create incident ticket
   
3. INVESTIGATE (5-30 min)
   - Review audit logs: Who accessed secret?
   - Check: When was it compromised?
   - Determine: Was it used for unauthorized activity?
   
4. MITIGATE (30 min - 2 hours)
   - Generate new secret
   - Deploy new secret to all systems
   - Verify systems reconnect successfully
   - Monitor for errors
   
5. DOCUMENT (2-4 hours)
   - Post-incident review: Root cause
   - Update security controls (e.g., rotate more frequently)
   - Communicate remediation to stakeholders
```

### Break-Glass Access (Emergency)

For high-security scenarios where normal Vault access is compromised:

```yaml
Break-Glass Credentials:
  - Stored in encrypted USB (physical safe/vault)
  - Known only to 2-3 high-trust individuals
  - Used ONLY in emergency (coordinator + witness)
  - All actions logged to external system
  - Rotated annually (unplanned use = immediate rotation)

Example Break-Glass Procedure:
  1. Incident commander confirms emergency
  2. Request 2 break-glass signatories
  3. Retrieve encrypted USB from safe
  4. Decrypt using shared passphrase + hardware token
  5. Use credentials to access Vault/systems
  6. Log all actions to external audit system
  7. Return USB to safe
  8. Rotate break-glass credentials within 24 hours
```

## Never Commit Secrets

### Pre-Commit Hooks

Use `pre-commit` framework to prevent secret commits:

```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
    - id: detect-secrets
      args: ['--baseline', '.secrets.baseline']
  
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    - id: detect-private-key
```

**Install:**
```bash
pip install pre-commit detect-secrets
pre-commit install
pre-commit run --all-files
```

### Git Configuration

```bash
# Configure .gitignore patterns
echo ".env" >> .gitignore
echo "*.pem" >> .gitignore
echo "*.key" >> .gitignore
echo "secrets/" >> .gitignore

# Prevent force-push (prevent secret deletion)
git config receive.denyForcePushes true
```

### Compliance Mappings

### SOC2 CC6.1 — Logical and Physical Access Controls

Demonstrate:
- Secrets stored in encrypted vault
- Access restricted by role (least privilege)
- Audit trail of all access attempts
- Automatic revocation policies in place

### HIPAA Security Rule §164.308(a)(3)(ii)(B) — Encryption/Decryption

Encrypt secrets at rest:
- Vault encryption: AES-256-GCM
- Database: column-level encryption for credentials
- Transmission: TLS 1.3+ for all secret access

### PCI-DSS Requirement 8.2.3 — Strong Cryptography

Use strong encryption for credential storage:
- 256-bit keys minimum
- FIPS 140-2 compliance for cryptographic modules
- Regular key rotation (minimum annually)

## References

- [NIST SP 800-57 Part 1 — Recommendation for Key Management](https://doi.org/10.6028/NIST.SP.800-57pt1r5)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [CIS Controls v8 — Control 3.13 & 3.14 (Cryptographic Key Management)](https://www.cisecurity.org/controls)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
