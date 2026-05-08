---
description: "L2 memory index. Loads at session start to prime fast pattern recall. Maps trigger contexts to known high-confidence patterns and subject tags for deeper retrieval. Keep under 500 tokens — index only, no full memories."
applyTo: "**/*"
---

# Memory Index — L2 Hot Cache

> **For forks of BaseCoat:** This file ships with BaseCoat's own patterns as a reference implementation. Replace the Trigger Map and Pattern Bundle Catalog with your team's patterns. The Memory Hierarchy and Promotion Ladder sections are framework guidance — keep those. Your accumulated memories (SQLite store, session state) are yours alone and are git-ignored — they never travel upstream.

This file is the L2 tier of the BaseCoat memory hierarchy. It loads automatically to prime fast recall before any task starts. It contains trigger-to-subject mappings and the highest-confidence patterns that recur across sprints.

**Rule:** Do not inline full memories here. List the pattern in one line and the subject tag. Full retrieval goes to L3/L4.

## Memory Hierarchy

| Tier | Name | Mechanism | Lookup cost |
|---|---|---|---|
| L0 | Reflexes | Hard rules in frontmatter + always-on instructions | Zero — baked in |
| L1 | Procedural | `applyTo: **/*` instruction files | Zero — always loaded |
| L2 | Team Hot Index | This file — trigger → pattern/subject map | ~400 tokens at session start |
| L2s | Shared Hot Index | `{org}/basecoat-memory/hot-index.md` (if configured) | ~400 tokens at session start |
| L3 | Episodic | `session_store_sql` — recent session history | 1 tool call, ~200–500 tokens |
| L3s | Shared Deep | `memories/{domain}/*.md` from shared repo (cached) | On demand, per domain |
| L4 | Semantic | `store_memory` recall + `docs/` reference | 1–2 tool calls, load on demand |

**Shared memory** (`L2s`/`L3s`) requires `BASECOAT_SHARED_MEMORY_REPO` to be set and `pwsh scripts/sync-shared-memory.ps1` to have been run. Memories are cached locally with a 24-hour TTL and are git-ignored — they never travel with the repo. See `docs/shared-memory.md`.

### Promotion Ladder

Patterns move up through use; stale patterns move down.

```
L4 store_memory accessed 3+ times across sessions → promote to L2 index entry
L2 entry applied 5+ times → extract to L1 instruction file rule
L1 rule applied in >50% of sessions → consider L0 (agent frontmatter)
L1 rule not applied in 90 days → demote back to L2 or prune
L2 entry not referenced in 60 days → demote to L4 or prune
```

**Pinned patterns** (security, governance, hard constraints) are exempt from decay. Mark with `[pin]`.

## Execution Path Routing

Before loading any context, classify intent and route:

```
confidence ≥ 0.80 → FAST PATH: load pattern bundle, skip exploration
confidence 0.50–0.79 → bundle as starting point + run Explore phase  
confidence < 0.50 → FULL PATH: layered context load, estimate N turns
```

Guardrails (Layer 1) fire at fixed checkpoints regardless of path. See `docs/execution-hierarchy.md`.

## Pattern Bundles — Fast Path Catalog

| Bundle | Trigger keywords | Turn budget | Confidence |
|---|---|---|---|
| `run-tests` | run tests, validate, check tests | 1 | 0.98 |
| `fix-lint` | lint, MD0xx, fix warnings, markdown lint | 2 | 0.92 |
| `new-agent` | new agent, create agent, add agent | 3 | 0.88 |
| `new-instruction` | new instruction, add instruction | 2 | 0.90 |
| `compile-aw` | compile, agentic workflow, gh aw compile | 2 | 0.90 |
| `merge-pr` | merge PR, dependabot, merge pull request | 3 | 0.85 |
| `release` | release, version bump, tag, CHANGELOG | 4 | 0.87 |
| `clean-branches` | clean branches, stale branches, delete merged | 2 | 0.95 |
| `portal-feature` | portal, component, hook, frontend | 5 | 0.80 |

### CI / GitHub Actions

| Trigger | Pattern | Subject |
|---|---|---|
| Edit agentic workflow | `add-labels` and `add-comment` take no sub-properties; `allowed-labels` belongs under `create-issue` | `gh-aw` |
| gh aw expressions | Allowed: `issue.number/title`, `pull_request.number/title`, `workflow_run.id/conclusion/head_sha`, `repository`, `run_number`, `actor` — fetch body/login via `gh` CLI | `gh-aw` |
| gh aw compile | Markdown body edits don't require recompile; frontmatter changes do. Run `gh aw compile <name>` | `gh-aw` |
| `workflow_run` trigger | Add `types: [completed]`; check `conclusion == 'failure'` in body | `ci-workflow` |
| Copilot agent PR | Shows `action_required` (0 jobs) — maintainer must push empty commit to trigger CI | `ci-approval` [pin] |

### Testing

| Trigger | Pattern | Subject |
|---|---|---|
| Full validation | `pwsh tests/run-tests.ps1` — runs all tests including lint and agent checks | `testing-commands` |
| Structure only | `pwsh scripts/validate-basecoat.ps1` — asset structure check without full suite | `asset-validation` |

### Authoring Assets

| Trigger | Pattern | Subject |
|---|---|---|
| New agent file | Must have `## Inputs`, `## Workflow` (or `## Process`), and output section — validated by test suite | `agent-conventions` [pin] |
| New skill | `SKILL.md` needs `name` + `description` frontmatter; `allowed_skills` must match directory name exactly | `skill-conventions` [pin] |
| Markdown lint | `##` headings only (MD036), blank lines before/after code fences (MD031), files end with newline (MD047) | `markdown-standards` |

### Portal

| Trigger | Pattern | Subject |
|---|---|---|
| Scan polling | `useScanPoller(scanId, 3000, 20)` — stops on `completed`/`failed` or maxAttempts | `portal-scan` |
| Scan backend | POST `/scans` sets `status: 'running'`; setTimeout stub → `completed` after 5s | `portal-backend` |

### Git / Branches

| Trigger | Pattern | Subject |
|---|---|---|
| Branch cleanup | Squash merges won't show as `--merged`; use `gh pr list --state all --head <branch>` to verify | `git-hygiene` |
| Worktrees | Sprint branches use separate worktrees; check with `git worktree list` | `git-worktree` |

### Turn Budget

| Trigger | Pattern | Subject |
|---|---|---|
| Starting any task | Classify Routine(≤3 turns) / Familiar(≤5) / Novel(estimate N) before starting | `turn-budget` [pin] |
| Stuck after 5 turns | `store_memory` failure pattern, change approach, do not escalate model tier first | `failure-protocol` [pin] |
| Task succeeds with novel solution | `store_memory` if non-obvious pattern + tests pass; skip for boilerplate | `success-protocol` |

## Episodic Retrieval Shortcuts (L3)

Use these queries when you need prior session context:

```sql
-- Recent sessions on a topic
SELECT id, summary, created_at FROM sessions
WHERE summary ILIKE '%<topic>%'
ORDER BY created_at DESC LIMIT 5

-- Prior failures on a pattern
SELECT t.user_message, t.assistant_response FROM turns t
JOIN sessions s ON t.session_id = s.id
WHERE s.created_at > now() - INTERVAL '30 days'
  AND t.user_message ILIKE '%<keyword>%'
LIMIT 10
```

## Maintenance Rules

Update this file when:
- `store_memory` has been called for the same subject 3+ times (promote to index)
- A gotcha has burned >2 turns in multiple sessions
- A pattern recurs across 2+ sprints

Remove an entry when:
- The pattern is now fully covered by an L1 instruction file
- The pattern hasn't applied in 2+ sprints (demote to L4 or prune)
