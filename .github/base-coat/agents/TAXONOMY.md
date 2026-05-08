# Agent Taxonomy

Agents are classified across three dimensions:

## Dimensions

### Model (LLM capability tier)

| Tier | Use Case | Examples |
|------|----------|----------|
| **reasoning** | Complex multi-step analysis, architecture decisions, multi-file changes | solution-architect, legacy-modernization |
| **balanced** | General implementation, code review, standard workflows | backend-dev, frontend-dev, devops-engineer |
| **fast** | High-volume triage, simple transforms, boilerplate generation | issue-triage, new-customization, merge-coordinator |

### Task (SDLC phase)

| Phase | Purpose | Examples |
|-------|---------|----------|
| **plan** | Architecture, design, strategy, requirements | solution-architect, api-designer, product-manager |
| **build** | Code generation, implementation, refactoring | backend-dev, frontend-dev, middleware-dev |
| **test** | Quality assurance, security, chaos engineering | code-review, chaos-engineer, security-analyst |
| **deploy** | CI/CD, release, infrastructure provisioning | devops-engineer, infrastructure-deploy, release-manager |
| **operate** | Monitoring, incident response, SRE, observability | sre-engineer, incident-responder, performance-analyst |

### Type (interaction pattern)

| Pattern | Behavior | Examples |
|---------|----------|----------|
| **autonomous** | Runs end-to-end without human input | self-healing-ci, issue-triage, merge-coordinator |
| **collaborative** | Human-in-the-loop, produces artifacts for review | code-review, solution-architect, tech-writer |
| **reactive** | Triggered by events (CI failure, alert, PR) | incident-responder, self-healing-ci, guardrail |

## Registry

<!-- Each agent is tagged with [model, task, type] -->

| Agent | Model | Task | Type |
|-------|-------|------|------|
| agent-designer | balanced | build | collaborative |
| agentops | balanced | operate | collaborative |
| api-designer | reasoning | plan | collaborative |
| app-inventory | balanced | plan | autonomous |
| backend-dev | balanced | build | collaborative |
| chaos-engineer | balanced | test | autonomous |
| code-review | balanced | test | collaborative |
| config-auditor | fast | operate | reactive |
| containerization-planner | reasoning | plan | collaborative |
| data-tier | balanced | build | collaborative |
| dataops | balanced | deploy | collaborative |
| dependency-lifecycle | fast | operate | autonomous |
| devops-engineer | balanced | deploy | collaborative |
| exploratory-charter | balanced | test | collaborative |
| feedback-loop | fast | operate | reactive |
| frontend-dev | balanced | build | collaborative |
| github-security-posture | balanced | operate | collaborative |
| guardrail | fast | test | reactive |
| incident-responder | reasoning | operate | reactive |
| infrastructure-deploy | balanced | deploy | autonomous |
| issue-triage | fast | plan | autonomous |
| legacy-modernization | reasoning | build | collaborative |
| llmops | balanced | deploy | collaborative |
| manual-test-strategy | balanced | test | collaborative |
| mcp-developer | balanced | build | collaborative |
| memory-curator | fast | operate | autonomous |
| merge-coordinator | fast | deploy | autonomous |
| middleware-dev | balanced | build | collaborative |
| mlops | balanced | deploy | collaborative |
| new-customization | fast | build | autonomous |
| performance-analyst | balanced | test | collaborative |
| policy-as-code-compliance | reasoning | deploy | collaborative |
| product-manager | reasoning | plan | collaborative |
| project-onboarding | balanced | plan | autonomous |
| prompt-coach | balanced | build | collaborative |
| prompt-engineer | balanced | build | collaborative |
| release-impact-advisor | balanced | deploy | collaborative |
| release-manager | balanced | deploy | collaborative |
| retro-facilitator | balanced | plan | collaborative |
| rollout-basecoat | balanced | deploy | autonomous |
| security-analyst | reasoning | test | collaborative |
| self-healing-ci | fast | deploy | reactive |
| solution-architect | reasoning | plan | collaborative |
| sprint-planner | balanced | plan | collaborative |
| sre-engineer | balanced | operate | reactive |
| strategy-to-automation | reasoning | plan | collaborative |
| tech-writer | balanced | build | collaborative |
| ux-designer | balanced | plan | collaborative |

## Usage

Select agents by filtering on any dimension:

```bash
# Find all autonomous deploy agents
grep -E "autonomous.*deploy|deploy.*autonomous" agents/TAXONOMY.md

# Find reasoning-tier agents for planning
grep -E "reasoning.*plan" agents/TAXONOMY.md
```

Or reference by directory:

```text
agents/models/reasoning/   → agents needing opus-class models
agents/tasks/deploy/       → agents for CI/CD and release
agents/types/reactive/     → event-driven agents
```
