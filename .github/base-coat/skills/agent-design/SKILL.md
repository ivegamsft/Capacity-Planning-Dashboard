---

name: agent-design
description: "Use when designing Copilot agents, authoring agent definitions, creating skill folders, or scaffolding instruction files. Provides templates and conventions for the agent ecosystem."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Agent Design Skill

Use this skill when the goal is to design, scaffold, or author Copilot agent definitions, skill folders, or instruction files for a shared customization repository.

## Template Index

| Template | Purpose | Path |
|---|---|---|
| Agent definition | Scaffold a new `.agent.md` file with frontmatter and standard sections | `agent-template.md` |
| Skill folder | Scaffold a new skill with `SKILL.md` and supporting structure | `skill-template.md` |
| Instruction file | Scaffold a reusable instruction file | `instruction-template.md` |

## When to Use Each Template

- **Agent template** — you need a new autonomous agent with its own workflow, tool grants, and domain guidance.
- **Skill template** — you need a reusable knowledge module that agents can reference but that does not run on its own.
- **Instruction template** — you need a scoped directive that applies to a file, folder, or repository without requiring a full agent or skill.

## Agent Pairing

This skill is designed to work with:

- **agent-designer agent** (`agents/agent-designer.agent.md`) — the primary consumer of these templates. The agent-designer invokes this skill to scaffold new agents and skills.
- **prompt-engineer agent** (`agents/prompt-engineer.agent.md`) — optimizes the instruction text produced by these templates.

## Conventions

- Agent filenames: `<kebab-case-name>.agent.md`
- Skill folders: `skills/<kebab-case-name>/SKILL.md`
- Instruction files: `instructions/<kebab-case-name>.instructions.md`
- All files use YAML frontmatter fenced by `---` as the first content.
- Descriptions must include trigger phrases for discovery.

## Guardrails

- Do not create an agent when a skill or instruction would suffice.
- Do not create a skill that duplicates an existing one — check the inventory first.
- Keep each primitive (agent, skill, instruction) scoped to a single responsibility.
- Validate all frontmatter with a YAML linter before committing.
