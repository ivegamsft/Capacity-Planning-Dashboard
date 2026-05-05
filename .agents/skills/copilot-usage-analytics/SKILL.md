---

name: copilot-usage-analytics
description: "Use when estimating per-session Copilot CLI cost, analyzing model-routing efficiency, tracking agent dispatch patterns, or documenting which GitHub Copilot usage APIs exist. Covers session cost estimation, model selection recommendations, and API landscape mapping."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Copilot Usage Analytics Skill

Use this skill when the goal is to estimate Copilot CLI session costs from dispatch patterns, recommend model-routing strategies based on task complexity, or document the current state of GitHub Copilot usage APIs.

## When to Use

- Estimating cost for a completed or in-progress Copilot CLI session
- Analyzing which sub-agent dispatches are driving the most token consumption
- Choosing the right model tier for a task to minimize cost without sacrificing quality
- Auditing agent workflows for routing inefficiencies
- Generating an ROI report (issues resolved versus estimated spend)
- Documenting which Copilot usage APIs are available versus missing

## How to Invoke

Reference this skill by attaching `skills/copilot-usage-analytics/SKILL.md` to your agent context, or instruct the agent:

> Use the copilot-usage-analytics skill. Apply the session cost estimate template and the model-routing recommendation template to the current session's dispatch log.

## Workflow

1. **Collect dispatch data** — enumerate all tool calls and sub-agent dispatches in the session, noting the model identifier used for each.
2. **Estimate token consumption** — use message length and interaction count as a proxy for input/output tokens per dispatch.
3. **Apply cost rates** — map each model to its published token rate to produce a per-dispatch and per-session cost estimate.
4. **Identify high-cost dispatches** — rank dispatches by estimated cost and flag any where a lighter model would suffice.
5. **Generate routing recommendations** — for each flagged dispatch, recommend an alternative model tier and explain the trade-off.
6. **Produce session summary** — fill in the session cost estimate template with totals, per-model breakdown, and optimization actions.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `templates/session-cost-estimate-template.md` | Per-session cost breakdown by dispatch, model, and estimated token usage |
| `templates/model-routing-recommendation-template.md` | Structured recommendations for right-sizing model selection per task type |
| `templates/api-landscape.md` | Reference map of GitHub Copilot usage APIs — what exists, what is missing, and current workarounds |

## API Landscape Summary

Three data sources were investigated for programmatic Copilot CLI usage data:

| Source | Endpoint | Status | Notes |
|---|---|---|---|
| GitHub REST — Copilot Usage | `GET /orgs/{org}/copilot/usage` | ⚠️ Partial | Returns IDE completion metrics only; CLI/agent token data not exposed |
| GitHub REST — Copilot Billing | `GET /orgs/{org}/copilot/billing` | ⚠️ Partial | Returns seat counts only; no per-model or per-session cost data |
| Power BI Copilot Usage dataset | Dataset `5c6c70ac-*` | ❌ Auth error | Requires separate AAD scope (`AADSTS9010010`); not available via standard MCP token |

Until GitHub exposes per-session usage data (expected via Copilot Metrics API expansion), session cost must be self-tracked using this skill's estimation workflow.

## Model Routing Guidance

| Task Complexity | Recommended Model | Rationale |
|---|---|---|
| Simple lookup, label assignment, short summarization | GPT-4o-mini / Claude Haiku | Low reasoning demand; high token efficiency |
| Code generation, refactoring, structured output | GPT-4o / Claude Sonnet | Balanced quality-to-cost ratio |
| Architecture design, multi-file reasoning, threat modeling | GPT-4o / Claude Sonnet 3.7+ | High accuracy required; cost justified by complexity |
| Creative or exploratory research | Claude Opus | Reserve for tasks where quality difference is measurable |

## Guardrails

- Token estimates are proxies, not exact counts — present them with an explicit uncertainty range.
- Do not use model cost rates that are more than 30 days old; rates change and stale data misleads decisions.
- ROI reports must include the number of issues resolved, not just cost; cost alone is not an actionable metric.
- Do not make routing recommendations that sacrifice correctness for cost on security or compliance tasks.

## Agent Pairing

This skill is designed to be used alongside:

- **agentops agent** (`agents/agentops.agent.md`) — monitors agent lifecycle health and can incorporate cost signals into rollback and routing decisions.
- **performance-analyst agent** (`agents/performance-analyst.agent.md`) — pairs token-cost data with latency and throughput metrics for a full efficiency picture.
- **sprint-planner agent** (`agents/sprint-planner.agent.md`) — uses ROI estimates to prioritize automation investments.
