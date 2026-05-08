---
description: "Model-routing recommendations for Copilot CLI tasks. Maps task types to optimal model tiers based on complexity, accuracy requirements, and cost targets."
---

# Model Routing Recommendations

**Prepared for:** <!-- agent name or workflow -->
**Date:** <!-- YYYY-MM-DD -->
**Based on session:** <!-- session ID, PR, or issue reference -->

## Current Routing Profile

| Task Type | Model Currently Used | Frequency (dispatches/session) | Est. Cost Share |
|---|---|---|---|
| | | | |
| | | | |

## Routing Recommendations

For each task type identified above, evaluate against the decision criteria below.

### Decision Criteria

| Factor | Lightweight Model | Balanced Model | High-Capability Model |
|---|---|---|---|
| Reasoning depth required | Low (lookup, label, classify) | Medium (code gen, structured output) | High (multi-file reasoning, architecture, threat modeling) |
| Output accuracy tolerance | Approximate acceptable | Mostly accurate required | Exact or critical |
| Context window needed | < 8 K tokens | 8 K – 32 K tokens | > 32 K tokens |
| Security / compliance risk | No | Low–Medium | High |
| Typical cost per call | Lowest | Mid | Highest |

### Recommended Changes

| Task Type | Current Model | Recommended Model | Justification | Est. Monthly Savings |
|---|---|---|---|---|
| | | | | |
| | | | | |

## Model Tier Reference

| Tier | Example Models | Best For |
|---|---|---|
| Lightweight | GPT-4o-mini, Claude Haiku | Triage, classification, short summaries, simple rewrites |
| Balanced | GPT-4o, Claude Sonnet | Code generation, refactoring, documentation, structured analysis |
| High-capability | Claude Opus, o1 | Complex reasoning, architecture, security-critical tasks |

## Guardrails for Routing Changes

- Never downgrade the model for tasks tagged security, compliance, or data-loss risk.
- Validate routing changes against a representative sample (≥ 10 sessions) before committing.
- Monitor output quality after every downgrade for at least two sprint cycles.
- Document the justification for every downgrade in this template before implementing.

## Next Review Date

<!-- Set a review date 30 days from today to validate that savings were realized and quality was maintained. -->
