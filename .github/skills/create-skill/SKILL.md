---

name: create-skill
description: "Use when creating a new reusable skill for instructions, workflows, or domain guidance. Covers folder layout, frontmatter, discovery language, templates, and validation steps."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Create A Skill

Use this skill when the goal is to add a new `SKILL.md` to a shared customization repository.

## Workflow

1. Define the exact problem the skill should solve repeatedly.
2. Confirm a skill is the right primitive instead of an instruction, prompt, or agent.
3. Create a folder with a stable, discoverable name.
4. Add frontmatter with `name` matching the folder and a description that includes trigger phrases.
5. Write a short workflow with guardrails, expected output, and non-goals.
6. Add templates or examples if the workflow benefits from starter assets.
7. Validate frontmatter and update any catalog or inventory.

## Guardrails

- Keep the skill scoped to one clear workflow.
- Put discovery keywords in the description, not only in the body.
- Avoid broad descriptions that overlap heavily with existing skills.
- Do not create a skill when a file instruction would be sufficient.

## Starter Assets

- Template: `templates/SKILL.template.md`
- Consider adding `examples/` or `templates/` only when they reduce repeated work
