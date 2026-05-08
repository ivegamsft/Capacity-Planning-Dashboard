---
description: "Use when creating or reviewing Azure Bicep files or parameter files. Covers symbolic names, parameters, secure values, and Bicep validation best practices."
applyTo: "**/*.{bicep,bicepparam}"
---

# Bicep Standards

Use this instruction for Bicep templates and parameter files.

## Expectations

- Prefer `.bicepparam` files over ARM JSON parameters for new work.
- Use symbolic names instead of `resourceId()` and `reference()` where possible.
- Use `parent` for child resources instead of embedding `/` in resource names.
- Mark sensitive inputs with `@secure()`.
- Keep modules focused and avoid unnecessary module `name` properties.
- Prefer precise types and clear parameter descriptions where the intent is not obvious.
- Validate with `bicep build` and deployment preview tooling before rollout.

## Review Lens

- Are resource types and properties current and real?
- Are secure values protected correctly?
- Is the file composed for reuse instead of one-off duplication?
- Are child resources modeled with parent references rather than string concatenation?
