# Release Verification Checklist

**Audience:** Release engineer or on-call operator  
**Purpose:** Gate-check before merging to `main` and verify a successful production deployment  
**Estimated time:** 15–20 minutes  
**Related:** [Rollback Playbook](./rollback-playbook.md) | [CI/CD Reference](../GITHUB-ACTIONS.md) | [First Deployment Runbook](../FIRST-DEPLOYMENT-RUNBOOK.md)

---

## 1. Pre-Deploy Gates

Complete every item before merging the PR to `main`. A failed gate **blocks the merge**.

### 1.1 CI Pipeline

| Check | Where to verify | Pass criteria |
|---|---|---|
| CI workflow green on the PR | GitHub Actions → **CI** tab for the PR | All jobs pass (`npm ci`, `npm test`) |
| No skipped tests | CI run logs | Zero skipped or pending test cases |
| Branch up to date with `main` | GitHub PR page | "This branch has no conflicts with the base branch" |

### 1.2 Code Review

| Check | Where to verify | Pass criteria |
|---|---|---|
| PR approved | GitHub PR → Reviews | ≥ 1 approving review |
| All review comments resolved | GitHub PR → Conversations | 0 unresolved threads |
| No `TODO` / `FIXME` left in touched files | `grep -r "TODO\|FIXME" src/ server.js app.js` | Returns nothing |

### 1.3 Security

| Check | How to verify | Pass criteria |
|---|---|---|
| No critical/high security findings unresolved | GitHub Security → Code scanning | Zero open critical or high alerts in the PR diff |
| No secrets in the diff | Review PR file changes | No plaintext credentials, tokens, or connection strings |
| Dependency audit clean | `npm audit --audit-level=high` on the PR branch | Zero high or critical advisories |

### 1.4 Database Migration Review

All SQL scripts under `sql/` must be reviewed before merging:

| Check | How to verify | Pass criteria |
|---|---|---|
| Migration scripts are additive | Inspect new `sql/` files in the diff | No destructive `DROP TABLE` / `DELETE` without an `IF EXISTS` guard |
| Migrations are backward-compatible | Code review: old app version still works against new schema | Yes — no column renames or type changes that break running instances |
| Migration tested against non-prod | Manual run or prior staging deploy | Script completes without error |

### 1.5 GitHub Secrets and Variables

Confirm the following are configured in **Settings → Secrets and variables → Actions** for `ivegamsft/Capacity-Planning-Dashboard` before the first deploy and after any rotation:

```bash
# Confirm variables (non-sensitive identifiers)
gh api repos/ivegamsft/Capacity-Planning-Dashboard/actions/variables \
  --jq '[.variables[].name] | sort'
# Expected: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

# Confirm secrets (sensitive resource identifiers)
gh secret list --repo ivegamsft/Capacity-Planning-Dashboard
# Expected: AZURE_WEBAPP_NAME, AZURE_RESOURCE_GROUP
```

| Name | Type | Purpose |
|---|---|---|
| `AZURE_CLIENT_ID` | Variable | OIDC service principal app (client) ID |
| `AZURE_TENANT_ID` | Variable | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Variable | Azure subscription GUID |
| `AZURE_WEBAPP_NAME` | Secret | App Service name (e.g. `app-capdash-prod-prod01`) |
| `AZURE_RESOURCE_GROUP` | Secret | Resource group containing the App Service |

---

## 2. Merge and Deploy Trigger

Once all pre-deploy gates pass, merge via GitHub UI (squash merge preferred):

```bash
# Merge the PR (squash)
gh pr merge <PR_NUMBER> --repo ivegamsft/Capacity-Planning-Dashboard --squash --delete-branch

# Confirm the deploy workflow fired
gh run list --repo ivegamsft/Capacity-Planning-Dashboard --workflow deploy.yml --limit 3
```

The **Deploy Capacity Dashboard** workflow starts automatically on push to `main` via the `push` trigger. Monitor it at:  
**GitHub → Actions → Deploy Capacity Dashboard → latest run**

---

## 3. Post-Deploy Smoke Tests

Run the following checks in order **within 10 minutes** of the deploy workflow completing.  
If any check fails, execute the [Rollback Playbook](./rollback-playbook.md) immediately.

### 3.1 Workflow Completion

```bash
# Confirm both jobs succeeded
gh run list --repo ivegamsft/Capacity-Planning-Dashboard --workflow deploy.yml --limit 1
```

Expected status: **success** on both `build-and-test` and `deploy` jobs.

### 3.2 App Service Running

```bash
WEBAPP_NAME="<value of AZURE_WEBAPP_NAME secret>"
RG="<value of AZURE_RESOURCE_GROUP secret>"

az webapp show -n "$WEBAPP_NAME" -g "$RG" --query state -o tsv
# Expected: Running
```

### 3.3 Health Check Endpoint

```bash
APP_URL="https://<your-app-service-hostname>.azurewebsites.net"

curl -sf "$APP_URL/healthz"
# Expected HTTP 200 with body: {"status":"ok"}
```

> **Known gap:** The `/healthz` endpoint implementation is tracked in issue [#10](https://github.com/ivegamsft/Capacity-Planning-Dashboard/issues/10). Until it ships, substitute with `curl -I "$APP_URL/"` and confirm `HTTP/2 200`.

### 3.4 Dashboard UI

Open `$APP_URL` in a browser and verify:

- [ ] Dashboard page loads without a JavaScript console error
- [ ] Capacity grid renders with at least one data row (not empty / error state)
- [ ] Region, resource type, and SKU family filters respond without errors

### 3.5 Ingestion Status Widget

On the dashboard:

- [ ] Ingestion status widget displays a **last ingest timestamp** (not an error banner)
- [ ] Timestamp is within the expected ingestion interval (check `INGEST_CRON_SCHEDULE` app setting)

### 3.6 Admin Panel Access

Log in with a user who is a member of the Entra admin group (`ADMIN_GROUP_ID`):

- [ ] Admin panel link is visible and accessible
- [ ] A non-admin account cannot reach the admin panel (returns 403 or redirect)

### 3.7 SQL Migration Logged

Confirm the migration ran successfully by querying the operation log:

```sql
SELECT TOP 5
    OperationName,
    OperationStatus,
    CreatedAt,
    Details
FROM dbo.DashboardOperationLog
ORDER BY CreatedAt DESC;
```

Expected: a row with `OperationName` matching the migration step and `OperationStatus = 'Success'` at a timestamp matching the deploy window.

### 3.8 App Insights — No Exception Spike

In the Azure Portal → App Insights → **Failures** blade:

- [ ] No new exception types appeared in the 5-minute window after deploy
- [ ] Exception rate is within the pre-deploy baseline

Quick CLI check:

```bash
az monitor app-insights query \
  --app "<app-insights-name>" \
  --resource-group "$RG" \
  --analytics-query "exceptions | where timestamp > ago(10m) | summarize count() by type | order by count_ desc" \
  --output table
```

### 3.9 Export Smoke Test

- [ ] Navigate to a data view with results
- [ ] Trigger a CSV download
- [ ] Confirm the file downloads, is non-empty, and opens correctly

---

## 4. Sign-Off

After all smoke tests pass, paste the following block as a comment on the merged PR:

```
## ✅ Release Verified

**Deploy run:** <link to GitHub Actions run>
**Verified by:** @<your-github-handle>
**Verified at:** YYYY-MM-DD HH:MM UTC

### Smoke test results

| Check | Status |
|---|---|
| Workflow completed (success) | ✅ / ❌ |
| App Service Running | ✅ / ❌ |
| Health check `/healthz` | ✅ / ❌ |
| Dashboard UI loads with data | ✅ / ❌ |
| Ingestion status widget OK | ✅ / ❌ |
| Admin panel accessible | ✅ / ❌ |
| SQL migration logged | ✅ / ❌ |
| No App Insights exception spike | ✅ / ❌ |
| Export CSV downloads | ✅ / ❌ |

### Notes

<any deviations, follow-up issues filed, or known transient failures>
```

---

## 5. Known Gaps

| Gap | Tracking issue |
|---|---|
| `/healthz` endpoint not yet implemented; health check falls back to root `/` HTTP 200 | [#10](https://github.com/ivegamsft/Capacity-Planning-Dashboard/issues/10) |
| No automated post-deploy smoke test runner; all checks above are manual | File a new issue to track automation |
| App Insights query requires the `application-insights` Azure CLI extension — install with `az extension add --name application-insights` | — |
