---
description: "Use when reviewing PRs, evaluating security posture, measuring performance, or enforcing coverage thresholds. Covers quality gates that every change must pass and how review agents collaborate."
applyTo: "**/*"
---

# Quality Gates and Security Standards

Use this instruction to enforce the minimum quality bar on every pull request and to coordinate the code-reviewer, security-analyst, performance-analyst, and devops agents.

## PR Review Minimum Bar

Every pull request must pass these checks before merge:

- **Correctness** — The change does what it claims. Review the diff against the linked issue or description. If the behavior cannot be verified from the diff alone, request a test or a screencast.
- **Test coverage** — New logic has tests. Bug fixes include a regression test. No test-only PRs that test nothing meaningful.
- **Error handling** — New error paths follow the standards in `development.instructions.md`. No swallowed exceptions, no generic error types, no missing context in log entries.
- **Security scan** — No new warnings from static analysis or dependency audit tools. Any pre-existing warning touched by the diff must be resolved or have a tracked issue.
- **Documentation** — Public API changes update the relevant docs. Configuration changes update the README or deployment guide.
- **Naming and style** — Variable, function, and file names are descriptive. No single-letter names outside loop counters. No commented-out code.
- **No secrets** — No credentials, tokens, API keys, PII, or connection strings anywhere in the diff, including commit messages.
- **Changelog** — Breaking changes and user-facing features have a changelog entry or release note.

A reviewer must explicitly confirm each item. "LGTM" without specifics is not a valid approval.

## Security Review Gates

A dedicated security review is required when any of the following conditions apply:

- The change modifies authentication or authorization logic.
- The change adds or alters trust boundaries (new API endpoints, new service-to-service calls, new external integrations).
- The change introduces a new dependency that handles cryptography, parsing, deserialization, or network I/O.
- The change modifies secrets management, token handling, or credential storage.
- The change touches CI/CD pipeline permissions, workflow secrets, or deployment credentials.
- The change adds user-facing input that is processed server-side (forms, file uploads, query parameters).

When a security review is required:

1. Label the PR with `security-review`.
2. The security-analyst agent must approve before merge.
3. The security-analyst documents findings inline as review comments with severity (`critical`, `high`, `medium`, `low`).
4. `critical` and `high` findings block merge. `medium` findings require a tracking issue. `low` findings are advisory.

## Performance Budgets

All changes must stay within these budgets. Any regression requires justification and a tracking issue.

| Metric | Budget | Measurement |
|---|---|---|
| Page load (LCP) | ≤ 2.5 s | Lighthouse CI on the critical user journey |
| First Input Delay (FID) | ≤ 100 ms | Lighthouse CI or Web Vitals |
| Cumulative Layout Shift (CLS) | ≤ 0.1 | Lighthouse CI or Web Vitals |
| API response time (p95) | ≤ 500 ms | Load test or APM trace on staging |
| API response time (p99) | ≤ 1 000 ms | Load test or APM trace on staging |
| JavaScript bundle size (gzip) | ≤ 250 KB | Build output or bundle analyzer |
| CSS bundle size (gzip) | ≤ 50 KB | Build output |
| Docker image size | ≤ 500 MB | `docker images` output in CI |

If a PR increases any metric beyond its budget, the performance-analyst agent must review and approve the justification before merge.

## Code Coverage Thresholds

| Scope | Minimum | Enforcement |
|---|---|---|
| Overall project | ≥ 80 % line coverage | CI gate — merge blocked below threshold |
| New / changed files | ≥ 90 % line coverage | CI gate — merge blocked below threshold |
| Critical paths (auth, payment, data access) | ≥ 95 % branch coverage | CI gate — merge blocked below threshold |

- Coverage is measured by the project's configured coverage tool and reported in the PR status check.
- A PR that lowers overall coverage below the threshold is blocked even if the new code itself is fully covered.
- Coverage exceptions require a code comment explaining why and a tracking issue: `// Coverage exception — see #<N>`.

## Agent Interaction and Handoff Model

Four review agents collaborate on every qualifying PR. Each agent has a distinct responsibility and a clear handoff protocol.

### code-reviewer

- **Scope:** Correctness, style, test quality, documentation, and adherence to `development.instructions.md`.
- **Runs:** On every PR.
- **Output:** Inline review comments. Approves or requests changes.
- **Handoff:** If the diff touches a security gate trigger (see above), the code-reviewer adds the `security-review` label and tags the security-analyst. If the diff includes measurable performance changes (new endpoints, bundle changes, image changes), the code-reviewer tags the performance-analyst.

### security-analyst

- **Scope:** Trust boundaries, input validation, secrets handling, dependency risk, and adherence to `security.instructions.md`.
- **Runs:** On PRs labeled `security-review` or when tagged by the code-reviewer.
- **Output:** Inline review comments with severity ratings. Approves or blocks.
- **Handoff:** After completing the security review, the security-analyst removes the `security-review` label if all findings are resolved or tracked. If infrastructure or pipeline changes are involved, the security-analyst tags the devops agent for deployment review.

### performance-analyst

- **Scope:** Performance budgets, bundle size, API latency, Core Web Vitals, and image/container size.
- **Runs:** On PRs that change frontend bundles, API routes, database queries, or container definitions.
- **Output:** Budget comparison table in a PR comment. Approves or requests optimization.
- **Handoff:** If a performance issue stems from infrastructure configuration (scaling, caching, CDN), the performance-analyst tags the devops agent. If the issue is code-level, the performance-analyst requests changes from the PR author.

### devops

- **Scope:** CI/CD pipeline correctness, deployment safety, infrastructure configuration, and environment parity.
- **Runs:** On PRs that change workflow files, Dockerfiles, infrastructure-as-code, or deployment scripts.
- **Output:** Inline review comments on pipeline and infrastructure files. Approves or requests changes.
- **Handoff:** After approving infrastructure changes, the devops agent confirms that staging deployment succeeded before the PR is eligible for production merge. If the devops agent discovers a security concern in pipeline configuration, it tags the security-analyst.

### Handoff Rules

1. **No agent merges alone.** A PR requires approval from every agent whose scope is triggered.
2. **Tagging is explicit.** Agents tag the next agent by GitHub handle in a review comment, stating the reason for the handoff.
3. **Blocking findings take priority.** If any agent has an unresolved `critical` or `high` finding, the PR cannot merge regardless of other approvals.
4. **Async by default.** Agents review in parallel when scopes do not overlap. Sequential review is required only when one agent's output is an input to another (e.g., security-analyst waits for code-reviewer to confirm the diff is functionally correct before evaluating trust implications).
5. **Escalation path.** If agents disagree, the tie-breaker is the agent closest to the risk: security-analyst for security issues, performance-analyst for performance issues, devops for deployment issues, code-reviewer for correctness issues.
