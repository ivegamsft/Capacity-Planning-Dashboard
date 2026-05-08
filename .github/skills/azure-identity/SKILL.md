---

name: azure-identity
description: "Use when designing Azure identity architectures — RBAC role assignments, managed identities, Entra ID app registrations, conditional access policies, or workload identity federation for CI/CD. Covers zero trust patterns, PIM, and GitHub OIDC."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure Identity & Entra ID Skill

Use this skill when the task involves designing or implementing identity and access management on Azure — including RBAC hierarchies, managed identity configurations, Entra ID app registrations, conditional access policies, and workload identity federation.

## When to Use

- Mapping application and service identity requirements for a workload
- Designing RBAC role hierarchies with custom roles, scope assignments, or Privileged Identity Management (PIM)
- Generating managed identity configurations for Azure resources (VMs, App Services, Container Apps, AKS)
- Producing Entra ID app registration templates with API permissions and credential policies
- Designing conditional access policies for zero trust enforcement
- Generating workload identity federation configurations for GitHub Actions OIDC

## How to Invoke

Reference this skill by attaching `skills/azure-identity/SKILL.md` to your agent context, or instruct the agent:

> Use the azure-identity skill. Apply the RBAC role assignment template and managed identity mapping template to the workload being designed.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `rbac-role-assignment-template.md` | RBAC role assignment matrix for documenting principal-to-role-to-scope mappings |
| `managed-identity-mapping-template.md` | Managed identity mapping for cataloguing system-assigned and user-assigned identities per workload |
| `app-registration-checklist.md` | Entra ID app registration checklist covering API permissions, credentials, and token configuration |
| `workload-identity-federation-template.md` | Workload identity federation configuration for GitHub Actions OIDC and other external identity providers |
| `conditional-access-policy-template.md` | Conditional access policy template for zero trust enforcement across users, devices, and applications |

## Agent Pairing

This skill is designed to be used alongside the `identity-architect` agent. The agent drives the identity design workflow; this skill provides the reference templates and standards.

For infrastructure provisioning of identity resources, coordinate with the `devops-engineer` agent using Bicep or Terraform. For application-level auth integration, coordinate with the `backend-dev` or `frontend-dev` agents. For security threat modeling of identity boundaries, pair with the `security-analyst` agent.
