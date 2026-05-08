---

name: api-design
description: "Use when designing, reviewing, or evolving API contracts. Provides OpenAPI templates, breaking-change checklists, versioning decision trees, and governance checklists."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# API Design Skill

Use this skill when the task involves designing new API contracts, reviewing spec changes for breaking changes, choosing a versioning strategy, or enforcing API governance standards.

## When to Use

- Authoring a new OpenAPI 3.x specification from scratch
- Reviewing a spec diff for breaking changes before merge
- Deciding whether a change requires a new API version
- Auditing an existing API against governance standards
- Designing a GraphQL schema or extending an existing graph
- Documenting deprecation and sunset plans

## How to Invoke

Reference this skill by attaching `skills/api-design/SKILL.md` to your agent context, or instruct the agent:

> Use the api-design skill. Apply the OpenAPI template, breaking-change checklist, and governance checklist to the API being designed.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `openapi-template.md` | OpenAPI 3.x skeleton for a new REST API resource with full CRUD, pagination, and error envelopes |
| `breaking-change-checklist.md` | Checklist for evaluating whether a spec change is breaking, with mitigation guidance |
| `versioning-decision-tree.md` | Decision tree for choosing the right versioning action for a given change |
| `api-governance-checklist.md` | Governance checklist that every API spec must pass before approval |

## Agent Pairing

This skill is designed to be used alongside the `api-designer` agent. The agent drives the workflow; this skill provides the reference templates and standards.

For implementation after design, hand off to the `backend-dev` agent. For data model design, coordinate with the `data-tier` agent. For consumer integration, share the spec with the `frontend-dev` agent.
