---
name: dotnet-modernization
title: .NET Modernization
description: "Structured guidance for .NET modernization from assessment through execution."
compatibility: ["agent:dotnet-modernization-advisor", "agent:legacy-modernization", "agent:backend-dev"]
metadata:
  domain: dotnet
  maturity: production
  audience: [platform-engineer, backend-dev, solution-architect]
allowed-tools: [bash, dotnet, nuget, msbuild, pwsh]
author: IBuySpy-Shared
version: 1.0.0
category: modernization
tags: [dotnet, modernization, migration, upgrade]
---

## .NET Modernization

Use this skill when evaluating, planning, or executing migration from legacy .NET Framework or older .NET targets to modern .NET.

## When to use

- Inventorying a solution before modernization
- Creating phased upgrade plans and risk controls
- Reviewing package/framework compatibility and breaking changes
- Defining test and release gates for modernization waves

## Inputs

- Solution and project files (`*.sln`, `*.csproj`)
- Current runtime and framework versions
- NuGet package graph (direct and transitive)
- CI test coverage and deployment constraints

## Outputs

- Modernization assessment summary
- Phased migration plan with checkpoints
- Dependency remediation recommendations
- Test and rollout strategy

## References

- ./references/breaking-changes.md
