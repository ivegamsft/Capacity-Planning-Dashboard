---
description: "Use when selecting models, escalating reasoning cost, or loading context. Enforces cost-aware routing and token budget discipline for all agent work."
applyTo: "**/*"
---

# Token Economics

Use this instruction whenever choosing a model, deciding how much context to load, or escalating a task to a more expensive tier.

## Expectations

- Match model to task complexity. Do not use premium-tier models for routine automation, scanning, formatting, or simple repository operations.
- Do not use fast-tier models for architecture, security, or other decisions where mistakes are costly or hard to reverse.
- Treat token budget as cumulative session spend, not just the current prompt. Prefer approaches that finish the task with less total context and fewer retries.
- Load only the context needed for the current step. Start narrow, then expand only when the task justifies it.
- If a premium-tier model is required, state why the higher cost is justified and what tradeoff it avoids.
- Do not re-read files that are already in context unless the file changed or a missing section is genuinely needed.
- Do not load entire files when a targeted section, diff, symbol, or summary is sufficient.

## Model Tier Guidance

- **Premium** — Use for high-stakes, irreversible, or trust-without-second-opinion decisions such as architecture direction, security analysis, compliance interpretation, and major cross-system tradeoffs.
- **Reasoning** — Use for analysis, code review, research, test strategy, planning, and other work that needs structured judgment but not the highest-cost tier.
- **Code** — Use for implementation, refactoring, debugging, migration, and code generation tasks where code quality matters more than broad strategic reasoning.
- **Fast** — Use for routine automation, scanning, formatting, status checks, simple transformations, and other well-defined tasks with clear inputs and easy validation.

## Context Loading Discipline

**Classify intent before loading any context.** Intent classification is free — it uses only what is already in context (user message + L2 memory index). Context loading happens *after* classification, not before.

Load context in this order:

1. **Intent classification** — match against L2 trigger map; assign fast path or full path
2. **Fast path (confidence ≥ 0.80)**: load the pattern bundle only — pre-scoped instructions + docs for this intent type. Skip broad exploration.
3. **Full path (confidence < 0.80 or Novel)**: load in layered order:
   - Governing instructions and the immediate task
   - The exact files, symbols, or sections needed to act
   - Supporting docs, adjacent files, or history only if the task still cannot be completed
   - Broad repository context only as a last resort

Prefer targeted searches, line ranges, summaries, diffs, and handoffs before loading full files or large document sets.

See `docs/execution-hierarchy.md` for the full stack, pattern bundle catalog, and confidence lifecycle.

## Cost Escalation

Before escalating to a premium-tier model, confirm that the task involves one or more of the following:

- irreversible or expensive decisions
- deep cross-file or cross-system reasoning
- security, compliance, or policy-sensitive analysis
- output that will be trusted with minimal human correction

When escalating, explicitly mention the tradeoff: higher cost is being accepted to reduce risk, avoid rework, or improve decision quality.

## Avoid Waste

- Reuse context already loaded in the session when it is still current.
- Prefer incremental reads over repeated full-file reads.
- Summarize large context before handing it to a higher-tier model.
- Break broad work into smaller steps when doing so reduces total token spend.
- Prefer the cheapest model tier that can complete the task reliably.

## References

- `docs/MODEL_OPTIMIZATION.md` — model tier matrix, overrides, and cost guidance
- `docs/token-optimization.md` — context window strategy, compression, caching, and token budget patterns

## Turn Budget and Learning Cost

Classify each task before starting. State the classification at the top of your plan.

| Class | Definition | Soft turn budget |
|---|---|---|
| **Routine** | Matches a known pattern already covered by instructions or memory | ≤ 3 turns |
| **Familiar** | Partial match — similar to prior work but with new variables | ≤ 5 turns |
| **Novel** | No prior coverage; first time encountering this pattern | Estimate N turns upfront as learning cost; state it explicitly |

Novel tasks pay a learning cost. That cost is real and expected — do not treat a Novel task overrunning its estimate as failure. Once completed, it becomes Familiar for next time.

### Failure Protocol — Stuck After 5 Turns

If a task has consumed more than 5 turns **and** there has been no measurable forward progress, stop and reassess. Do not continue with "more of the same."

Forward progress means at least one of:
- A new test passes that did not pass before
- A new error class is resolved (not just the same error with a different message)
- A file reaches its intended target state
- A blocker is identified and removed

**When stuck:**
1. Log the failure pattern to memory: task description, approach tried, failure mode, and blocking signal.
2. Reassess: try a different approach, escalate the model tier, break the task into smaller units, or flag as blocked.
3. Do not escalate model tier as the first response — change the approach first.

### Success Protocol — Completed Within Budget + Test Validation

When a task completes within its turn budget and tests pass, evaluate whether the solution involved a non-obvious pattern not already covered by existing instructions.

- **If yes:** call `store_memory` with the pattern, the context it applies to, and the test that validated it. This converts learning cost into reusable knowledge and lowers future turn budgets.
- **If no:** skip. Reinforcing well-known patterns wastes memory slots and dilutes signal.

### Progress Tracking

Track actual turns against the estimated budget as you work. If you reach 80% of your budget with less than 50% progress, pause and reassess before continuing — do not wait until fully stuck.

## Review Lens

- Is the chosen model tier the lowest-cost tier that can do the work reliably?
- Was context loaded in priority order rather than dumped all at once?
- Were already-loaded files reused instead of re-read?
- Were targeted sections used instead of whole-file reads where possible?
- If premium-tier reasoning was used, was the cost-quality tradeoff stated explicitly?
- Was the task classified (Routine/Familiar/Novel) before starting?
- If stuck past 5 turns, was the failure logged and approach changed?
- If completed within budget with test validation, was a novel pattern reinforced to memory?
