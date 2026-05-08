# Rollback Playbook

**Audience:** On-call operator or release engineer  
**Purpose:** Guide a safe, time-bounded rollback of a failed production deployment  
**Estimated time:** 10–20 minutes end-to-end  
**Related:** [Release Verification Checklist](./release-verification.md) | [CI/CD Reference](../GITHUB-ACTIONS.md) | [First Deployment Runbook](../FIRST-DEPLOYMENT-RUNBOOK.md)

---

## 1. When to Roll Back

Use the decision table below. If any condition in the **Roll back** column is true, start the rollback procedure immediately — do not wait to investigate.

| Symptom | Roll back? | Instead consider |
|---|---|---|
| Deploy workflow failed at the `deploy` job | **Roll back** | Check logs first; if the old slot is still live, no rollback may be needed |
| App Service in `Stopped` or `Unknown` state after deploy | **Roll back** | — |
| Dashboard UI throws unhandled errors for all users | **Roll back** | — |
| SQL migration job failed mid-run and left schema partially applied | **Roll back + hotfix** | Contact DBA before re-running migration |
| Exception rate in App Insights spiked > 2× pre-deploy baseline | **Roll back** | — |
| Ingestion status widget shows persistent errors (> 5 min) | **Roll back** | Check ingestion logs; may be transient |
| Admin panel returns 500 for admin-group users | **Roll back** | — |
| Performance degradation only (p99 latency ≥ 3× baseline) | Investigate first | Roll back if not resolved within 30 min |
| Single export failure, non-reproducible | Do **not** roll back | File a bug; monitor |

---

## 2. Rollback Decision Gate

Before rolling back, answer these two questions:

1. **Is the previous artifact known-good?**  
   Check GitHub Actions for the last successful `deploy.yml` run before this one. Confirm it completed with status **success**.

2. **Is the schema backward-compatible?**  
   If the failed deploy included a database migration, a code rollback may leave the schema in a newer state than the code expects. Consult the migration diff before proceeding.

If both answers are yes → proceed to Step 3.  
If schema compatibility is uncertain → escalate before rolling back code.

---

## 3. Rollback Procedure

> **Critical:** The deploy pipeline uses `cancel-in-progress: false` for the `deploy-production` concurrency group. Never cancel a running deploy workflow — wait for it to finish (success or failure) before starting rollback.

### Step 1 — Identify the last known-good commit

```bash
# List recent successful deploys
gh run list \
  --repo ivegamsft/Capacity-Planning-Dashboard \
  --workflow deploy.yml \
  --status success \
  --limit 5

# Note the run ID of the last successful deploy, then find its commit SHA
gh run view <LAST_GOOD_RUN_ID> \
  --repo ivegamsft/Capacity-Planning-Dashboard \
  --json headSha,createdAt,displayTitle \
  --jq '{sha: .headSha, at: .createdAt, title: .displayTitle}'
```

Record the commit SHA as `$GOOD_SHA`.

### Step 2 — Create a revert commit and open a PR

```bash
git fetch origin
git checkout main
git revert HEAD --no-edit           # revert last commit
# If the bad change spans multiple commits:
# git revert <BAD_SHA_START>^..<BAD_SHA_END> --no-edit

git push origin main --force-with-lease
```

Alternatively, use the GitHub UI: **Code → Commits → \<bad commit\> → Revert**.

> **Avoid** `git push --force` to `main` without `--force-with-lease`. Always check that no one else pushed between your fetch and your push.

### Step 3 — Monitor the rollback deploy

The push to `main` triggers a new `deploy.yml` run automatically.

```bash
# Watch the new run
gh run watch --repo ivegamsft/Capacity-Planning-Dashboard

# Or check status
gh run list \
  --repo ivegamsft/Capacity-Planning-Dashboard \
  --workflow deploy.yml \
  --limit 3
```

Expected duration: same as a normal deploy (~3–5 minutes).

### Step 4 — Verify the rollback

Run the core subset of post-deploy smoke tests from the [Release Verification Checklist](./release-verification.md):

```bash
WEBAPP_NAME="<value of AZURE_WEBAPP_NAME secret>"
RG="<value of AZURE_RESOURCE_GROUP secret>"

# App Service state
az webapp show -n "$WEBAPP_NAME" -g "$RG" --query state -o tsv
# Expected: Running

# Root response (until /healthz is implemented — see issue #10)
APP_URL="https://<your-app-service-hostname>.azurewebsites.net"
curl -I "$APP_URL/"
# Expected: HTTP/2 200
```

Then check in a browser:

- [ ] Dashboard UI loads without errors
- [ ] Ingestion status widget shows a valid timestamp (not an error)
- [ ] Admin panel accessible for admin-group users

### Step 5 — Communicate status

Post a status update to the team incident channel (Teams or Slack) using this template:

```
🔄 ROLLBACK IN PROGRESS / ✅ ROLLBACK COMPLETE

Service: Capacity Planning Dashboard
Environment: Production
Time started: YYYY-MM-DD HH:MM UTC
Time resolved: YYYY-MM-DD HH:MM UTC

Bad commit: <SHA> — <title>
Rolled back to: <GOOD_SHA>

Impact: <describe user-visible impact and duration>

Next steps:
- [ ] Root cause analysis underway (see PIR issue below)
- [ ] Fix being developed in <branch>
- [ ] Re-deploy scheduled for <date/time>

PIR: <GitHub Issue link>
```

---

## 4. Escalation Contacts

Use this list when you are blocked, cannot confirm rollback success, or the incident involves data loss.

| Role | Who to contact | Channel |
|---|---|---|
| **On-call engineer** | Check the current on-call rotation | `#capdash-oncall` |
| **Repo owner / tech lead** | See `CODEOWNERS` or the GitHub repo admin list | GitHub @mention or Teams DM |
| **Azure platform / infra** | Azure subscription owner | Teams: `#azure-platform` |
| **Database admin (DBA)** | Contact for schema-related rollbacks | Teams: `#database-ops` |
| **Security** (credentials compromised) | Security team alias | `security@<your-org>.com` |

> **SLA guidance:** Response expected within 15 minutes during business hours, 30 minutes outside business hours.

---

## 5. Post-Incident Review (PIR) Template

Open a GitHub Issue using the command below **within 24 hours** of incident resolution:

```bash
gh issue create \
  --repo ivegamsft/Capacity-Planning-Dashboard \
  --title "PIR: <short incident description> — YYYY-MM-DD" \
  --label "incident,post-incident-review" \
  --body "## Post-Incident Review

**Incident date:** YYYY-MM-DD  
**Duration:** HH:MM (detected at HH:MM UTC, resolved at HH:MM UTC)  
**Severity:** P0 / P1 / P2  
**Affected component:** App Service / Database / Ingestion / Auth  

---

### Timeline

| Time (UTC) | Event |
|---|---|
| HH:MM | Deploy triggered by PR #<number> merged |
| HH:MM | First alert / user report |
| HH:MM | Rollback decision made |
| HH:MM | Rollback deploy completed |
| HH:MM | Service confirmed healthy |

---

### Root Cause

<What went wrong? Be specific — include commit SHA, config change, or dependency version.>

---

### Impact

- **Users affected:** <estimate or 'all' / 'admin only' / 'none observable'>
- **Data loss:** Yes / No
- **SLA breach:** Yes / No

---

### What Went Well

- <item>
- <item>

---

### What Went Wrong

- <item>
- <item>

---

### Action Items

| Action | Owner | Due date | Tracking issue |
|---|---|---|---|
| <Fix the root cause> | @<handle> | YYYY-MM-DD | #<issue> |
| <Add test to prevent recurrence> | @<handle> | YYYY-MM-DD | #<issue> |
| <Update runbook if needed> | @<handle> | YYYY-MM-DD | #<issue> |
"
```

---

## 6. Known Limitations

| Limitation | Notes |
|---|---|
| No deployment slots (blue/green) | The App Service is deployed directly; rollback requires a re-deploy, not a slot swap |
| `/healthz` not yet implemented | Use root `/` HTTP 200 check until issue [#10](https://github.com/ivegamsft/Capacity-Planning-Dashboard/issues/10) is resolved |
| Schema rollback not automated | If a migration ran, manual schema revert is required before code rollback is safe |
| No automated rollback trigger | All rollback decisions and actions are manual per this playbook |
