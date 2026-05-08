# Development Tips: Faster Agentic Sprints

Lessons learned from the 2026-04-30 sprint session. These tips apply to any Copilot CLI fleet-mode session.

## Prompt Engineering

### What worked

- **Specific, structured prompts** — Each sub-agent got a numbered checklist with exact file paths, commit messages, and branch names. Zero ambiguity meant zero back-and-forth.
- **Include validation steps** — "Run `pwsh tests/run-tests.ps1`" in every prompt prevented silent regressions.
- **Conventional commit format in prompt** — Pre-specifying the exact commit message ensured consistent history.

### What to improve

- **Scope agents narrowly** — One agent (#268) was so comprehensive it made two other agents (#269, #270) redundant. This wasted ~5 minutes of compute. Better to give each agent a focused, non-overlapping scope.
- **Include file content hints** — Agents that needed to read 10+ files (README counts) took 4x longer than surgical fixes. Pre-reading and including key file snippets in the prompt accelerates research-heavy tasks.

## Parallelism Patterns

### Maximize independence

```
✅ Good: 4 agents, each touching different files
❌ Bad: 4 agents, all editing .github/workflows/ (merge conflicts)
```

### Dependency chains should be short

```
✅ Good: A → B (1 dependency)
❌ Bad: A → B → C → D (serial bottleneck)
```

Structure work so most tasks are Phase 1 (independent) with at most one Phase 2 layer.

### Batch by file scope

Group issues that touch the same files into ONE agent to avoid conflicts:

| Pattern | Result |
|---------|--------|
| Agent A: workflows, Agent B: workflows | ❌ Merge conflict |
| Agent A: all workflows, Agent B: all scripts | ✅ Clean |

## Sprint Flow Optimization

### Current flow (worked well)

```
List issues → Prioritize → Dispatch parallel agents → Review PRs → Merge
```

### Faster flow (recommended)

```
List issues → Prioritize → Pre-read key files → Dispatch parallel agents
                                                  (with file content in prompt)
→ Review PRs → Batch merge
```

**Pre-reading saves time** because:
- Agents don't spend 30% of their time just reading files
- You catch scope overlaps before dispatching
- You can split work by file boundaries, not logical boundaries

### Merge strategy

- **Squash merge immediately** after reviewing — don't wait for all agents
- First-merged PR becomes the new baseline; later PRs may conflict
- If two PRs touch the same files, merge the more comprehensive one first and close the other

## Code Quality Audit Tips

### Run audits early, not after the sprint

Discovering issues during execution means re-prioritization mid-sprint. Better to:

1. Audit first (code scanning, secret scanning, lint)
2. File issues from findings
3. Then plan the sprint from the full issue list

### Use code scanning APIs

```bash
gh api repos/{owner}/{repo}/code-scanning/alerts
gh api repos/{owner}/{repo}/dependabot/alerts
gh api repos/{owner}/{repo}/secret-scanning/alerts
```

These catch things human review misses (like 8 missing permissions blocks).

## Agent Prompt Template

For maximum efficiency, give every sub-agent this structure:

```markdown
## Task: <one-line description> (Issue #N)

### Context
<2-3 sentences of background the agent needs>

### What to do
1. <specific step with file path>
2. <specific step>
3. <specific step>

### Branch & Commit
- Branch: `<type>/<issue>-<description>`
- Commit: `<conventional commit message>`

### Validation
- Run: `pwsh scripts/validate-basecoat.ps1`
- Run: `pwsh tests/run-tests.ps1`

### Deliverable
- Push branch, create PR with title and body
```

## Time Budget

| Activity | Typical time | Optimization |
|----------|-------------|--------------|
| Agent reading files | 30-60s | Pre-include content in prompt |
| Agent making changes | 10-30s | N/A (already fast) |
| Agent running tests | 20-40s | Only run relevant tests |
| PR review by human | 30-60s | Trust validation, spot-check diff |
| Merge | 5s | Squash immediately |

**Total per issue (optimized): ~2 minutes wall-clock with parallel dispatch.**
