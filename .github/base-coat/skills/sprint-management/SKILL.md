---

name: sprint-management
description: "Use when planning sprints, running retrospectives, grooming backlogs, or managing sprint ceremonies. Provides templates for sprint planning, retrospectives, and backlog refinement."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Sprint Management Skill

Use this skill when the task involves sprint ceremony facilitation, backlog management, or sprint lifecycle activities.

## When to Use

- Planning a new sprint (capacity, goals, story selection)
- Running a sprint retrospective
- Facilitating backlog grooming / refinement sessions
- Tracking sprint velocity and commitments
- Preparing for sprint demos or reviews

## How to Invoke

Reference this skill by attaching `skills/sprint-management/SKILL.md` to your agent context, or instruct the agent:

> Use the sprint-management skill. Apply the sprint planning template to set up Sprint 15.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `sprint-planning-template.md` | Sprint planning ceremony — goals, capacity, story selection, and commitments |
| `retrospective-template.md` | Sprint retrospective — what went well, what to improve, action items |
| `backlog-grooming-template.md` | Backlog refinement — story review, estimation, acceptance criteria validation |

## Agent Pairing

This skill is designed to be used alongside the following agents:

- **sprint-planner** — Drives sprint planning and velocity tracking
- **product-manager** — Provides prioritized stories and acceptance criteria
- **issue-triage** — Feeds triaged and prioritized issues into the backlog
- **retro-facilitator** — Facilitates retrospective ceremonies

For release-level coordination, pair with the `release-manager` agent.
