---

name: architecture
description: "Use when designing systems, recording architecture decisions, evaluating technologies, or assessing architectural risks. Provides C4 diagram templates, ADR format, technology selection matrices, and risk registers."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Architecture Skill

Use this skill when the task involves system design, architecture documentation, technology evaluation, or risk assessment at the architecture level.

## When to Use

- Designing a new system or decomposing an existing one into services and components
- Creating C4 context, container, or component diagrams
- Recording an architecture decision (ADR)
- Evaluating competing technologies for a project
- Identifying and tracking architectural risks
- Reviewing cross-cutting concerns (auth, observability, data residency, resilience)

## How to Invoke

Reference this skill by attaching `skills/architecture/SKILL.md` to your agent context, or instruct the agent:

> Use the architecture skill. Apply the C4 diagram template for the system context, record the database decision as an ADR, and evaluate the messaging options using the tech selection matrix.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `adr-template.md` | Architecture Decision Record with status lifecycle, context, decision, and consequences |
| `c4-diagram-template.md` | C4 context and container diagram templates in Mermaid syntax |
| `tech-selection-matrix-template.md` | Weighted scoring matrix for evaluating technology alternatives |
| `risk-register-template.md` | Architecture risk register with likelihood, impact, and mitigation tracking |

## Agent Pairing

This skill is designed to be used alongside the `solution-architect` agent. The agent drives the architecture workflow; this skill provides the reference templates and standards.

For implementation details, hand off to domain-specific agents: `backend-dev` for API and service design, `frontend-dev` for UI architecture, and `data-tier` for database and storage design.
