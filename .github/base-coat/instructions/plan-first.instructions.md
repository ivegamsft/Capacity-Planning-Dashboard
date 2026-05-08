---
description: "Use when tasks require multiple steps, cross-file changes, or non-trivial design decisions. Enforces an explore-plan-implement-verify workflow so work stays scoped and intentional."
applyTo: "**/*"
---

# Plan-First Workflow

Use this instruction for any task that is large enough to benefit from explicit thinking before editing files.

## When to Plan

Create a brief plan before implementation when the task involves any of:

- multi-file changes
- architectural or API decisions
- unfamiliar codebases or unclear ownership
- migrations, refactors, or anything with more than two meaningful steps

Skip the formal plan for small, obvious work such as:

- single-file fixes
- typo or wording corrections
- safe one-step changes with a clear outcome

## Five-Phase Workflow

### Phase 0 — Intent Classification (always first, zero extra context cost)

Before loading any context, classify the task:

1. Match the user message against the L2 trigger map in `instructions/memory-index.instructions.md`
2. If a pattern bundle matches with confidence ≥ 0.80 → **Fast Path**: load the bundle's pre-scoped context, apply its turn budget, skip broad exploration
3. If confidence 0.50–0.79 → load the bundle as a starting point but continue with full Explore phase
4. If confidence < 0.50 or no match → **Full Path**: proceed through all phases below

Fast-path tasks skip directly to Phase 2 (Plan) using the bundle's context. Guardrails still fire at their fixed checkpoints regardless of path.

### Phase 1 — Explore (Full Path only)

Inspect the relevant code, constraints, and existing patterns before proposing changes.

### Phase 2 — Plan

Write a short plan covering scope, approach, major risks, and verification criteria.

### Phase 3 — Implement

Execute the plan in small, well-scoped steps instead of attempting the whole task at once.

### Phase 4 — Verify

Run the relevant tests, validation, or manual checks and confirm the result matches the plan.

## Plan Expectations

Keep the plan brief and actionable. Include:

- **Scope** — what will and will not change
- **Approach** — the sequence of steps or components to touch
- **Risks** — key failure modes, dependencies, or unknowns
- **Verification criteria** — how success will be checked

Do not write a novel. The plan should be short enough to guide execution and easy to update.

## Course Correction

If implementation reveals new constraints or the work must diverge from the plan:

- update the plan before continuing, or
- stop and reassess if the original approach is no longer sound

Do not keep executing against a stale plan.

## High-Stakes Changes

Before implementing architectural changes, breaking changes, or other high-impact decisions, confirm the proposed approach with the user or reviewer first.
