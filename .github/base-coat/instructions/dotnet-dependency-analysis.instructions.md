---
description: ".NET dependency compatibility and remediation analysis guidance."
applyTo: "**/*.{sln,csproj,props,targets,json,md}"
---

# .NET Dependency Analysis

## Objective

Analyze direct and transitive dependencies for compatibility with the target .NET runtime and produce a remediation strategy.

## Required steps

1. Generate dependency inventory across all projects.
2. Classify each dependency as compatible, upgradeable, replace-required, or blocked.
3. Flag security and supportability risks for outdated components.
4. Propose replacement/upgrade sequence that minimizes cross-project breakage.

## Output expectations

- Dependency compatibility matrix
- Ordered remediation backlog with risk and owner fields
- Explicit blockers requiring architectural decisions
