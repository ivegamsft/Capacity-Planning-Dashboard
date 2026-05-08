---

name: azure-landing-zone
description: "Use when designing or scaffolding Azure enterprise-scale landing zones (ESLZ) following the Cloud Adoption Framework. Provides IaC templates for management groups, hub networking, policy assignments, and landing zone vending."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure Landing Zone Skill

Use this skill when the task involves designing, scaffolding, or reviewing an Azure enterprise-scale landing zone (ESLZ) aligned to Microsoft's Cloud Adoption Framework (CAF).

## When to Use

- Designing or documenting a CAF management group hierarchy
- Scaffolding platform subscriptions (Connectivity, Identity, Management)
- Generating hub networking IaC (VNet, Azure Firewall, DNS resolver, Bastion, gateway)
- Assigning regulatory policy initiatives (NIST 800-53, ISO 27001, CIS, PCI-DSS)
- Creating landing zone vending templates for application teams
- Recording architecture decisions for ESLZ design choices

## How to Invoke

Reference this skill by attaching `skills/azure-landing-zone/SKILL.md` to your agent context, or instruct the agent:

> Use the azure-landing-zone skill. Generate a hub networking Bicep module for the Connectivity subscription and assign the NIST 800-53 policy initiative at the Landing Zones management group scope.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `adr-template.md` | Architecture Decision Record for ESLZ design choices (connectivity model, DNS, identity, policy baseline) |
| `platform-subscription-template.bicep` | Bicep module for deploying a platform subscription (Connectivity, Identity, or Management) |
| `hub-networking-template.bicep` | Bicep module for hub virtual network, Azure Firewall, DNS Private Resolver, Bastion, and gateway |
| `policy-assignment-template.json` | Azure Policy initiative assignment parameter file for regulatory baselines |
| `policy-exemption-template.json` | Azure Policy exemption template with required justification and expiration fields |
| `landing-zone-vending-template.bicep` | Bicep module for vending a new application landing zone subscription |

## Agent Pairing

This skill is designed to be used alongside the `azure-landing-zone` agent. The agent drives the ESLZ workflow; this skill provides the reference templates and standards.

For cross-cutting concerns, collaborate with:

- `solution-architect` — for high-level system design and ADRs beyond IaC scope
- `policy-as-code-compliance` — for ongoing policy compliance validation and audit reporting
- `infrastructure-deploy` — for executing Bicep deployments to Azure

## References

- [Azure Landing Zones](https://aka.ms/alz)
- [CAF Enterprise-Scale](https://github.com/Azure/Enterprise-Scale)
- [ALZ-Bicep](https://github.com/Azure/ALZ-Bicep)
