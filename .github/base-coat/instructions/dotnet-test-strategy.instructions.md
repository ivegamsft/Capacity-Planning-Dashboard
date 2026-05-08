---
description: ".NET modernization test strategy and regression-gate guidance."
applyTo: "**/*.{sln,csproj,cs,yml,yaml}"
---

# .NET Test Strategy

## Objective

Define and enforce a test strategy that protects behavior, performance, and operability during .NET modernization.

## Required steps

1. Establish baseline test coverage and identify critical business paths.
2. Map unit, integration, and end-to-end coverage to each migration phase.
3. Add regression criteria for API behavior, data access, and performance.
4. Require CI quality gates before phase promotion.

## Output expectations

- Phase-by-phase test matrix
- Entry/exit criteria for each modernization wave
- Post-deployment validation checks and rollback triggers
