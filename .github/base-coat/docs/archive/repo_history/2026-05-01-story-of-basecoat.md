# The Story of Base Coat

**Generated:** 2026-05-01 (updated after v2.1.0 release)
**Scope:** Repository inception through v2.1.0, covering 174 closed issues, 150 PRs, and the evolution from a simple scaffold to a full-SDLC agent framework.

---

## Chapter 1: The Scaffold (v0.1.0 — March 19, 2026)

Base Coat began as a modest idea: what if teams could share GitHub Copilot
customizations the way they share linting configs or CI templates?

The initial commit created the repository scaffold with:

- Sync scripts for PowerShell and Bash consumers
- Starter instructions, prompts, skills, and agent files
- An inventory file and version metadata

At this point, Base Coat was a **template** — a starting point for teams to copy
and customize. The core insight was already present: separate *instructions*
(ambient rules) from *agents* (workflows) from *skills* (knowledge packs).

---

## Chapter 2: Building the Foundation (v0.2.0–v0.4.2 — March 19, 2026)

In rapid succession, the foundation layers were added:

**v0.2.0** — YAML frontmatter for all assets, expanded instruction sets for security,
reliability, and documentation. The refactoring skill and bugfix prompt arrived.

**v0.3.0** — Enterprise packaging took shape: sample Azure, naming, Terraform, and
Bicep instructions; authoring skills for creating new skills and instructions;
GitHub Actions workflows for validation and release packaging; example consumer
workflows and starter IaC.

**v0.4.0** — MCP standards guidance, repository template standard with lock-based
bootstrap and drift enforcement, and CI validation for template assets.

**v0.4.1–v0.4.2** — Stabilization: fixing commit-message scanner tests and the
tag-triggered packaging workflow.

By the end of this phase, Base Coat had its distribution pipeline, its validation
infrastructure, and its governance model. But it only had a handful of agents.

---

## Chapter 3: The Agent Explosion (v0.5.0–v0.7.0 — March–April 2026)

### Sprint 1: Testing Agents (v0.5.0)

Three testing agents landed together: `manual-test-strategy`, `exploratory-charter`,
and `strategy-to-automation`. Each had a clear role in a pipeline — define manual
scope, run exploratory sessions, then convert findings to automation candidates.
The `manual-test-strategy` skill provided rubric, charter, checklist, and defect
templates.

### Sprint 2: The Dev Core Four (v0.6.0)

Issues #1–#8 defined the backbone: four development agents (`backend-dev`,
`frontend-dev`, `middleware-dev`, `data-tier`) with paired skills and a shared
`development.instructions.md`. Each agent was framework-agnostic, filed tech-debt
issues automatically, and followed structured templates for API specs, service
layers, component specs, schema designs, and migration scripts.

This sprint established the pattern that every subsequent agent would follow:
**agent + paired skill + ambient instruction**.

### Sprint 3: Architecture, Quality, and Process (v0.7.0)

The next wave expanded across disciplines:

- **Architecture agents** (#9–#16): `solution-architect`, `api-designer`,
  `ux-designer` with skills for ADRs, C4 diagrams, OpenAPI specs, and
  wireframes
- **Quality agents** (#17–#23): `code-review`, `security-analyst`,
  `performance-analyst` with OWASP checklists and STRIDE templates
- **DevOps and Meta agents** (#20, #24–#30): `devops-engineer`,
  `mcp-developer`, `agent-designer`, `prompt-engineer`
- **Process agents** (#31–#37): `product-manager`, `sprint-planner`,
  `tech-writer`, `issue-triage`

Model recommendations were added to every agent with a `## Model` section.
The governance instruction gained model selection guidance and token budget
awareness rules.

Sprint management agents like `sprint-planner`, `release-manager`,
`retro-facilitator`, and `project-onboarding` (#46–#50) closed the loop:
Base Coat could now plan its own sprints, cut its own releases, and onboard
new repos using its own agents.

---

## Chapter 4: The Router and v2.0.0 (April 28, 2026)

The v2.0.0 release marked Base Coat's transition from a collection of assets
to a **framework with a single entry point**.

Key additions:

- `/basecoat` router skill with dual-mode UX (discovery + delegation)
- `basecoat-metadata.json` — machine-readable registry of all agents
  with categories, keywords, aliases, and paired skills
- `PRODUCT.md` — project identity document
- `PHILOSOPHY.md` — why three primitives, how they compose
- `basecoat-ghcp.zip` release artifact for 1-step GitHub Copilot installation

PR #103 (`feat: /basecoat router skill + metadata registry`) was the keystone.
With the router, users no longer needed to memorize 28 agent names — they just
said `/basecoat backend` or `/basecoat security` and the router figured out the rest.

---

## Chapter 5: The Big Expansion (April 30, 2026)

The day after v2.0.0, a massive expansion sprint landed 40+ PRs in a single day.
This was Base Coat's most ambitious sprint, driven by parallel agent dispatch.

### Wave 1: New Instructions and Behavioral Patterns

PRs #149–#164 added 16 new instruction files and skills:

- `verification-driven-development` — test-first workflow enforcement
- `token-economics` — cost-aware model selection
- `session-hygiene` — clean context management
- `plan-first-workflow` — think before coding
- `agent-behavior` — anti-loop detection
- `parallel-agent-execution` — fleet-mode patterns
- `structured-handoff` — agent-to-agent protocols
- `human-in-the-loop` — approval gates
- `tool-minimization` — reduce tool call overhead
- `scoped-instructions` — targeted rule application
- `SQLite-persistent-memory` — cross-session knowledge
- `local-embeddings` — semantic code search
- `prompt-registry` — versioned prompt management

### Wave 2: Advanced Agents

PRs #165–#182 introduced a new generation of specialized agents:

- **Observability:** `sre-engineer`, `incident-responder`
- **Ops:** `agentops`, `dataops`, `mlops`, `llmops`
- **Security:** `guardrail`, `policy-as-code-compliance`, `chaos-engineer`
- **Knowledge:** `memory-curator`, `prompt-coach`
- **Architecture:** `ai-architecture-patterns`

### Wave 3: Enterprise Infrastructure

PRs #184–#196 built out enterprise tooling:

- `.github/copilot-instructions.md` for repo-level Copilot configuration
- Agent testing harness documentation
- Distribution and packaging guide
- Enterprise runner availability guide
- Telemetry and adoption tracking guide
- Adoption dashboard with bootstrap setup
- Degradation detection and alert filing

### Wave 4: Azure and Migration

PRs #209–#243 expanded cloud and modernization coverage:

- `infrastructure-deploy` agent
- `containerization-planner` agent
- `legacy-modernization` agent
- `app-inventory` agent with complexity scoring
- Azure skills: Container Apps, Landing Zone (ESLZ), WAF Review,
  Networking (hub-spoke), Policy & Governance, Identity & Entra ID
- Treatment matrix for migration decisions (Retire/Rehost/Replatform/Refactor/Rebuild/Replace)

### Wave 5: Runtime and Governance

PRs #244–#246 added structural governance:

- Agent taxonomy (organized by model, task, and type)
- Role-based skill scoping
- Runtime enforcement for agent tools, skill allow-lists, and model binding

---

## Chapter 6: Hygiene Sprint (April 30, 2026)

One of the most impressive demonstrations of Base Coat's own capabilities:
a single Copilot CLI session resolved 11 issues in 90 minutes using
fleet-mode parallel agents.

**The session:**

1. Listed 4 open hygiene issues
2. Dispatched 3 parallel sub-agents (sync bug #249, README fixes #251–#252)
3. Dispatched a dependent task (sync tests #250) after the fix landed
4. Ran a proactive code quality audit — discovered 7 more issues
5. Filed issues #260–#266, dispatched 4 more parallel agents
6. Merged 6 PRs, closed 2 as duplicates (scope overlap)
7. Resolved 2 triage-bot-filed issues (#271–#272)

**Zero human intervention** after the initial "start" command.

This session proved that Base Coat could maintain itself using its own
agents and patterns — the framework eating its own dogfood.

(Full write-up: [2026-04-30-sprint-hygiene.md](2026-04-30-sprint-hygiene.md))

---

## Chapter 7: Refinement and Open Frontiers (Early May 2026)

The latest PRs before v2.1.0 focused on refinement and closing gaps:

- **Copilot usage analytics skill** (PR #312) — per-session cost breakdown
- **Runner routing guardrail** (PR #313) — self-hosted vs GitHub-hosted decisions
- **Deployment cancellation pre-flight** (PR #314) — safety checks before deploy
- **Improved copilot-instructions** (PR #315) — session learnings baked in
- **Basecoat metrics MCP server** (PR #316) — programmatic access to adoption data

---

## Chapter 8: Sprint 6 and v2.1.0 (May 1, 2026)

Sprint 6 focused on a single theme: **making Base Coat fully discoverable in VS Code
Copilot**. An audit of the VS Code customization docs revealed that 33 skills were
invisible to VS Code (not synced to `.github/skills/`), 50 agents were routed to
the wrong model (VS Code ignores `## Model` sections), and docs weren't delivered
to consumer repos.

### The Sprint

Seven issues were filed from the VS Code audit (#317–#323) and four more from an
evaluation of the [Agent Skills spec](https://agentskills.io) (#327–#330). The sprint
was scoped to 5 VS Code-priority items, with cross-client work deferred to backlog.

Five PRs landed in rapid succession:

1. **PR #332** — Doc cleanup: corrected stale asset counts across README, PRODUCT,
   PHILOSOPHY; complete rewrite of INVENTORY and CATALOG
2. **PR #333** — Sync fix: `sync.ps1`/`sync.sh` now copy `skills/` to
   `.github/skills/` for VS Code auto-discovery, plus `docs/` to staging
3. **PR #334** — Agent model frontmatter: added `model:` field to all 50 agent
   YAML blocks so VS Code routes each to the correct model
4. **PR #335** — Sprint-retrospective agent and skill: structured retrospective
   generation from GitHub API data
5. **PR #336** — CI fix: removed premature CATALOG/INVENTORY entries for
   uncommitted files

### The Release

v2.1.0 was tagged and released with the full changelog auto-extracted. The Release
workflow succeeded, though the Package workflow's validate job collided with a
simultaneous push-to-main validate (same SHA, same concurrency group). This was
diagnosed and fixed immediately via PR #339 — the Copilot coding agent's first
contribution to Base Coat, adding a `concurrency_group` input to the reusable
validate workflow.

### Post-Release

An audit of GitHub org/repo security APIs confirmed that secret scanning, code
scanning, Dependabot, rulesets, and code security configurations are all accessible
with standard token scopes. Issue #340 was filed for a `github-security-posture`
agent and skill to provide one-command security audits.

### Open Issues

Sixteen issues remain open, organized by theme:

| Theme | Issues | Summary |
|---|---|---|
| **Agent Skills spec** | #327, #328, #329, #330 | Cross-client skill interop (`.agents/skills/`, frontmatter, validator, progressive disclosure) |
| **VS Code stretch** | #319, #321, #323 | Agent handoffs, prompt frontmatter, context:fork for large skills |
| **Cross-tool compat** | #322 | AGENTS.md for Claude Code, Cursor, Windsurf |
| **Data workloads** | #275, #324, #325, #326 | Python/DS instructions, data-pipeline agent, test suite |
| **Metrics & tracking** | #282, #283 | Enterprise Copilot usage metrics, per-model billing API |
| **Security** | #340 | GitHub security posture agent (org/repo policy auditing) |
| **Sprint tracking** | #331 | Sprint 6 tracking (close pending) |

---

## By the Numbers

| Metric | Value |
|---|---|
| Total issues filed | 190+ |
| Issues closed | 174 |
| Pull requests merged | 129 |
| Agents | 50 |
| Skills | 34 |
| Instruction files | 34 |
| Prompts | 3 |
| Guardrails | 6+ |
| Releases | 4 (v0.7.0, v1.0.0, v2.0.0, v2.1.0) |
| Time from scaffold to v2.1.0 | ~6 weeks |
| Contributors | Human + AI agents (Copilot coding agent, Copilot CLI) |

---

## Themes and Patterns

### 1. Agents Build Agents

Base Coat is self-referential: `agent-designer` designs new agents,
`new-customization` creates skills and instructions, `sprint-planner` plans
the sprints that build Base Coat, and `release-manager` cuts the releases.

### 2. Parallel-First Development

The hygiene sprint proved that fleet-mode parallel agent dispatch — with
dependency-aware ordering and file-scope batching — can resolve 11 issues
in 90 minutes with zero human intervention.

### 3. Governance as Code

Instructions are the secret weapon. They are ambient (always active), composable
(layer multiple), and updatable (change one file, affect all agents). The
three-primitive architecture keeps governance separate from workflow.

### 4. Enterprise from Day One

Version pinning, SHA256 checksums, CI validation, secret scanning, Dependabot,
adoption metrics, and runner routing were not afterthoughts — they were built
into the distribution pipeline from v0.3.0 onward.

### 5. Azure-Native Cloud Patterns

A significant portion of the skill library targets Azure: Container Apps,
Landing Zones, WAF Review, Networking, Policy, Identity, and Bicep/Terraform
IaC patterns. This reflects the target audience (Microsoft enterprise teams)
while keeping the core framework cloud-agnostic.

---

## What's Next

Based on open issues and trajectory:

- **Cross-client skill interop** — `.agents/skills/` path for Claude Code, Cursor, Windsurf (#329)
- **Agent Skills spec compliance** — optional frontmatter fields, validator in CI, progressive disclosure (#327, #328, #330)
- **Python and Data Science coverage** — closing the gap for ML/notebook workflows (#275, #324–#326)
- **GitHub security posture** — org/repo policy auditing via native APIs (#340)
- **VS Code advanced features** — agent handoffs, prompt frontmatter, context:fork (#319, #321, #323)
- **AGENTS.md cross-tool compatibility** — single discovery file for all AI tools (#322)
- **Copilot metrics integration** — once enterprise policy and per-model billing API are available (#282, #283)
