---
name: basecoat
title: Base Coat Router & Agent Discovery
description: Single entry point for 28+ agents across 6 disciplines—discover or delegate across Development, Architecture, Quality, DevOps, Process, and Meta
compatibility: ["agent:*"]
metadata:
  domain: framework
  maturity: production
  audience: [all]
allowed-tools: [bash, curl, git]
---

# Base Coat Router

The front door to the entire Base Coat framework. This skill routes requests to the right agent across 6 disciplines: Development, Architecture, Quality, DevOps, Process, and Meta.

Two modes of operation:
- **Discovery** — browse, search, and learn about available agents
- **Delegation** — route a prompt directly to the right agent

---

## Usage Modes

### Discovery Mode

Use discovery when you want to explore what's available or need help picking the right agent.

| Command | What It Does |
|---------|--------------|
| `/basecoat` | Full categorized agent catalog |
| `/basecoat development` | Show only Development agents |
| `/basecoat quality` | Show only Quality agents |
| `/basecoat help [agent-name]` | Detailed usage card for one agent |
| `/basecoat find "[search term]"` | Fuzzy search across agent keywords |

When showing discovery results, format them by category:

#### 🔨 Development

| Agent | Description | Invoke With |
|-------|-------------|-------------|
| @backend-dev | APIs, services, business logic | `/basecoat backend [prompt]` |
| @frontend-dev | UI, components, accessibility | `/basecoat frontend [prompt]` |
| @middleware-dev | API gateways, integration, events | `/basecoat middleware [prompt]` |
| @data-tier | Schema, migrations, queries | `/basecoat data [prompt]` |

#### 🏗️ Architecture

| Agent | Description | Invoke With |
|-------|-------------|-------------|
| @solution-architect | System design, trade-offs, ADRs | `/basecoat architect [prompt]` |
| @api-designer | OpenAPI specs, API contracts | `/basecoat api-design [prompt]` |
| @ux-designer | Wireframes, accessibility, UX flows | `/basecoat ux [prompt]` |

#### 🔍 Quality

| Agent | Description | Invoke With |
|-------|-------------|-------------|
| @code-review | Code review, pull-request feedback | `/basecoat review [prompt]` |
| @security-analyst | Vulnerability scanning, threat models | `/basecoat security [prompt]` |
| @performance-analyst | Profiling, bottleneck analysis | `/basecoat perf [prompt]` |
| @config-auditor | Config hygiene, secrets audit | `/basecoat config [prompt]` |
| @manual-test-strategy | Test plans, manual test cases | `/basecoat manual-test [prompt]` |
| @exploratory-charter | Exploratory testing charters | `/basecoat exploratory [prompt]` |
| @strategy-to-automation | Convert test strategy to automation | `/basecoat automate-tests [prompt]` |

#### 🚀 DevOps

| Agent | Description | Invoke With |
|-------|-------------|-------------|
| @devops-engineer | CI/CD pipelines, infrastructure | `/basecoat devops [prompt]` |
| @release-manager | Versioning, changelogs, releases | `/basecoat release [prompt]` |
| @rollout-basecoat | Enterprise onboarding, rollout plans | `/basecoat rollout [prompt]` |

#### 📋 Process

| Agent | Description | Invoke With |
|-------|-------------|-------------|
| @sprint-planner | Sprint planning, wave breakdown | `/basecoat sprint [prompt]` |
| @product-manager | Requirements, user stories, PRDs | `/basecoat product [prompt]` |
| @issue-triage | Issue classification, labeling | `/basecoat triage [prompt]` |
| @retro-facilitator | Retrospective facilitation | `/basecoat retro [prompt]` |
| @project-onboarding | Project setup, getting-started guides | `/basecoat onboarding [prompt]` |

#### 🧰 Meta

| Agent | Description | Invoke With |
|-------|-------------|-------------|
| @agent-designer | Design new agents | `/basecoat agent [prompt]` |
| @prompt-engineer | System prompts, prompt tuning | `/basecoat prompt [prompt]` |
| @mcp-developer | MCP tool servers | `/basecoat mcp [prompt]` |
| @tech-writer | Docs, runbooks, ADRs | `/basecoat docs [prompt]` |
| @new-customization | Create new skills/customizations | `/basecoat customization [prompt]` |
| @merge-coordinator | Parallel merge conflict resolution | `/basecoat merge [prompt]` |

---

### Delegation Mode

When a discipline keyword and prompt are provided, the router delegates directly:

```
/basecoat backend build a REST API for user management
→ Delegates to @backend-dev with prompt "build a REST API for user management"

/basecoat review check auth module for SQL injection
→ Delegates to @security-analyst

/basecoat sprint plan sprint 12 from open issues
→ Delegates to @sprint-planner
```

---

## Keyword-to-Agent Routing Table

Use this table to match user input to the correct agent.

| Keyword(s) | Agent | Category |
|------------|-------|----------|
| backend, api, server | @backend-dev | 🔨 Development |
| frontend, ui, web | @frontend-dev | 🔨 Development |
| middleware, integration, gateway | @middleware-dev | 🔨 Development |
| data, database, db | @data-tier | 🔨 Development |
| architect, design, system | @solution-architect | 🏗️ Architecture |
| api-design, openapi, swagger | @api-designer | 🏗️ Architecture |
| ux, accessibility, wireframe | @ux-designer | 🏗️ Architecture |
| review, cr, pull-request | @code-review | 🔍 Quality |
| security, vulnerability, threat | @security-analyst | 🔍 Quality |
| perf, performance, profiling | @performance-analyst | 🔍 Quality |
| config, secrets, audit | @config-auditor | 🔍 Quality |
| manual-test, test-strategy | @manual-test-strategy | 🔍 Quality |
| exploratory, charter | @exploratory-charter | 🔍 Quality |
| automate-tests, test-automation | @strategy-to-automation | 🔍 Quality |
| devops, cicd, deploy, pipeline | @devops-engineer | 🚀 DevOps |
| release, version, changelog | @release-manager | 🚀 DevOps |
| rollout, onboard-enterprise | @rollout-basecoat | 🚀 DevOps |
| sprint, plan, wave | @sprint-planner | 📋 Process |
| product, requirements, stories | @product-manager | 📋 Process |
| triage, classify, label | @issue-triage | 📋 Process |
| retro, retrospective | @retro-facilitator | 📋 Process |
| onboarding, setup, getting-started | @project-onboarding | 📋 Process |
| agent, create-agent | @agent-designer | 🧰 Meta |
| prompt, system-prompt | @prompt-engineer | 🧰 Meta |
| mcp, tools, tool-server | @mcp-developer | 🧰 Meta |
| docs, document, runbook | @tech-writer | 🧰 Meta |
| customization, create-skill | @new-customization | 🧰 Meta |
| merge, conflict, parallel-merge | @merge-coordinator | 🧰 Meta |

---

## Delegation Instructions

When routing a `/basecoat [keyword] [prompt]` request:

1. **Match** the first token after `/basecoat` against the keyword column in the routing table above.
2. **Ambiguous match?** If multiple agents could fit, show the top 2–3 candidates with a one-line description and ask the user to pick.
3. **Load the agent** — open the matched agent's instruction file and its paired skill from the `skills/` directory.
4. **Pass the prompt** — forward everything after the keyword as the user's prompt to the loaded agent.
5. **No match?** Fall back to the full discovery menu with a note:
   > I couldn't match "xyz" to a specific agent. Here's the full catalog — pick the one that fits:

---

## Metadata Reference

The file `basecoat-metadata.json` at the repository root contains the machine-readable registry of all 28 agents. It includes:

- Agent names, descriptions, and file paths
- Category groupings
- Keywords and aliases for routing
- Paired skill references

The router can reference this file for programmatic matching when keyword lookup alone is insufficient.

---

## Examples

```text
# ── Discovery ──────────────────────────────────────────────
/basecoat                        → Full agent catalog by category
/basecoat architecture           → Architecture agents only
/basecoat help code-review       → Detailed usage card for @code-review
/basecoat find "deploy"          → Finds @devops-engineer, @release-manager

# ── Delegation ─────────────────────────────────────────────
/basecoat backend build a REST API for orders
/basecoat security run threat model for auth service
/basecoat sprint plan sprint 5 from open issues
/basecoat docs write a runbook for deployment
/basecoat agent design a new linting agent
/basecoat perf profile the checkout flow for latency
```
