---
description: "Use when creating or reviewing Terraform for Azure or shared infrastructure. Covers provider pinning, state hygiene, modules, validation, and safe Terraform workflows."
applyTo: "**/*.tf"
---

# Terraform Standards

Use this instruction for Terraform changes, especially when provisioning Azure resources.

## Expectations

- Pin Terraform and provider versions explicitly.
- Prefer typed variables, clear descriptions, and narrow outputs.
- Keep secrets out of checked-in `.tfvars` files.
- Use modules to share repeated infrastructure patterns instead of copy-paste resources.
- Make tags and naming inputs first-class where the platform requires consistency.
- Run `terraform fmt`, `terraform validate`, and `terraform plan` before apply.
- Treat remote state, locking, and environment separation as part of the design.

## Review Lens

- Are providers versioned and minimal?
- Is the configuration safe to plan and apply repeatedly?
- Are names, tags, and locations consistent with platform standards?
- Is state management defined clearly for team use?
