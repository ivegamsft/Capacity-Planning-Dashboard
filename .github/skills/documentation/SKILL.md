---

name: documentation
description: "Use when writing or improving technical documentation, READMEs, ADRs, runbooks, or implementing docs-as-code practices. Provides templates for common documentation types."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Documentation Skill

Use this skill when the task involves creating, updating, or reviewing technical documentation of any kind.

## When to Use

- Creating a new README or project overview
- Recording an architecture decision (ADR)
- Writing an operational runbook
- Reviewing existing docs for accuracy and completeness
- Establishing documentation standards for a project
- Writing API reference documentation

## How to Invoke

Reference this skill by attaching `skills/documentation/SKILL.md` to your agent context, or instruct the agent:

> Use the documentation skill. Apply the ADR template to document our decision to adopt PostgreSQL.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `readme-template.md` | Project README structure — overview, setup, usage, and contributing |
| `adr-template.md` | Architecture Decision Record — context, decision, and consequences |
| `runbook-template.md` | Operational runbook — trigger, steps, rollback, and escalation |

## Agent Pairing

This skill is designed to be used alongside the following agents:

- **tech-writer** — Drives documentation creation using these templates
- **solution-architect** — Provides architectural context for ADRs
- **devops-engineer** — Provides operational context for runbooks
- **product-manager** — Provides feature context for user-facing documentation

For code-level documentation (inline comments, docstrings), coordinate with the `backend-dev` or `frontend-dev` agents.
