---
description: ".NET upgrade planning checklist and phased execution guidance."
applyTo: "**/*.{sln,csproj,props,targets,cs,json,yml,yaml}"
---

# .NET Upgrade Planning

## Objective

Produce a phased, low-risk upgrade plan from current .NET targets to a supported modern target.

## Required steps

1. Inventory current frameworks, SDKs, runtimes, and package dependencies.
2. Identify unsupported or end-of-life components and classify risk.
3. Define the target runtime and migration sequencing by project boundaries.
4. Add explicit quality gates for build, tests, and deployment validation at each phase.
5. Add rollback criteria and contingency paths for each deployment wave.

## Output expectations

- A concise phased plan with dependencies and blockers
- Risk register with mitigation owner and validation method
- Clear go/no-go gates between phases
