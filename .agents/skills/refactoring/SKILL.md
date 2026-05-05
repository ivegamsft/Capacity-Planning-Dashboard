---

name: refactoring
description: "Use when simplifying structure without intentionally changing behavior. Covers common refactoring best practices for preserving behavior, reducing risk, and validating changes."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Refactoring

Use this skill when the goal is to improve code structure, readability, or maintainability while keeping behavior stable.

## Workflow

1. Identify the specific pain point: duplication, naming, long functions, mixed responsibilities, or hidden dependencies.
2. Protect current behavior with existing tests or add narrow characterization tests when needed.
3. Make one structural move at a time: extract, rename, isolate side effects, or split modules.
4. Re-run relevant validation after each meaningful step.
5. Stop when the code is materially clearer; do not refactor past the point of value.

## Guardrails

- Keep public APIs stable unless the task explicitly allows breaking changes.
- Prefer small mechanical refactors over broad rewrites.
- Separate behavior changes from structure changes when practical.
- Remove dead code only when you have enough evidence it is unused.

## Output

- Structural problems addressed
- Safety checks used
- Main refactors applied
- Residual risks or deferred cleanup
