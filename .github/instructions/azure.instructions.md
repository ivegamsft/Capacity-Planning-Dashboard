---
description: "Use when working on Azure services, Azure SDK integrations, Azure deployment configuration, or cloud architecture for Azure. Covers secure Azure defaults, authentication, and service usage patterns."
applyTo: "**/*.{bicep,bicepparam,tf,tfvars,ps1,sh,md,json,yml,yaml,ts,js,py,cs}"
---

# Azure Standards

Use this instruction when changes touch Azure-hosted applications, SDK usage, infrastructure, or operational configuration.

## Expectations

- Prefer managed identity for Azure-hosted workloads over connection strings and access keys.
- Never hardcode credentials. Use Key Vault or secure environment configuration.
- Use least privilege for both management-plane and data-plane access.
- Add retries, timeouts, and logging for transient cloud operations.
- Prefer current Azure services and current SDK versions over legacy service patterns when starting new work.
- Keep regional, quota, and cost implications visible when proposing Azure resources.

## Review Lens

- Is authentication appropriate for where the code will run?
- Are secrets and certificates kept out of source control?
- Are Azure-specific failure modes handled clearly?
- Does the change require infrastructure, RBAC, or deployment documentation updates?
