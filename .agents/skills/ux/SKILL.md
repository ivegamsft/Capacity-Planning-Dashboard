---

name: ux
description: "Use when designing user experiences, mapping user journeys, specifying wireframes or components, or auditing accessibility. Provides journey mapping templates, wireframe specs, component design specs, and WCAG 2.1 AA checklists."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# UX Design Skill

Use this skill when the task involves designing user experiences, mapping user journeys, specifying UI wireframes or components, or auditing designs for accessibility and usability.

## When to Use

- Mapping a user journey for a new or existing feature
- Specifying wireframe layouts and interaction patterns
- Writing component design specs for a design system
- Auditing a design or implementation for WCAG 2.1 AA accessibility compliance
- Reviewing a design against usability heuristics

## How to Invoke

Reference this skill by attaching `skills/ux/SKILL.md` to your agent context, or instruct the agent:

> Use the ux skill. Apply the user journey template, wireframe spec template, and accessibility audit checklist to the feature being designed.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `user-journey-template.md` | End-to-end user journey mapping with personas, steps, emotions, and opportunities |
| `wireframe-spec-template.md` | Screen-level wireframe specification with layout, content hierarchy, and interaction states |
| `accessibility-audit-checklist.md` | WCAG 2.1 AA compliance checklist organized by principle (Perceivable, Operable, Understandable, Robust) |
| `component-spec-template.md` | Figma-compatible component design spec with anatomy, variants, states, spacing, and accessibility |

## Agent Pairing

This skill is designed to be used alongside the `ux-designer` agent. The agent drives the workflow; this skill provides the reference templates and standards.

For implementation, the ux-designer agent produces specs that the `frontend-dev` agent consumes. Route accessibility violations to the `ux-designer` agent for remediation guidance, then to `frontend-dev` for implementation fixes.
