---

name: "copilot-cli-usage-analytics"
description: "Copilot CLI usage analytics skill. Trigger: 'Copilot CLI usage', 'session cost', 'model dispatch breakdown', 'Copilot CLI cost', 'Copilot CLI analytics'."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Copilot CLI Usage Analytics

Use this skill to estimate per-session Copilot CLI model usage and cost, track agent dispatches, and generate model-routing recommendations. This skill is essential for understanding which sessions are most expensive, identifying model-routing inefficiencies, and supporting ROI analysis.

## Workflow

1. Track tool calls and agent dispatches within the session.
2. Estimate token usage from message lengths and model selection.
3. Record which model each sub-agent used.
4. Generate an end-of-session cost estimate and model-routing recommendations.
5. Document which APIs exist vs don't for Copilot CLI usage.

## Guardrails

- Do not attempt to access unavailable GitHub Copilot usage APIs (REST, Billing, Power BI) directly.
- Only estimate costs based on session-local data; do not claim accuracy beyond self-tracking.
- When GitHub exposes per-session usage data, prefer API integration over estimation.

## Starter Assets

- Template: `templates/usage-report.md` (to be created)

## Folder Structure

```
skills/copilot-cli-usage-analytics/
├── SKILL.md
├── templates/
│   └── usage-report.md
```

## Conventions

- The folder name matches the `name` field in frontmatter.
- `SKILL.md` is the entry point for this skill.
- Discovery keywords are in the `description` field.
