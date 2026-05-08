# Changelog

All notable changes to this repository should be recorded in this file.

## Unreleased

## 3.11.0 - 2026-05-09

### Docs Reorganization, Memory Design Docs, Architecture Diagrams

#### Docs Reorganization (`docs/`)

Complete restructuring of 155+ files into an 8-section taxonomy for navigability:

- **`docs/architecture/`** — execution hierarchy, multi-agent orchestration, AI patterns
- **`docs/guides/`** — enterprise setup, rollout, governance, hooks, rate-limit
- **`docs/reference/`** — CLI, label taxonomy, asset registry, INVENTORY, prompt registry
- **`docs/agents/`** — agent testing, skill map, telemetry, handoffs, runtime enforcement
- **`docs/memory/`** — SQLite memory, shared memory, token optimization, local models
- **`docs/operations/`** — release process, runbooks, cost optimization, DR, blocked issues
- **`docs/integrations/`** — MCP, RAG, pydantic, Azure-specific, portal, app inventory
- **`docs/archive/`** — wave summaries, staging reports, sprint deliverables
- Updated `docs/INDEX.md` with full 8-section taxonomy and diagram links
- Updated `README.md` all broken doc links to new paths
- Updated `sync.ps1` to find `INVENTORY.md` at new `docs/reference/` location

#### Memory Design Documentation (`docs/memory/`)

Three new authoritative docs for the BaseCoat memory model:

- **`MEMORY_DESIGN.md`** — full L0–L4 hierarchy, retrieval cost, promotion ladder, turn budget, failure protocols, SQLite schema, fork guidance
- **`LEARNING_MODEL.md`** — Routine/Familiar/Novel knowledge taxonomy, TRM/HRM research context, adopter warm-up path, pattern bundle lifecycle, anti-patterns
- **`SHARED_MEMORY_GUIDE.md`** — full setup walkthrough, writing good entries, contribution flow, sync script usage, maintenance cadence

#### Architecture Diagrams (`docs/diagrams/`)

10 new Excalidraw diagrams providing visual reference for architecture and process flows:

**Architecture (5):**
- `execution-hierarchy.excalidraw` — 5-layer execution stack from user intent to output
- `multi-agent-orchestration.excalidraw` — LangGraph StateGraph fan-out/fan-in pattern
- `asset-taxonomy.excalidraw` — four primitive asset types and their relationships
- `memory-lookup-hierarchy.excalidraw` — L0–L4 memory layer lookup and retrieval cost
- `two-tier-memory-model.excalidraw` — personal vs shared memory tiers

**Process (5):**
- `intent-routing.excalidraw` — fast-path vs deep-reasoning routing decision
- `turn-budget-protocol.excalidraw` — token budget enforcement and graceful degradation
- `memory-promotion-flow.excalidraw` — pattern promotion and demotion ladder
- `agentic-workflow-lifecycle.excalidraw` — PR trigger → filter → agent → safe output
- `bootstrap-flow.excalidraw` — 4-phase bootstrap script flow

All diagrams indexed at `docs/diagrams/README.md`.

## 3.10.0 - 2026-05-08

### Bootstrap, Agentic Workflows Tier 1-2, Azure Instructions, Shared Org Memory

#### Bootstrap (`scripts/bootstrap.ps1`)

New idempotent 4-phase setup script for new BaseCoat adopters:

- **Phase 1 — Repo setup**: fork/clone detection, `gh` CLI check, `gh aw` extension install prompt, GitHub Actions status verification
- **Phase 2 — Memory layer**: `.gitignore` guard for SQLite/session-state files, `.memory/` directory init, optional shared org memory sync
- **Phase 3 — Secrets checklist**: `COPILOT_GITHUB_TOKEN` presence check, `BASECOAT_SHARED_MEMORY_REPO` config, `version.json` readability
- **Phase 4 — Validation**: runs `validate-basecoat.ps1` + `tests/run-tests.ps1`; actionable error list on failure
- Flags: `-Silent` (CI use), `-SkipTests`, `-SharedMemoryRepo`

#### Agentic Workflows — Tier 2 (`.github/workflows/`)

New `security-analyst.md` + compiled `security-analyst.lock.yml`:

- Triggers on `pull_request: [opened, synchronize]`
- Performs OWASP Top 10 spot check scoped to PR diff, secret scan, dependency risk assessment
- Posts a severity-ranked findings table only when issues are found — no noise on clean PRs
- Completes the Tier 1+2 agentic workflow set: `issue-triage`, `retro-facilitator`, `self-healing-ci`, `code-review-agent`, `release-impact-advisor`, `security-analyst`

#### Azure Instructions

- **`instructions/azure-service-connector.instructions.md`**: managed identity authentication (system/user-assigned), Key Vault references for secrets, Bicep `Microsoft.ServiceLinker/linkers` patterns, standard environment variable names, connection validation
- **`instructions/azure-app-configuration.instructions.md`**: key naming hierarchy (`{service}/{component}/{key}` + labels), feature flags with safe defaults, dynamic refresh with sentinel key, `disableLocalAuth`, purge protection, private endpoints, SDK usage pattern (.NET example)

#### Shared Org Memory Repo

- Created `IBuySpy-Shared/basecoat-memory` private repo — the shared L2s/L3s memory tier for the org
- Seeded from `docs/templates/basecoat-memory/`: README, CONTRIBUTING, hot-index, validate-memory CI workflow
- Sync via `scripts/sync-shared-memory.ps1 -SharedMemoryRepo IBuySpy-Shared/basecoat-memory`

## 3.9.0 - 2026-05-07

### Adaptive Execution Hierarchy + Memory Fast-Path Routing

#### Execution Hierarchy (`docs/execution-hierarchy.md`)

New reference document defining the 5-layer execution stack for all BaseCoat agents:

- **Layer 0** — System instructions (host/provider, immutable)
- **Layer 1** — BaseCoat guardrails as structural circuit breakers (governance, security, agent-behavior); fire at fixed checkpoints regardless of fast/full path — cannot be routed around
- **Layer 2** — Intent classification using L2 memory index (zero extra context cost); routes to fast path or full path based on confidence score
- **Layer 3a Fast Path** — Pattern bundle loaded for known intents (confidence ≥ 0.80); pre-scoped context + pre-validated turn budget
- **Layer 3b Full Path** — Layered context load for novel/low-confidence tasks; L2 → L3 episodic → L4 semantic
- **Layer 5** — Post-execution learning: reinforce successful novel patterns to memory; log failure patterns on stuck tasks

Pattern bundle catalog: 9 known BaseCoat patterns with turn budgets and confidence lifecycle (degrades on overruns, retires below 0.50).

#### Memory Lookup Hierarchy (`instructions/memory-index.instructions.md`)

New L2 hot-cache instruction file — loads at session start to prime fast recall:

- L0–L4 tier map with retrieval cost per tier
- Promotion ladder: `store_memory` accessed 3× → L2 index; 5 sessions → L1 instruction rule; >50% sessions → L0 frontmatter
- Pinned patterns exempt from decay (security, governance)
- Trigger map organized by domain (CI, testing, portal, git, assets, turn budget)
- Episodic retrieval SQL shortcuts for L3 queries

#### Turn Budget and Learning Cost (`instructions/token-economics.instructions.md`)

- Classify tasks as **Routine** (≤3 turns), **Familiar** (≤5 turns), or **Novel** (estimate N) before starting
- **Failure protocol**: after 5 turns with no measurable forward progress → `store_memory` failure pattern, change approach before escalating model tier
- **Success protocol**: novel solution + tests pass → `store_memory`; skip for boilerplate
- **80/50 early-warning rule**: at 80% turn budget with <50% progress → pause and reassess
- Intent-first context loading replaces static layered order

#### Memory Schema Extensions (`docs/SQLITE_MEMORY.md`)

- Added columns: `tier` (l0–l4), `heat` (cold/warm/hot), `pinned`, `promotion_count`, `last_promoted_at`
- Heat thresholds: cold (0–2 accesses), warm (3–9), hot (10+)
- Pinned flag exempts memories from decay and demotion

#### Memory Curator Agent (`agents/memory-curator.agent.md`)

- L0–L4 lookup hierarchy with retrieval cost per tier
- Promotion protocol (myelination): access frequency drives tier promotion
- Heat-based proactive injection: hot memories injected at session start when domain matches
- Resolution order for SessionStart and PostToolUse failure paths

#### Plan-First Workflow (`instructions/plan-first.instructions.md`)

- Phase 0 (Intent Classification) added before Explore phase
- Fast-path tasks skip directly to Plan using bundle context
- Guardrails still fire at structural checkpoints on all paths

## 3.8.0 - 2026-05-07

### Sprint 11 — GitHub Agentic Workflows + Portal Scan Trigger

#### Agentic Workflows (`gh aw`)

Five BaseCoat agents converted to GitHub Agentic Workflows that run automatically
inside GitHub Actions. Each workflow is a `.md` source file compiled to a
`.lock.yml` with the `gh aw` framework's defense-in-depth security model
(read-only agent job → threat detection → safe-output execution).

- **`issue-triage`** — fires on `issues: opened`; classifies issue type, applies
  priority labels (`P0`–`P3`), and posts a triage summary comment (#562)
- **`retro-facilitator`** — `schedule: weekly`; analyzes closed issues and merged
  PRs for the past 7 days and creates a structured Went Well / Improve / Action
  Items retrospective issue (#563)
- **`self-healing-ci`** — fires on `workflow_run: failed`; fetches failed job logs
  and posts a root-cause diagnosis with remediation steps (#564)
- **`release-impact-advisor`** — fires on `pull_request: opened`; assesses blast
  radius, rollback complexity, and risks for the PR diff (#566)
- **`code-review-agent`** — fires on `pull_request: [opened, synchronize]`; reviews
  the diff for bugs, security vulnerabilities, and logic errors with
  high signal-to-noise ratio (#567)

#### Portal — Scan Trigger

- **Trigger Scan button** in `RepositoryDetail` — POST `/api/v1/repositories/:id/scans`,
  disabled while running, error banner on failure (#565)
- **`useScanPoller` hook** — polls `GET /api/v1/scans/:id` every 3s until
  `completed` or `failed`; auto-refreshes scan history table (#565)
- **Scan running badge** — visual indicator while polling is active (#565)
- **Backend stub runner** — scan transitions `running → completed` via 5s timeout,
  enabling end-to-end demo without a live scanner (#565)
- **20 tests** — 6 `useScanPoller` unit tests + 14 `RepositoryDetail` tests (#565)

#### Documentation

- **`docs/agentic-workflows.md`** — `COPILOT_GITHUB_TOKEN` PAT setup guide,
  workflow authoring instructions, security model overview, allowed-expressions
  reference

#### Security

- Bump `path-to-regexp` 8.3.0 → 8.4.2 in `/mcp` (#559)

## 3.7.0 - 2026-05-07

### Sprint 10 — Portal UX, Docker Deployment, and Plugin Docs

#### Portal Frontend

- **Dashboard charts** — recharts `ScanBarChart` (scans per repo) and `ScanStatusPie` (pass/fail distribution) with summary cards for total repos, total scans, pass rate (#548)
- **Repository detail page** — `RepositoryDetail.tsx` with scan history table, status badges, and back navigation; 7 unit tests (#549)
- **Repositories list** — `Repositories.tsx` list page with repo name, scan count, and last-scan status (#549)

#### Docker Deployment

- **Multi-stage Dockerfiles** — `portal/backend/Dockerfile` (node:20-alpine, `USER node`) and `portal/frontend/Dockerfile` (Vite build + nginx:alpine runtime) (#550)
- **docker-compose.yml** — Full stack: `postgres:16` + `backend:3000` + `frontend:8080` with health checks and env-var injection (#550)
- **nginx SPA routing** — `portal/frontend/nginx.conf` with `/api` proxy pass and `try_files` fallback for React Router (#550)
- **`.env.example`** — Documented all required environment variables (#550)
- **Portal quickstart** — `portal/README.md` with Docker Compose and manual dev-server setup instructions (#550)

#### CLI Plugin Docs

- **Plugin README** — End-user documentation for `@basecoat/copilot-cli-plugin`: install, config, API, and troubleshooting (#551)
- **npm publish config** — Added `files`, `publishConfig`, `keywords`, `repository`, and `engines` to `plugins/copilot-cli-plugin/package.json` (#551)
- **`.npmignore`** — Excludes test files, source maps, and dev configs from published package (#551)

#### CI / Agent Quality

- **Sync test robustness** — `Invoke-SyncToConsumer` now creates a temp named branch for `git clone` instead of using detached-HEAD ref; works in all CI states (PR merge commits, tag checkouts, shallow clones)
- **Agent output sections** — Fixed `## Key Outputs` → `## Output` in `api-security`, `database-migration`, `e2e-test-strategy`, and `gitops-engineer` agents to satisfy word-boundary CI validation
- **CRLF fix** — `skills/azure-container-apps/SKILL.md` converted to LF

#### Security Updates (Dependabot)

- Bump `vite` 5.4.21 → 8.0.11 in `/portal/frontend` (#532)
- Bump `tar` and `sqlite3` in `/portal/backend` (#528)
- Bump `@tootallnate/once` and `sqlite3` in `/portal/backend` (#527)
- Bump `hono` 4.12.8 → 4.12.18 in `/mcp` (#518)
- Bump `@hono/node-server` 1.19.11 → 1.19.14 in `/mcp` (#517)
- Bump `ip-address` and `express-rate-limit` in `/mcp` (#516)
- Bump `minimatch`, `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser` in `/portal-ui` (#514)



## 3.6.0 - 2026-05-07

### Sprint 9 — Plugin Wiring, Portal API, Auth, and Frontend Data

#### Copilot CLI Plugin

- **invoke() wired end-to-end** — `parseCommand → buildContext → findAgent → delegate`, never throws, returns structured `DelegationResult` (#533)
- **CLI binary** — `src/cli.ts` + `bin/basecoat` npm binary with `--help`, `--version`, exit codes (#536)
- **Integration tests** — 7 plugin e2e tests covering success, agent-not-found, parse errors, streaming, config override (#538)

#### Portal Backend

- **REST API** — 6 endpoints: `GET/POST /api/v1/repositories`, `GET /api/v1/repositories/:id`, `POST/GET /api/v1/repositories/:id/scans`, `GET /api/v1/scans/:id` with `{ data }` envelope (#534)
- **GitHub OAuth + JWT** — passport-github2 strategy, `requireAuth` middleware, `/auth/github`, `/auth/github/callback`, `/auth/logout`, `GET /api/v1/me` (#535)
- **Auth on API routes** — repositories and scans routes now require valid JWT (#538)
- **Integration tests** — 12 portal API tests covering auth middleware and full CRUD flow (#538)

#### Portal Frontend

- **GitHub OAuth flow** — Login page, AuthCallback (`?token=` param), JWT in localStorage (#537)
- **Protected routes** — `ProtectedRoute` wraps all authenticated pages, redirects to `/login` (#537)
- **Live data** — Dashboard fetches real `/api/v1/repositories` with loading spinner and error banner (#537)
- **Axios interceptor** — Bearer token on all requests, auto-logout on 401 (#537)
- **Logout** — Sidebar logout clears JWT and redirects to `/login`; Header shows real username (#537)

## 3.5.0 - 2026-05-09

### Sprint 8 — Copilot CLI Plugin and Portal Scaffold

#### Copilot CLI Plugin (`plugins/copilot-cli-plugin/`)

- **Agent registry design** — JSON Schema Draft 7, 73-agent registry, TTL-cached loader, fuzzy search (#478, #482)
- **Plugin scaffold** — `BasecoatPlugin` class, TypeScript interfaces, ESLint/Prettier/Jest setup (#477)
- **Command parser** — `/basecoat <agent-id> <task> [--flags]` with validation, quoted strings, 40 tests (#479)
- **Context builder** — OS/shell detection, ISO 8601 timestamp, `InvocationContext` assembly, 17 tests (#481)
- **Delegation engine** — `Promise.race` timeout, exponential backoff retry, streaming chunks, 83 total tests (#483)

#### Portal Backend (`portal/backend/`)

- **Express scaffold** — TypeScript, Sequelize, Winston logger, request logger, error handler, `GET /health` (#485)
- **Data models** — User, Repository, Scan, ScanResult, AuditLog with associations and 5 Sequelize migrations (#486)

#### Portal Frontend (`portal/frontend/`)

- **React scaffold** — React 18 + Vite 5 + TypeScript + Tailwind CSS + Zustand + React Router v6 (#487)
- Dashboard with stat cards, searchable Agents page, sidebar navigation, Axios API client

## 3.4.0 - 2026-05-08

### Repository Structure Cleanup

- **`docs/portal/`** — 21 portal/IAM/accessibility/security docs moved out of repo root and `docs/` (#501)
- **`docs/wireframes/`** — 6 Excalidraw wireframe files relocated from repo root (#501)
- **`portal/prompts/`** — 5 portal-specific prompts moved out of `prompts/` sync path (#503)
- **`docs/INDEX.md`** — New repo-wide documentation map covering all 60+ docs by topic (#502)
- **`docs/PORTAL_INDEX.md`** — Former `docs/INDEX.md` (portal infrastructure index) preserved (#502)
- **`scripts/generate-inventory.ps1`** — New script to validate asset counts against INVENTORY.md and README.md (#505)

### INVENTORY.md Completion

- Added 21 missing agent entries (73 total, up from 52)
- Added 22 missing skill entries (55 total, up from 33)
- All counts verified: 73 agents · 55 skills · 56 instructions · 8 prompts

## 3.3.0 - 2026-05-08

### Deployable MCP Server

- **`mcp/` server** — standalone Node.js MCP server exposing Base Coat assets as tools
- **Docker + Azure Container Apps** deployment support with `Dockerfile` and deployment guide
- **`docs/mcp-deployment.md`** — step-by-step deployment guide for Docker and ACA
- **`examples/mcp/basecoat.mcp.json`** — reference MCP client configuration

### Squad Workflow Automation

- **`.github/agents/squad.agent.md`** — squad coordination agent for GitHub issue management
- **4 GitHub Actions workflows**: `squad-heartbeat`, `squad-issue-assign`, `squad-triage`, `sync-squad-labels`
- **`.copilot/mcp-config.json`** — MCP configuration for squad integration

### Consumer Smoke Tests

- **`tests/run-consumer-smoke.ps1`** — Windows smoke test script for release artifact validation
- **`tests/run-consumer-smoke.sh`** — Unix smoke test script for CI/CD pipeline use

### CI Hardening

- **16 agent files** fixed with missing required `## Inputs`, `## Workflow`, `## Output` sections
- **`actions/upload-artifact`** upgraded from deprecated v3 → v4 in performance baseline check
- **`.markdownlintignore`** — excludes third-party agent files from markdown lint CI
- **`version-consistency`** now reliably enforced across all PR branches

## 3.2.0 - 2026-05-07

### Wave 3 Portal Design Acceleration — Design Validation & Implementation Readiness

This release delivers the complete Wave 3 Days 2-3 outputs: formal validation sign-offs,
implementation scaffolding, and Go/No-Go approval for Sprint 7 (May 11 kickoff).

#### Architecture & API Sign-Offs
- **Architecture Review** — Formal APPROVED status with 11 documented risks and mitigations
- **API Contract Sign-Off** — Binding contracts for 28+ endpoints (OAuth 2.0, RBAC matrix, rate limiting, multi-tenancy audit trail)

#### Security
- **Security Risk Mitigation Roadmap** — OWASP Top 10, STRIDE (20 threats), SOC 2, GDPR mapped to 4-week sprint delivery plan

#### Implementation Scaffolding
- **@basecoat/portal-ui v0.1.0** — React component library (5 production components, 96.99% test coverage, WCAG 2.1 AA)
- **Performance Testing Framework** — 5 k6 load test scripts + Prometheus/Grafana monitoring + GitHub Actions CI/CD integration; baselines: <500ms p95 at 100 users
- **Pydantic v2 Schemas** — Complete artifact schema definitions (Agent, Skill, Instruction, Prompt, CustomInstruction + CompatibilityEnum/MaturityEnum)

#### Documentation
- Wave 3 deliverables manifest and staging infrastructure deployment documentation
- Staging cost estimate: $250-315/month (AWS multi-AZ)
- Final deployment readiness report — **✅ GO for Sprint 7 May 11 kickoff**

## 3.1.0 - 2026-05-07

### Monolith AI Guidance & Production Sync

- Instruction sets for monolith decomposition, C++, runtime debugging, and AI verification
- Automated production sync workflow (publish-to-production CI/CD)

## 3.0.0 - 2026-05-04

### Major Release: Enterprise-Scale Ecosystem Complete

This major release represents the completion of the full enterprise customization framework for GitHub Copilot. 

#### Highlights
- **73 Production Agents** — End-to-end coverage for DevOps, security, architecture, data, and development workflows
- **55 Reusable Skills** — Modular, composable patterns for integration, infrastructure, and service patterns
- **52 Instruction Sets** — Language-specific, framework-specific, and discipline-specific guidance
- **3 Prompt Templates** — VS Code routing, model selection, and multi-turn conversation patterns
- **53 Enterprise Documentation** — Architecture guidance, migration playbooks, governance frameworks
- **100% Validation Coverage** — All assets validated, indexed, and cross-referenced
- **Rate-Limit Protected** — Exponential backoff strategy for GitHub API and LLM inference
- **Zero Regression Testing** — Complete sprint delivery with maintained code quality

#### New Assets (Post-v2.9.0)
- `agents/cloud-agent-auto-approval.agent.md` — GitHub Actions workflow automation for Copilot cloud agent (#383)
- Comprehensive rate-limit guidance and exponential backoff utilities (#446)
- Multi-agent orchestration patterns research and implementation (#450)
- Untools integration framework evaluation (#444)
- Pydantic schema validation investigation (#448)
- 4-agent concurrency wave batching (#451)
- Test failure propagation hardening (#403)
- Agent Skills spec validation warnings reduced 127 → 0 (#402)

#### Documentation Updates
- `CONTRIBUTING.md` — Updated with rate-limit discipline, GitHub Actions auto-approval, issue labeling standards
- `docs/LABEL_TAXONOMY.md` — Formalized taxonomy (7 categories, 11.4 KB)
- `scripts/validate-basecoat.ps1` — Enhanced validation with optional frontmatter recognition
- `tests/run-tests.ps1` — Improved error propagation and coverage tracking
- `docs/ENTERPRISE_*.md` — 10 comprehensive enterprise guides (networking, database, DNS, observability, DR, SLA/SLO, .NET, identity, security, Kubernetes)

#### Infrastructure & Automation
- `.github/workflows/issue-approve.yml` — Concurrency group for max 4 concurrent cloud agents
- `.github/workflows/auto-approve-cloud-agent-workflows.yml` — Auto-approval workflow for cloud agent PRs
- `scripts/bootstrap-fabric-workspace.ps1 & .sh` — Cross-platform Fabric automation (21 KB combined)
- Fabric notebooks deployment patterns with medallion architecture
- Service principal bootstrap with OIDC federation

#### Quality Metrics (Post-Sprint Delivery)
- **Test Coverage**: 100% maintained throughout all 3 sprints
- **Regressions**: 0 introduced
- **Rate-Limit Errors**: 0 (exponential backoff strategy successful)
- **Validation Warnings**: 127 → 0 (Sprint 5)
- **Open Issues**: 0 (all 31 sprint issues closed)
- **Open PRs**: 0 (all feature work merged)

### Statistics
- **Lines Added**: ~12,000+ across all sprints
- **Issues Closed**: 31 (Sprints 5-7 complete)
- **Commits**: 40+ conventional-format commits
- **Releases**: 3 published (v2.1.0, v2.2.0, v2.3.0) during sprint execution
- **Assets**: 73 agents + 55 skills + 52 instructions + 3 prompts + 53 docs

### Breaking Changes
None — v3.0.0 maintains backward compatibility with v2.x patterns.

## 2.7.0 - 2026-05-02

### Added
- `docs/BLOCKED_ISSUES.md` — Known limitations, prerequisites, and workarounds for API constraints (#283, #282)
- `docs/AGENT_SKILL_MAP.md` — Complete index of agents and skills by discipline, with quick-reference guide
- Complete Tier 2B ecosystem work: Supply chain security agents, OpenTelemetry instrumentation guidance
- Skill refactoring guidance for modular `references/` subdirectory pattern (Phase 2 #330)
- All 59 agents now fully documented with cross-references and adoption guidance

### Fixed
- Documented GitHub API limitations blocking per-model billing data collection (#283)
- Documented enterprise prerequisite for Copilot usage metrics (#282)



### Added
- `skills/electron-apps/SKILL.md` — Electron app development patterns: IPC, CSP, state management, testing, packaging, auto-updates (#346)
- `instructions/fabric-notebooks.instructions.md` — Medallion architecture for Fabric notebooks, lakehouse integration, CI/CD automation, governance (#377)
- `agents/security-operations.agent.md` — SOC playbook, threat detection, incident response, secrets rotation, audit logging (#360)
- `agents/penetration-test.agent.md` — Penetration testing workflows, OWASP Testing Guide alignment, finding templates (#364)
- `agents/production-readiness.agent.md` — PRR gates, business continuity planning, disaster recovery, FMEA analysis (#363)
- `agents/ha-architect.agent.md` — High availability patterns, resilience review, SRE/chaos engineering (#362)
- `agents/contract-testing.agent.md` — Consumer-driven contracts, Pact, mutation testing, integration test orchestration (#361)
- `agents/data-architect.agent.md` — Medallion architecture, data governance, ETL/ELT patterns, performance optimization (#365)
- `agents/database-migration.agent.md` — Zero-downtime migrations, schema evolution, dual-write strategies (#365)
- `agents/gitops-engineer.agent.md` — Argo CD, Flux v2, drift detection, disaster recovery patterns (#365)
- All supporting skills for Tier 1B security, operations, and data agents
- Agent Skills spec validator integration (Phase 2 #327)
- Cross-client interop sync paths for `.agents/skills/` (Phase 2 #329)

### Fixed
- Agent Skills spec frontmatter adoption for all 59 agents (100% coverage)



### Added
- `agents/data-pipeline.agent.md` — orchestrates data ingestion, transformation, quality validation workflows (#379)
- `agents/github-security-posture.agent.md` — analyzes org/repo security settings, permissions, branch protections, secret scanning (#381)
- `agents/vs-code-handoff.agent.md` — seamless skill/agent handoff workflows between VS Code Copilot and other tools (#382)
- Cloud agent coordination workflows with auto-approval and self-merge for continuous delivery (#379-382)

## 2.4.0 - 2026-05-01

### Added
- `model` and `tools` frontmatter fields to all 3 prompt files for VS Code routing (#321)
- Browser storage threat model section in `security.instructions.md` (#344)
- Security headers section in `nextjs-react19.instructions.md` with CSP baseline (#344)
- `instructions/rest-client-resilience.instructions.md` — timeouts, retries, 429 handling, semaphores, structured failure logging (#347)
- `skills/azure-devops-rest/SKILL.md` — auth, PAT scopes, pagination, throttling, endpoint taxonomy (#345)

## 2.3.0 - 2026-05-01

### Added
- `instructions/terraform-init.instructions.md` — always use `-reconfigure` in bootstrap and CI/CD (#353)
- `instructions/bootstrap-autodetect.instructions.md` — auto-detect values via param → env → CLI cascade, no prompts (#348)
- `instructions/bootstrap-github-secrets.instructions.md` — auto-push secrets/variables via `gh` CLI (#350)
- `instructions/ci-firewall.instructions.md` — single-job runner IP firewall pattern with guaranteed cleanup (#351)
- `instructions/bootstrap-structure.instructions.md` — decomposed, idempotent, documented bootstrap scripts (#349)
- `instructions/rbac-authentication.instructions.md` — RBAC-only Azure auth, disable shared keys/SAS/access policies (#352)

## 2.2.0 - 2026-05-01

### Fixed
- **CRITICAL**: Skill invocation self-contradiction in `agents.instructions.md` — clarified that omitting `allowed_skills` inherits all skills, and the `## Allowed Skills` section filters when present
- Branch naming conflict between governance and process instructions — `process.instructions.md` now defers to governance (`feat/<issue>-desc` pattern)
- Model routing table in `agents.instructions.md` aligned with `model-routing.instructions.md` (claude-sonnet-4.6 for standard tier)
- `azure/login@v1` → `@v2` in environment-bootstrap skill
- BinaryFormatter (RCE vector) replaced with System.Text.Json in service-bus-migration skill
- ClientSecret patterns in identity-migration skill now include security warnings and use env vars
- ADR path standardized to `docs/adr/` in architecture.instructions.md
- Self-merge policy clarified — permitted when repo policy allows
- 4 agent name mismatches fixed (Title Case → kebab-case): app-inventory, containerization-planner, infrastructure-deploy, legacy-modernization
- 3 agents with fictional tools replaced with real platform tools: legacy-modernization, infrastructure-deploy, release-impact-advisor

### Added
- `AGENTS.md` — root-level file listing all 50 agents for cross-tool AI agent discovery
- `context: fork` frontmatter added to 6 large skills (>5KB) for efficient VS Code context management
- Domain-specific sections added to 3 stub agents: code-review (review checklist), new-customization (decision tree), rollout-basecoat (distribution channels)

## 2.1.1 - 2026-05-01

### Fixed
- Sync scripts no longer copy agent taxonomy subdirs (`models/`, `orchestrator/`, `tasks/`, `types/`) to consumer repos — these contained only index READMEs with broken relative links
- `.github/agents/` Copilot discovery path now receives only flat `*.agent.md` files (no subdirs)
- Package Base Coat workflow no longer skips jobs on tag push — `validate-basecoat.yml` now accepts a `concurrency_group` input to prevent collisions with simultaneous push-to-main validate runs

### Changed
- `docs/GOALS.md` — updated for v2.1.0 (agent counts, model frontmatter, process discipline)
- `docs/repo_history/2026-05-01-story-of-basecoat.md` — added Chapter 8 (Sprint 6, v2.1.0, post-release fixes)

## 2.1.0 - 2026-05-01

### Added
- `agents/sprint-retrospective.agent.md` — new agent for generating structured sprint retrospectives with metrics, timelines, and actionable tips
- `skills/sprint-retrospective/SKILL.md` — companion skill with document templates, metrics formulas, and tips taxonomy
- `docs/GOALS.md` — 8 primary project goals, non-goals, and success criteria
- `docs/repo_history/2026-05-01-story-of-basecoat.md` — 7-chapter narrative of repo evolution
- `model` field added to all 50 agent YAML frontmatter blocks for VS Code model routing (27 claude-sonnet-4.6, 16 gpt-5.3-codex, 3 claude-haiku-4.5, 2 claude-sonnet-4-5, 1 claude-sonnet-4, 1 default)

### Fixed
- `sync.ps1` / `sync.sh` now copy `skills/` to `.github/skills/` for VS Code auto-discovery (was missing — 33 skills were invisible to VS Code)
- `sync.ps1` / `sync.sh` now sync `docs/` to consumer repos (fixes broken guardrail doc references)
- Removed premature CATALOG/INVENTORY entries referencing uncommitted files

### Changed
- `CATALOG.md` — added 15 agents, 7 skills, 15 instructions
- `INVENTORY.md` — complete rewrite with all 51 agents, 34 skills, 34 instructions
- `README.md` — updated asset counts (50→51 agents, 33→34 skills, 32→34 instructions)
- `PRODUCT.md` — updated 6 stale count references
- `PHILOSOPHY.md` — updated agent count

## 2.0.0 - 2026-04-28

### Added
- `/basecoat` router skill (`skills/basecoat/SKILL.md`) — single entry point with dual-mode UX: discovery (`/basecoat`) and delegation (`/basecoat [discipline] [prompt]`)
- `basecoat-metadata.json` — machine-readable registry of all 28 agents with categories, keywords, aliases, argument hints, and paired skills
- `PRODUCT.md` — project identity document defining audience, principles, and architecture
- `PHILOSOPHY.md` — explains the agents + skills + instructions design and how they compose
- Categorized agent table in `CATALOG.md` with emoji groupings (🔨🏗️🔍🚀📋🧰)
- `argumentHint` field for all 28 agents in metadata registry
- `basecoat-ghcp.zip` release artifact for 1-step GitHub Copilot installation
- Quick Start section in README with manual copy and sync script install methods

### Changed
- `sync.ps1` and `sync.sh` now distribute `basecoat-metadata.json` to consuming repos
- `package-basecoat.yml` workflow produces GHCP ZIP alongside existing artifacts

## 1.0.0 - 2026-04-28

### Added
- 28 agents covering full SDLC: development, architecture, quality, DevOps, process, meta
- 19 skills with templates and knowledge packs
- 19 instruction files for ambient governance
- 3 reusable prompts and 6 guardrails
- CI workflow with frontmatter validation and CATALOG sync checks
- Post-deploy smoke tests
- Enterprise setup guide and token optimization docs
- `CATALOG.md` machine-readable asset registry

### Fixed
- CI `grep` treating `---` as option flag (#94)
- Package workflow uploading directories (#95)
- PRD gate too aggressive for framework repos (#96)
- merge-coordinator.agent.md missing newline after frontmatter (#98)

## 0.7.0 - 2026-04-26

- Added `agents/sprint-planner.agent.md`: goal-to-issues decomposition with wave dependency mapping, agent assignment recommendations, acceptance criteria generation, and sprint board output
- Added `agents/project-onboarding.agent.md`: single-invocation new repo setup — creates repo, syncs Basecoat at pinned version, places sync scripts, configures .gitignore and issue templates, logs Sprint 1 issue, and scaffolds README
- Added `agents/release-manager.agent.md`: automated versioned release workflow — reads merged PRs, bumps version.json (semver), writes CHANGELOG entry, creates git tag, and publishes GitHub release; supports dry-run and PR-or-direct mode
- Added `agents/retro-facilitator.agent.md`: end-of-sprint retrospective — collects sprint artifacts, computes metrics, identifies patterns (Went Well / Improve / Action Items), files generic Basecoat improvement issues, and persists retro doc via PR
- Added `docs/MODEL_OPTIMIZATION.md`: model-per-role recommendations with tier matrix (Premium / Reasoning / Code / Fast), when-to-override guidance, cost considerations, and consumer configuration patterns
- Added `docs/RELEASE_PROCESS.md`: step-by-step release guide covering version artifact sync, semver rules, manual and agent-driven release processes, tag immutability policy, rollback procedure, and CI integration table
- Updated all 15 `agents/*.agent.md` files: added `## Model` section to every agent with recommended model, rationale, and minimum viable model
- Updated `instructions/governance.instructions.md`: Section 10 implemented — model selection guidance, token budget awareness rules, and cost attribution pattern (replaces stub)
- Fixed `README.md`: sync consumption pattern moved to top with Quick Start section, anti-pattern callout, and environment variables table

## 0.6.0 - 2026-03-19

- Added `agents/backend-dev.agent.md`: designs and implements REST/GraphQL APIs, service layers, and data access patterns; files GitHub Issues with `tech-debt,backend` labels for N+1 risk, missing validation, unhandled error paths, hardcoded values, and missing auth
- Added `agents/frontend-dev.agent.md`: builds component-driven UIs with WCAG 2.1 AA accessibility, responsive layouts, and Core Web Vitals targets; files GitHub Issues with `tech-debt,frontend,accessibility` labels for missing ARIA, hardcoded colors, non-semantic markup, missing loading states, and inline styles
- Added `agents/middleware-dev.agent.md`: designs integration layers, message contracts, API gateways, and event-driven architectures with circuit breaker, retry, DLQ, and idempotency patterns; files GitHub Issues with `tech-debt,middleware,reliability` labels
- Added `agents/data-tier.agent.md`: designs schemas, writes reversible migrations, optimizes queries, and establishes data access patterns; files GitHub Issues with `tech-debt,data,performance` labels for N+1 queries, missing indexes, SELECT *, missing rollbacks, and hardcoded IDs
- Added `skills/backend-dev/SKILL.md`: skill overview, invocation guide, and template index
- Added `skills/backend-dev/api-spec-template.md`: OpenAPI 3.x-compatible API spec skeleton with example paths, components, pagination, and error schemas
- Added `skills/backend-dev/service-template.md`: service layer scaffold with dependency injection, structured error types, logging stubs, and testing expectations
- Added `skills/backend-dev/error-catalog-template.md`: structured error catalog with codes, messages, HTTP status codes, and resolution hints
- Added `skills/backend-dev/repository-pattern-template.md`: data access repository pattern boilerplate with parameterized queries, pagination, and soft delete support
- Added `skills/frontend-dev/SKILL.md`: skill overview, invocation guide, and template index
- Added `skills/frontend-dev/component-spec-template.md`: component specification covering props, events, slots, all UI states, accessibility requirements, and test plan
- Added `skills/frontend-dev/accessibility-checklist.md`: WCAG 2.1 AA checklist organized by perceivable, operable, understandable, and robust principles with issue-filing guidance
- Added `skills/frontend-dev/state-management-template.md`: state structure template covering local state, shared state, async lifecycle phases, error state, and derived state
- Added `skills/data-tier/SKILL.md`: skill overview, invocation guide, and template index
- Added `skills/data-tier/schema-design-template.md`: schema design document covering entities, columns, constraints, indexes, relationships, and ERD scaffold
- Added `skills/data-tier/migration-template.md`: migration scaffold with up/down blocks, pre-migration checklist, rollback plan, and zero-downtime strategies
- Added `skills/data-tier/query-review-checklist.md`: query review covering N+1 detection, index usage, pagination, SELECT * checks, and explain plan interpretation
- Added `skills/data-tier/data-dictionary-template.md`: data dictionary template covering table, column, type, nullable, description, and example values
- Added `instructions/development.instructions.md`: shared standards for all four dev core agents covering code style, error handling, security, logging, testing, issue filing, and agent collaboration handoff order

## 0.5.0 - 2026-03-19

- Added `agents/manual-test-strategy.agent.md`: produces decision rubric, exploratory charter, regression checklist, defect template, and automation backlog; files GitHub Issues for all automation candidates
- Added `agents/exploratory-charter.agent.md`: generates time-boxed exploratory sessions with mission, scope, evidence capture, and triage routing; files GitHub Issues for automation-worthy findings
- Added `agents/strategy-to-automation.agent.md`: converts manual paths into tiered automation candidates (smoke, regression, integration, agent spec); files a GitHub Issue for every candidate without exception
- Added `skills/manual-test-strategy/SKILL.md`: skill description, when to use, and agent invocation guide
- Added `skills/manual-test-strategy/rubric-template.md`: decision rubric template for manual-only, automate-now, and hybrid classification with risk scoring matrix
- Added `skills/manual-test-strategy/charter-template.md`: exploratory charter template with mission, time box, scope, evidence log, and triage routing
- Added `skills/manual-test-strategy/checklist-template.md`: regression checklist template with automation candidate flagging
- Added `skills/manual-test-strategy/defect-template.md`: defect evidence template with reproduction steps, impact, diagnostic context, and automation handoff section
- Updated `instructions/testing.instructions.md`: added Manual Test Strategy section referencing all three agents, the skill, the decision rubric, and automation handoff expectations

## 0.4.2 - 2026-03-19

- Fixed Windows PowerShell test runner to clear expected nonzero scanner exit codes
- Stabilized the tag-triggered packaging workflow so release validation can complete on both runners

## 0.4.1 - 2026-03-19

- Fixed commit-message scanner negative tests to scan the actual latest sensitive commit
- Stabilized GitHub Actions validation for packaging and release workflows

## 0.4.0 - 2026-03-19

- Added MCP standards guidance for server allowlisting, tool safety, and governance
- Added repository template standard for lock-based bootstrap and drift enforcement
- Added a sample repository template with bootstrap and enforcement workflows
- Added CI validation for the sample repository template assets
- Fixed PowerShell packaging and hook-install scripts to remove duplicated execution blocks

## 0.3.0 - 2026-03-19

- Added sample Azure, naming, Terraform, and Bicep instruction files
- Added authoring skills for creating new skills and instructions
- Added sample workflow agents for customization creation and repo rollout
- Added enterprise packaging and validation scripts for PowerShell and bash
- Added GitHub Actions workflows for validation and release packaging
- Added example consumer workflows and starter IaC examples for Azure with Bicep and Terraform

## 0.2.0 - 2026-03-19

- Added YAML frontmatter to starter customization files for better discovery and validity
- Expanded instructions with common best-practice sets for security, reliability, and documentation
- Added a refactoring skill and a bugfix prompt
- Updated inventory and README to reflect the broader base set

## 0.1.0 - 2026-03-19

- Initial repository scaffold
- Added sync scripts for PowerShell and bash consumers
- Added starter instructions, prompts, skills, and agent files
- Added inventory and version metadata
