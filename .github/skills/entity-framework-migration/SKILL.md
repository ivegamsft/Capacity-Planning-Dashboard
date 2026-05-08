---
name: entity-framework-migration
title: Entity Framework Migration
description: "Guidance for migrating Entity Framework legacy codebases to modern EF Core patterns."
compatibility: ["agent:dotnet-modernization-advisor", "agent:data-tier", "agent:backend-dev"]
metadata:
  domain: data
  maturity: production
  audience: [backend-dev, data-engineer, platform-engineer]
allowed-tools: [bash, dotnet, ef-core, sqlcmd, pwsh]
author: IBuySpy-Shared
version: 1.0.0
category: data
tags: [dotnet, entity-framework, ef-core, migration]
---

## Entity Framework Migration

Use this skill when modernizing data layers from Entity Framework 6 or older patterns to EF Core.

## When to use

- Assessing EF6-to-EF Core migration feasibility
- Refactoring data access patterns and DbContext configuration
- Migrating model mappings and conventions
- Planning phased cutovers for schema and query behavior changes

## Inputs

- Existing data access projects and context classes
- Current migration history and database schema constraints
- Query hot paths and performance baselines

## Outputs

- EF migration approach and risk summary
- Mapping and query refactor checklist
- Validation strategy for correctness and performance
