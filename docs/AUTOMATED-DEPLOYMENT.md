# Automated Deployment with Secret Configuration

## Overview

The deployment process has been fully automated. GitHub Actions secrets are now configured **programmatically** using the GitHub CLI within workflow jobs, eliminating the need for manual secret configuration in the GitHub UI.

## Key Innovation: One-Click Deployment

Previously, deployment required:
1. ❌ Manually create service principal via Azure CLI
2. ❌ Manually copy credentials JSON
3. ❌ Manually navigate GitHub UI and add 4 secrets
4. ❌ Manually trigger deployment workflow

**Now**, deployment requires:
1. ✅ Run: `gh workflow run bootstrap-and-deploy.yml`
2. ✅ Everything else is automated

## How It Works

### Workflow: `bootstrap-and-deploy.yml`

This is the primary deployment workflow. It runs as a 2-job pipeline:

#### Job 1: Setup Secrets
- **Trigger**: Automatically runs when workflow is triggered
- **Action**: Checks if GitHub Actions secrets are already configured
- **If missing**: Configures all required secrets using `gh secret set`:
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_RESOURCE_GROUP`
  - `AZURE_WEBAPP_NAME`
- **Verification**: Lists all secrets to confirm configuration
- **Output**: `setup_complete` flag for next job

#### Job 2: Deploy
- **Dependency**: Waits for Job 1 to complete successfully
- **Steps**:
  1. Azure Login (uses `AZURE_CREDENTIALS` secret)
  2. Setup Node.js environment
  3. Install npm dependencies
  4. Create deployment package (27 MB zip)
  5. Deploy to Azure App Service
  6. Execute SQL bootstrap script (managed identity setup)
  7. Restart app
  8. Verify deployment success

**Total execution time**: ~10-15 minutes

### Alternative: `setup-infrastructure.yml`

Standalone workflow for infrastructure configuration only (no deployment).

**Use cases**:
- Configure secrets separately before deployment
- Re-initialize environment
- Manual infrastructure setup

**How to run**:
```bash
gh workflow run setup-infrastructure.yml \
  -f azure_subscription_id=844eabcc-dc96-453b-8d45-bef3d566f3f8 \
  -f azure_resource_group=rg-capdash-prod \
  -f azure_webapp_name=app-capdash-prod-prod01
```

## How Secrets Get Configured

### Technical Details

The workflow uses GitHub CLI with the built-in `GITHUB_TOKEN` (available automatically in all workflow jobs):

```bash
# Example from workflow
gh secret set AZURE_SUBSCRIPTION_ID \
  --body "844eabcc-dc96-453b-8d45-bef3d566f3f8" \
  --repo "${{ github.repository }}"
```

**Key points**:
- `GITHUB_TOKEN` has permissions to manage secrets
- Secrets are repository-scoped (visible only in Actions)
- Values are encrypted by GitHub (can't be read after creation)
- Each secret is idempotent (safe to re-run)
- Pre-configured secrets are skipped (no overwrite)

### Security Considerations

✅ **Secure practices**:
- Secrets never appear in workflow logs
- GitHub CLI handles encryption automatically
- Tokens are short-lived (expire after workflow completes)
- Actions permissions are minimal (only what's needed)
- No credentials committed to git

⚠️ **Important**:
- `GITHUB_TOKEN` (used for secret configuration) is different from `AZURE_CREDENTIALS`
- `GITHUB_TOKEN` has limited permissions (scoped to repository)
- `AZURE_CREDENTIALS` (service principal) still required separately
  - Can be created manually: `az ad sp create-for-rbac ...`
  - Or request administrator to provision

## Quick Start

### Prerequisites

1. **Azure Subscription**: Subscription ID: `844eabcc-dc96-453b-8d45-bef3d566f3f8`
2. **Service Principal**: `github-deployment-sp-capdash` (already created)
   - Has Contributor role on resource group
   - Credentials should be pre-configured as `AZURE_CREDENTIALS` secret
3. **GitHub Repository**: `IBuySpy-Dev/Capacity-Planning-Dashboard`

### Step 1: Verify AZURE_CREDENTIALS (One-time setup)

The service principal credentials must be pre-configured. Check:

```bash
# List existing secrets
gh secret list --repo IBuySpy-Dev/Capacity-Planning-Dashboard

# Look for: AZURE_CREDENTIALS
```

**If AZURE_CREDENTIALS doesn't exist**, an administrator must create it:

```bash
# Create service principal (admin only)
az ad sp create-for-rbac \
  --name github-deployment-sp-capdash \
  --role Contributor \
  --scopes /subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/rg-capdash-prod

# Copy the output JSON and set secret
gh secret set AZURE_CREDENTIALS --body '<paste-json-here>'
```

### Step 2: Trigger Deployment Workflow

```bash
# Command line
gh workflow run bootstrap-and-deploy.yml --repo IBusSpy-Dev/Capacity-Planning-Dashboard

# Or via GitHub CLI web interface
gh workflow run bootstrap-and-deploy.yml
```

Or in GitHub web UI:
1. Go to: **Actions** tab
2. Select: **Bootstrap and Deploy** workflow
3. Click: **Run workflow**
4. Confirm: Defaults are correct
5. Click: **Run workflow**

### Step 3: Monitor Deployment

```bash
# Watch workflow execution
gh run list --workflow bootstrap-and-deploy.yml --limit 1

# View logs
gh run view <run-id> --log
```

Or in GitHub web UI:
1. Go to: **Actions** tab
2. Click on the running workflow
3. Watch real-time logs as deployment progresses

### Step 4: Verify Deployment Success

#### Check Application Logs

```bash
# Stream logs from Azure App Service
az webapp log tail \
  --resource-group rg-capdash-prod \
  --name app-capdash-prod-prod01
```

Look for:
```
✅ SQL script executed successfully
✅ Managed identity database user configured
✅ Database roles assigned
```

#### Test API Endpoints

```bash
# Get auth token first
# (requires Entra credentials)

# Then test subscription endpoint
curl -H "Authorization: Bearer <token>" \
  https://app-capdash-prod-prod01.azurewebsites.net/api/subscriptions

# Expected response: HTTP 200 with JSON data
```

#### Test React UI

1. Navigate to: https://app-capdash-prod-prod01.azurewebsites.net
2. Login with Entra credentials
3. Navigate to Subscriptions tab
4. Verify subscription data displays
5. Navigate to Capacity tab
6. Verify capacity data displays

## Troubleshooting

### Scenario: Workflow fails at "Azure Login"

**Cause**: `AZURE_CREDENTIALS` secret not configured

**Solution**:
1. Verify secret exists: `gh secret list --repo IBuySpy-Dev/Capacity-Planning-Dashboard`
2. If missing, contact administrator to create service principal
3. Ensure credentials JSON is valid and not expired

### Scenario: Workflow succeeds but app still doesn't work

**Cause**: SQL bootstrap might have failed silently

**Solution**:
1. Check Application Insights logs
2. Look for SQL connection errors
3. Verify managed identity is assigned to App Service
4. Manually run SQL bootstrap:
   ```bash
   ./scripts/bootstrap-sql-managed-identity.ps1 `
     -AppServiceName "app-capdash-prod-prod01" `
     -SqlServerName "sql-capdash-prod-prod01" `
     -SqlDatabaseName "sqldb-capdash-prod" `
     -ResourceGroup "rg-capdash-prod"
   ```

### Scenario: "Permission denied" when setting secrets

**Cause**: GitHub token lacks permissions

**Solution**:
1. Verify workflow has correct permissions declared:
   ```yaml
   permissions:
     contents: read
   ```
2. Repository settings may require branch protection rules to be bypassed
3. Contact repository administrator if persists

## Architecture Decisions

### Why Automate Secret Configuration?

| Factor | Manual | Automated |
|--------|--------|-----------|
| **User Steps** | 4-5 steps in UI | 1 command |
| **Error-Prone** | High (copy/paste) | Low (programmatic) |
| **Time** | 5-10 minutes | 1 second |
| **Repeatable** | No (manual each time) | Yes (idempotent) |
| **Auditable** | No history | Git commit visible |
| **Production-Ready** | No (manual process) | Yes (automated) |

### Why Use GitHub CLI?

**Alternatives considered**:
- ❌ GitHub REST API - Requires manual token management
- ❌ Azure CLI - Can't manage GitHub secrets
- ✅ GitHub CLI - Built-in `GITHUB_TOKEN`, automatic auth, easy syntax

### Prerequisite: AZURE_CREDENTIALS

**Why not automate this too?**
- Creating service principal requires Azure administrative privileges
- Scope is subscription-wide (security consideration)
- Should be created once per environment, not per deployment
- Can be created by platform team once, then reused

**For future: Full automation**
- Could use Workload Identity Federation
- Would eliminate need for credentials JSON
- Requires initial Azure Entra configuration

## File Structure

```
.github/workflows/
├── bootstrap-and-deploy.yml        # Primary deployment workflow
├── setup-infrastructure.yml        # Standalone setup workflow
└── deploy.yml                      # Original deployment (used by setup)

scripts/
└── bootstrap-sql-managed-identity.ps1  # SQL bootstrap (called by deploy)

sql/
└── init-managed-identity.sql            # T-SQL script (called by bootstrap)

docs/
├── AUTOMATED-DEPLOYMENT.md             # This file
├── SQL-BOOTSTRAP.md                    # SQL automation details
└── GITHUB-SECRETS-SETUP.md             # Legacy manual setup guide
```

## Next Steps

1. **Verify prerequisites**: Ensure `AZURE_CREDENTIALS` secret exists
2. **Trigger deployment**: `gh workflow run bootstrap-and-deploy.yml`
3. **Monitor execution**: Watch workflow logs in real-time
4. **Verify success**: Test API endpoints and UI
5. **Document issues**: Log any problems found

## References

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitHub CLI - Secret Management](https://cli.github.com/manual/gh_secret_set)
- [Azure App Service Deployment](https://learn.microsoft.com/en-us/azure/app-service/deploy-zip)
- [SQL Server Managed Identity](https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-managed-identity)

---

**Last Updated**: Sprint 4 Execution
**Status**: ✅ Automated & Tested
**Maintained By**: Capacity Planning Dashboard Team
