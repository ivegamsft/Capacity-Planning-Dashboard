## 4-Agent Concurrency Limit for Cloud Agents

**Issue**: #451  
**Status**: Phase 2 Implementation Complete  
**Related**: #446 (rate-limit guidance), #450 (multi-agent orchestration)

### Problem

Cloud agents hit GitHub API rate limits when too many `/approve` workflows run concurrently. With 11+ simultaneous issue assignments, multiple `copilot-swe-agent` workflows execute in parallel, exhausting the 5000 req/hour quota.

### Solution Strategy

**Phase 1** (Deployed): Concurrency group in `.github/workflows/issue-approve.yml`
- Serializes `/approve` workflow invocations to prevent simultaneous assignments
- Only queues the *assignment* step; agent workflows still run concurrently if already assigned

**Phase 2** (This Implementation): Rate-limited batch assignment
- Sprint kickoff scripts respect the 4-agent ceiling
- Issues are approved in waves of 4 with delays between waves
- Rate limit checks prevent quota exhaustion

**Phase 3** (Future): Queue manager agent
- Monitors `copilot-swe-agent` workflow runs via GitHub Actions API
- Maintains 4-agent ceiling by queueing pending issues
- FIFO processing as slots free up

### Usage

#### Quick Start

```powershell
# Approve 12 issues in 3 waves of 4
.\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "444,446,448,450,451,453,455,457,459,461,463,465"
```

#### Parameters

- **IssueNumbers** (required): Comma-separated issue numbers (e.g., "444,446,448,450")
- **WaveSize** (optional): Agents per wave; default 4; range 1–10
- **InterWaveDelay** (optional): Seconds between waves; default 120; range 30–600
- **RateLimitBuffer** (optional): Min API requests to keep available; default 200; range 50–500

#### Examples

```powershell
# Custom wave size: 6 agents per wave, 180s between waves
.\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "444,446,448,450" -WaveSize 6 -InterWaveDelay 180

# Conservative: 2 agents per wave, 240s delays
.\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "444,446,448" -WaveSize 2 -InterWaveDelay 240
```

### How It Works

1. **Parse Issues**: Extract issue numbers from input
2. **Batch into Waves**: Group issues into chunks of `WaveSize` (default 4)
3. **For Each Wave**:
   - Check current rate limit (ensure `>= RateLimitBuffer`)
   - Approve each issue with 3-second spacing
   - Log results (✓ success, ✗ failure)
   - If more waves remain: Wait `InterWaveDelay` seconds before proceeding
4. **Summary**: Report total succeeded/failed

### Rate Limit Safeguards

- **Pre-Wave Check**: Before each wave, verify rate limit is available
- **Quota Protection**: If remaining requests <= buffer, wait for reset
- **Spacing Within Wave**: 3-second delay between issue approvals (prevents thundering herd)
- **Logging**: Displays remaining quota and reset times

### Integration with Sprint Workflows

**Manual kickoff** (existing teams):
```powershell
# Kick off Wave 1 (4 issues)
.\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "444,446,448,450"

# Wait for agents to initialize and process...
# Monitor: gh workflow list

# Kick off Wave 2 after agents complete (manual or automated)
.\scripts\sprint-kickoff-safe.ps1 -IssueNumbers "451,453,455,457"
```

**Automated kickoff** (via GitHub Actions):
The `sprint-kickoff` workflow can invoke this script with issue lists from sprint configuration.

### Monitoring

Once kickoff is complete:

```bash
# Check agent workflows
gh workflow list

# Monitor active runs
gh run list --workflow issue-approve.yml --status in_progress

# Check remaining API quota
gh api rate_limit --jq '.rate'

# View approved issues
gh issue list --label approved --state open
```

### Performance Expectations

- **Rate**: 4 agents assigned every `InterWaveDelay` seconds
- **Throughput**: ~1–2 agents starting per minute (after wave delays)
- **API Cost**: ~1–2 requests per issue assignment (within 5000/hour budget)
- **Total Time**: N agents × (⌈N/4⌉ × InterWaveDelay) seconds

Example: 16 issues, 4 per wave, 120s delay
- 4 waves × 120s = 480 seconds (8 minutes) + overhead

### Acceptance Criteria

- [x] Phase 2: Sprint kickoff scripts updated to batch in waves of 4
- [x] Rate-limited wave assignment with configurable parameters
- [x] Documentation updated to explain backoff policy and usage
- [x] Rate limit checks integrated into kickoff script
- [x] Tests passing (no regressions)

### Future Work

- **Phase 3**: Queue-manager agent for automatic 4-agent ceiling enforcement
- **Monitoring**: Dashboard for agent concurrency and rate limit trends
- **Auto-Tuning**: Adjust wave size and delays based on observed agent completion times
