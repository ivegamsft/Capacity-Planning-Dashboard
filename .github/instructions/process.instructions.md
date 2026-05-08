---
description: "Use when planning sprints, triaging issues, managing pull requests, coordinating releases, or evaluating delivery health. Covers the end-to-end delivery lifecycle from intake through production release."
applyTo: "**/*"
---

# Delivery and Process Standards

Use this instruction for all sprint planning, issue management, pull request workflow, release coordination, and cross-team collaboration activities.

## Sprint Ceremony Cadence

Each sprint is two weeks. All ceremonies are required unless the team explicitly cancels with 24-hour notice.

| Ceremony | When | Duration | Purpose |
|---|---|---|---|
| Sprint Planning | Day 1, Monday morning | 90 min | Select and scope work from the prioritized backlog |
| Daily Standup | Every weekday | 15 min | Surface blockers, align on the day's priorities |
| Backlog Refinement | Wednesday, Week 1 | 60 min | Estimate, clarify, and split upcoming stories |
| Sprint Review | Last Friday, afternoon | 60 min | Demo completed work to stakeholders, collect feedback |
| Sprint Retrospective | Last Friday, after review | 45 min | Identify process improvements, assign action items |

- **Planning** produces a sprint goal and a committed set of issues. Every committed issue must have acceptance criteria, an estimate, and an assignee before the sprint starts.
- **Standup** follows a strict format: what I completed, what I am working on, what is blocking me. Side discussions move to a thread.
- **Retro** action items are filed as GitHub Issues labeled `process-improvement` and assigned to a specific owner with a due date.

## Issue Lifecycle

Every unit of work follows this progression:

```
Triage → Backlog → Sprint → In Progress → In Review → Done
```

### Stage Definitions

| Stage | GitHub State | Criteria to Enter | Criteria to Exit |
|---|---|---|---|
| **Triage** | Open, no project | New issue filed or reported | Labeled, estimated, and accepted or rejected |
| **Backlog** | Open, project board | Triaged and accepted | Selected for a sprint during planning |
| **Sprint** | Open, sprint milestone | Committed in planning, has assignee | Work begins — assignee moves to In Progress |
| **In Progress** | Open, `in-progress` label | Assignee actively working | PR opened and linked to the issue |
| **In Review** | Open, linked PR under review | PR passes CI, reviewer assigned | PR approved and merged |
| **Done** | Closed | PR merged, deployment verified | Issue auto-closed via PR merge |

- Issues that are blocked gain the `blocked` label and a comment explaining the dependency.
- Issues not completed by sprint end return to Backlog unless the team votes to carry them over.
- Stale issues (no activity for 14 days in Backlog) are reviewed in refinement and either re-prioritized or closed.

## Pull Request Workflow

### Branch Naming

Use the pattern from [`governance.instructions.md`](governance.instructions.md): `<type>/<issue-number>-<short-description>`

| Type | Use |
|---|---|
| `feat/` | New features, content, agents, skills |
| `fix/` | Bug fixes, correctness corrections |
| `chore/` | Tooling, config, dependency updates |
| `docs/` | Documentation-only changes |
| `refactor/` | Code restructuring with no behavior change |
| `security/` | Security-related changes |

Examples: `feat/43-user-search-api`, `fix/17-null-ref-on-login`, `chore/88-upgrade-eslint`.

### Commit Conventions

Follow Conventional Commits:

```
<type>(<scope>): <short summary>

<optional body>

<optional footer>
```

- **type**: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`.
- **scope**: the module or area affected (e.g., `auth`, `api`, `ui`, `db`).
- **summary**: imperative mood, lowercase, no period, max 72 characters.
- Breaking changes add `BREAKING CHANGE:` in the footer or `!` after the type.

### Review Requirements

- Every PR requires at least one approving review from a team member who did not author the change.
- PRs touching security-sensitive code require approval from the security-analyst agent (see `quality.instructions.md`).
- PRs touching CI/CD or infrastructure require approval from the devops agent.
- Review comments must be resolved or explicitly deferred with a tracking issue before merge.
- Self-merge is permitted only when the repo policy explicitly allows it (e.g., solo maintainer repos). Otherwise, the reviewer merges after final approval.

### Merge Strategy

- Use **squash merge** for feature and fix branches to keep the main branch history linear.
- Use **merge commit** only for long-lived integration branches that need to preserve individual commit history.
- Delete the source branch after merge.
- Every merge to `main` must pass all CI checks. No force-pushes to `main`.

## Definition of Done

A work item is Done when every box is checked:

- [ ] Code complete — all acceptance criteria met.
- [ ] Tests written — unit tests, integration tests where applicable, regression test for bug fixes.
- [ ] Tests passing — full CI suite green on the PR branch.
- [ ] Coverage thresholds met — see `quality.instructions.md` for minimums.
- [ ] Security scan clean — no new warnings from static analysis or dependency audit.
- [ ] Documentation updated — API docs, README, or configuration guides reflect the change.
- [ ] PR reviewed and approved — at least one qualifying approval, all comments resolved.
- [ ] Merged to main — squash-merged, branch deleted.
- [ ] Deployed to staging — verified in the staging environment.
- [ ] Issue closed — linked issue auto-closed or manually closed with a summary comment.

## Escalation Paths and SLA Expectations

### Response SLAs

| Severity | First Response | Resolution Target | Escalation If Missed |
|---|---|---|---|
| **Critical** — production down, data loss | 30 min | 4 hours | Notify team lead and on-call immediately |
| **High** — major feature broken, no workaround | 2 hours | 1 business day | Escalate to team lead at EOD |
| **Medium** — degraded functionality, workaround exists | 1 business day | Current sprint | Review in next standup |
| **Low** — cosmetic, minor inconvenience | 2 business days | Next sprint | Review in refinement |

### Escalation Protocol

1. **First responder** triages the issue, assigns severity, and begins investigation.
2. If the SLA is at risk, the assignee posts in the team channel with a status update and tags the team lead.
3. If the resolution target is missed, the team lead escalates to the engineering manager with a written summary: what happened, what was tried, what is needed.
4. Post-incident, a root-cause analysis is filed as a GitHub Issue labeled `incident-review` within 48 hours.

## Release Process

### Versioning

Follow Semantic Versioning (`MAJOR.MINOR.PATCH`):

- **MAJOR** — breaking changes to public APIs or data contracts.
- **MINOR** — new features, backward-compatible.
- **PATCH** — bug fixes, backward-compatible.

Pre-release versions use a hyphen suffix: `1.2.0-rc.1`.

### Release Workflow

1. **Cut a release branch** from `main`: `release/vX.Y.Z`.
2. **Update the changelog** — consolidate commit messages since the last release into categorized sections: Added, Changed, Fixed, Removed, Security.
3. **Run the full test suite** on the release branch — unit, integration, and end-to-end.
4. **Tag the release** with an annotated Git tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`.
5. **Create a GitHub Release** from the tag with the changelog as the body.
6. **Deploy to production** via the CI/CD pipeline triggered by the tag.
7. **Verify production** — smoke tests and health checks pass.
8. **Merge the release branch back to main** if any hotfixes were applied during the release.

### Hotfix Process

- Branch from the release tag: `fix/hotfix-description`.
- Apply the minimal fix, test, and open a PR against `main`.
- Cherry-pick to the release branch if a patch release is needed.
- Follow the same release workflow for the patch version.

## Cross-Team Coordination

### Shared Contracts

- API contracts (OpenAPI specs) and message schemas are the authoritative interface between teams.
- Contract changes require a PR reviewed by at least one representative from each consuming team.
- Breaking contract changes must be announced at least one sprint in advance with a migration guide.

### Dependency Management

- When your work depends on another team's deliverable, create a linked issue in their repository and reference it in your issue.
- Track cross-team dependencies on the sprint board with the `cross-team` label.
- Blocked cross-team items are raised in standup and escalated to team leads if unresolved within two business days.

### Communication Channels

- **Sprint-scoped decisions** — GitHub Issue comments and PR reviews.
- **Urgent coordination** — team channel in chat, tagging the relevant team lead.
- **Design and architecture discussions** — dedicated discussion threads or ADR (Architecture Decision Record) documents in the repository.

## Metrics and Health Indicators

Track these metrics each sprint to assess delivery health:

| Metric | Target | Signal |
|---|---|---|
| Sprint velocity (story points completed) | Stable ± 15 % from rolling average | Declining velocity signals overcommitment or blockers |
| Cycle time (issue open → merged) | ≤ 5 business days for standard items | Rising cycle time signals review bottlenecks or scope creep |
| PR review turnaround | ≤ 1 business day for first review | Slow reviews block the pipeline and increase context-switch cost |
| Escaped defects (bugs found in production) | ≤ 2 per sprint | Rising defects signal gaps in testing or review |
| Sprint goal completion rate | ≥ 80 % of committed items | Consistently missing goals signals planning issues |
| Deployment frequency | ≥ 1 per week | Lower frequency signals release process friction |
| Change failure rate | ≤ 10 % of deployments cause rollback | Higher rate signals insufficient staging validation |

- Metrics are reviewed in the Sprint Retrospective.
- Trends matter more than individual data points. A single bad sprint is a data point; three consecutive bad sprints are a pattern that requires a process change.
- Do not use velocity to compare teams. Use it only to help a single team improve its own forecasting.
