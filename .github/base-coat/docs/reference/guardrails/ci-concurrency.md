# CI/CD Concurrency Settings

> **Rule:** Use conditional `cancel-in-progress` based on event type. Never unconditionally cancel workflow runs.

## Default Pattern

All CI workflows should use conditional cancellation — cancel redundant runs for pull requests but preserve every run on the default branch:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

## Rationale

| Scenario | Why |
|----------|-----|
| **PR pushes** | Rapid force-pushes make earlier runs obsolete; cancelling saves runner minutes. |
| **Push to main** | Every merge commit should complete CI to maintain a reliable status history and avoid missed regressions. |
| **Deploy workflows** | Cancelling a deploy mid-flight can leave environments in an inconsistent state. |
| **DB migrations** | Cancelling mid-migration corrupts schema state (see [db-deployment-concurrency](db-deployment-concurrency.md)). |

## Workflow-Type Guidance

### Build / Lint / Test Workflows

Use the conditional pattern. PR runs are safe to cancel; main-branch runs are not.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

### Deploy Workflows

Always set `cancel-in-progress: false`. Deployments must run to completion regardless of event type.

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: false
```

### DB Migration Workflows

Always set `cancel-in-progress: false`. See [db-deployment-concurrency.md](db-deployment-concurrency.md) for full details including serialisation requirements.

```yaml
concurrency:
  group: db-migrate-${{ github.ref }}
  cancel-in-progress: false
```

## Anti-Pattern

Do **not** use unconditional `cancel-in-progress: true`:

```yaml
# ❌ BAD — cancels main-branch runs, causing gaps in CI history
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

This creates race conditions when multiple PRs merge in quick succession — earlier runs are cancelled before reporting status, hiding regressions.

## Quick Reference

| Workflow type | `cancel-in-progress` value |
|--------------|---------------------------|
| Build / lint / test | `${{ github.event_name == 'pull_request' }}` |
| Deploy | `false` — always |
| DB migration | `false` — always |
| Scheduled / cron | `false` — each run represents a unique point in time |
