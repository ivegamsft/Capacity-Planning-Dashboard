## Rate Limiting in Sprint Execution

This guide provides practical strategies for managing GitHub API rate limits during rapid sprint execution, automation workflows, and batch operations.

### Quick Facts

- **Authenticated rate limit:** 5,000 requests per hour
- **Per-minute average:** ~83 requests per minute
- **Reset window:** Hourly (UTC-based)
- **Critical threshold:** ≤ 50 remaining requests triggers exponential backoff
- **Warning threshold:** ≤ 200 remaining requests logs a warning

### Rate Limit Context

The GitHub REST API enforces rate limits per **authenticated user or OAuth token**, not per repository or organization. This means:

- All API calls against `owner/repo` count toward **your** token's quota
- CI/CD workflows using repository secrets inherit the quota from that token
- Concurrent API calls from multiple scripts/agents deplete quota faster than sequential calls
- Each workflow dispatch, issue creation, comment, label assignment, and PR check consumes quota

During sprint execution with multiple workflows, agents making API calls, and batch operations, it's easy to exhaust 5,000 requests in minutes, leading to:
- Blocked PRs (checks hang waiting for rate limit reset)
- Failed deployments (workflow dispatch throttled)
- Stalled agent operations (API calls time out)

### Sprint Execution Guidance: 60-Second Minimum Spacing

**Rule:** Space major API-consuming operations ≥ 60 seconds apart.

**Major operations include:**
- Workflow dispatch (`gh workflow run`)
- Creating issues/PRs
- Bulk label assignments
- Running validation scripts with multiple API calls
- Triggering status checks

**Why 60 seconds?**
- Leaves headroom for background polling (code review agents, metrics collection)
- Allows `gh` CLI automatic retries to complete
- Gives rate limit headers time to update
- Prevents CI queue buildup

**Example sprint sequence:**

```
10:00:00 — Dispatch workflow 1 (API: ~5 requests)
10:01:00 — Create issue with labels (API: ~3 requests)
10:02:00 — Dispatch workflow 2 (API: ~5 requests)
10:03:00 — Run validation script (API: ~20 requests)
10:04:00 — Create PR (API: ~4 requests)
---
Total: 10 minutes elapsed, ~37 API requests (well under 83/min average)
```

### Polling Strategies with Exponential Backoff

**Scenario:** You're polling a workflow run status until it completes.

**Backoff formula:**
```
delay = min(initialDelay * (multiplier ^ attempt), maxDelay)
Initial: 30 seconds
Multiplier: 1.5
Max delay: 90 seconds
```

**Sequence:**
```
Attempt 1: Wait 30s, then poll
Attempt 2: Wait 45s, then poll
Attempt 3: Wait 67.5s, then poll
Attempt 4+: Wait 90s, then poll
```

**PowerShell example:**

```powershell
function Invoke-WithExponentialBackoff {
    param(
        [scriptblock]$Action,
        [int]$MaxAttempts = 5,
        [int]$InitialDelaySeconds = 30,
        [decimal]$Multiplier = 1.5,
        [int]$MaxDelaySeconds = 90
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return & $Action
        } catch {
            if ($attempt -eq $MaxAttempts) { throw }

            $delay = [math]::Min(
                $InitialDelaySeconds * [math]::Pow($Multiplier, $attempt - 1),
                $MaxDelaySeconds
            )

            Write-Warning "Attempt $attempt failed. Waiting $($delay)s before retry..."
            Start-Sleep -Seconds $delay
        }
    }
}

# Usage
$result = Invoke-WithExponentialBackoff {
    gh api repos/owner/repo/actions/runs/12345 --jq '.status'
}
```

### Batch Operations: 5 per 60 Seconds

**Rule:** Don't fire more than 5 API-consuming operations in a 60-second window.

**Guidance:**

| Operation Type | Requests per Call | Max Batch Size | Recommended Interval |
|---|---|---|---|
| Workflow dispatch | 2–5 | 5 | 60s between batches |
| Issue creation | 3–5 (with labels) | 5 | 60s between batches |
| PR comment | 1–2 | 10 | 30s between batches |
| Label assignment | 1 | 20 | 10s between batches |

**Example: Dispatching 20 workflow runs**

```powershell
$workflows = @( "ci.yml", "test.yml", "build.yml", "deploy.yml", "validate.yml" )
$dispatch = $workflows * 4  # repeat 4 times for 20 total

for ($i = 0; $i -lt $dispatch.Count; $i += 5) {
    $batch = $dispatch[$i..($i + 4)]  # take 5 at a time

    foreach ($wf in $batch) {
        Write-Host "Dispatching $wf..."
        gh workflow run $wf --ref main
    }

    if ($i + 5 -lt $dispatch.Count) {
        Write-Host "Batch complete. Waiting 60s before next batch..."
        Start-Sleep -Seconds 60
    }
}
```

**Expected duration:** 20 runs × 2 requests each = 40 API calls, distributed over 4 batches × 60s = ~4 minutes.

### Logging Rate Limit Headers

**Every automation script should log rate limit information for debugging.**

**PowerShell pattern:**

```powershell
function Get-ApiWithRateLimitLogging {
    param([string]$Endpoint)

    $response = gh api $Endpoint --include 'headers' 2>&1
    $headers = $response | Select-Object -Last 10

    # Extract rate limit info
    $remaining = $headers | grep -i "x-ratelimit-remaining" | cut -d' ' -f2
    $reset = $headers | grep -i "x-ratelimit-reset" | cut -d' ' -f2
    $limit = $headers | grep -i "x-ratelimit-limit" | cut -d' ' -f2

    Write-Host "Rate limit: $remaining / $limit remaining (resets at $reset)"

    if ($remaining -lt 50) {
        $resetTime = [DateTime]::UnixEpoch.AddSeconds($reset)
        Write-Error "Critical: Only $remaining requests remaining! Resetting at $resetTime"
        Start-Sleep -Seconds ([math]::Max(0, ($resetTime - [DateTime]::UtcNow).TotalSeconds + 5))
    }
    elseif ($remaining -lt 200) {
        Write-Warning "Warning: Only $remaining requests remaining in quota"
    }

    return $response
}
```

**CI/CD integration (GitHub Actions):**

```yaml
- name: Check rate limit before batch operations
  run: |
    REMAINING=$(gh api rate_limit --jq '.rate.remaining')
    LIMIT=$(gh api rate_limit --jq '.rate.limit')
    RESET=$(gh api rate_limit --jq '.rate.reset')
    echo "Rate limit: $REMAINING / $LIMIT (resets at $(date -d @$RESET))"

    if [ $REMAINING -lt 50 ]; then
      echo "ERROR: Only $REMAINING requests remaining!"
      exit 1
    fi
```

### Rate Limit Headers Explained

| Header | Meaning | Action |
|---|---|---|
| `X-RateLimit-Limit` | Total quota this window | Monitor for changes (usually 5000) |
| `X-RateLimit-Remaining` | Requests left | Pause if < 50; warn if < 200 |
| `X-RateLimit-Used` | Requests consumed | Track for reporting |
| `X-RateLimit-Reset` | Unix timestamp of reset | Wait until this time if exhausted |
| `X-RateLimit-Resource` | Quota being tracked | Usually `core` for REST API |

**CLI commands to inspect:**

```powershell
# Check current quota
gh api rate_limit

# Parse structured output
gh api rate_limit --jq '.rate | "Used: \(.used), Remaining: \(.remaining), Reset: \(.reset)"'

# Monitor rate limit in a loop (useful during batch operations)
for ($i = 0; $i -lt 10; $i++) {
    $remaining = $(gh api rate_limit --jq '.rate.remaining')
    Write-Host "[$(Get-Date)] Remaining: $remaining"
    Start-Sleep -Seconds 10
}
```

### Practical Example: Sprint Validation Script

Imagine you're validating 50 repositories. Here's a robust approach:

```powershell
function Validate-RepositoriesSafely {
    param(
        [string[]]$Repos,
        [int]$BatchSize = 5,
        [int]$BatchIntervalSeconds = 60
    )

    for ($i = 0; $i -lt $Repos.Count; $i += $BatchSize) {
        $batch = $Repos[$i..($i + $BatchSize - 1)]

        Write-Host "Processing batch: $($i / $BatchSize + 1) / $([math]::Ceiling($Repos.Count / $BatchSize))"

        # Check rate limit before batch
        $remaining = $(gh api rate_limit --jq '.rate.remaining')
        if ($remaining -lt 50) {
            Write-Error "Quota exhausted. Aborting."
            exit 1
        }

        foreach ($repo in $batch) {
            Write-Host "  Validating $repo..."
            gh api repos/$repo --jq '.description'
        }

        if ($i + $BatchSize -lt $Repos.Count) {
            Write-Host "Batch complete. Waiting $BatchIntervalSeconds seconds before next batch..."
            Start-Sleep -Seconds $BatchIntervalSeconds
        }
    }

    Write-Host "All repositories validated successfully."
}
```

### Common Failure Modes

| Symptom | Root Cause | Fix |
|---|---|---|
| "API rate limit exceeded" error mid-sprint | Concurrent scripts, no backoff | Implement backoff; space operations 60s apart |
| PR checks hang for 1 hour | Rate limit exhausted, auto-reset pending | Check rate limit before workflows; add quota buffer |
| Workflow dispatch "pending" forever | Status check polling depleted quota | Reduce polling frequency; increase backoff delay |
| Flaky tests due to timeout | Script waiting for rate limit reset | Add exponential backoff; log rate limit headers |

### Checklist for Sprint Planning

- [ ] All polling scripts implement exponential backoff (30–90s)
- [ ] Workflow dispatches are spaced ≥ 60s apart
- [ ] Batch operations respect 5-per-60s limit
- [ ] Rate limit check runs before major operations (e.g., `gh api rate_limit`)
- [ ] Rate limit headers are logged in CI (for debugging throttling issues)
- [ ] If ≥ 200 workflows run in sprint, consider using GitHub Apps (separate quota)
- [ ] Dry-run test with `--dry-run` flag where available before production run

### Related Issues

- **#451** — Concurrency control: Coordinating parallel batch operations without quota collision
- **#443** — Observed problem: Sprint execution blocked due to rate limit exhaustion; caused by unspaced workflow dispatches

### References

- [GitHub REST API Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api?apiVersion=2022-11-28#rate-limiting)
- [GitHub CLI (`gh`) Documentation](https://cli.github.com/manual/gh_api)
- [GitHub Actions Rate Limiting](https://docs.github.com/en/actions/reference/usage-limits-billing-and-administration)
