---

name: azure-networking
description: "Use when designing Azure networking architectures: hub-spoke VNet topologies, private endpoints, Private DNS zones, NSG rules, Azure Firewall policies, and route tables for hybrid or multi-region connectivity."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure Networking Skill

Use this skill when the task involves designing or generating Azure networking architectures — hub-spoke topologies, private endpoints, DNS zones, NSG rules, Azure Firewall policies, or forced-tunneling route tables.

## When to Use

- Designing a hub-spoke VNet topology with CIDR allocation
- Configuring private endpoints and Private DNS zones for PaaS services
- Producing NSG rule matrices or Azure Firewall policy templates
- Generating UDR route tables for forced tunneling or traffic inspection
- Assessing hybrid, multi-region, or internet-facing connectivity requirements
- Validating designs against Azure networking limits and best practices

## How to Invoke

Reference this skill by attaching `skills/azure-networking/SKILL.md` to your agent context, or instruct the agent:

> Use the Azure networking skill. Generate a hub-spoke topology with private endpoints and NSG rules for a multi-region workload.

## Workflow

1. **Assess connectivity requirements** — identify hybrid (ExpressRoute/VPN), multi-region, and internet-facing needs; document workload tiers and data-classification zones.
2. **Generate hub-spoke VNet topology** — define the hub VNet (firewall, gateway, DNS) and spoke VNets (per workload/environment); allocate CIDR ranges using the CIDR allocation template.
3. **Configure private endpoints and Private DNS zones** — map each PaaS service to its private endpoint and DNS zone using the private-endpoint DNS zone mapping template.
4. **Produce NSG rules and Azure Firewall policy** — define inbound/outbound rules per subnet tier using the NSG rule matrix template; produce Azure Firewall application and network rule collections.
5. **Generate route tables (UDR)** — create UDR entries for forced tunneling to hub firewall; document any asymmetric routing exceptions.
6. **Validate against Azure limits and best practices** — check VNet address-space limits, peering constraints, DNS resolution chain, and private endpoint DNS override precedence.

## Guardrails

- Do not allocate overlapping CIDR ranges across VNets — validate all address spaces before committing.
- Always route internet-bound traffic through Azure Firewall or an NVA in the hub; do not leave spoke subnets with direct internet egress.
- Private endpoint DNS zones must be linked to every VNet that needs name resolution — document each link explicitly.
- NSG rules must include both allow and explicit deny entries; do not rely solely on default deny.
- Do not use `0.0.0.0/0` in NSG allow rules without a compensating Firewall or WAF layer.
- Scope this skill to network-layer design. For identity/RBAC, defer to the `security` skill; for IaC authoring, defer to `devops` or the `terraform`/`bicep` instructions.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `templates/hub-spoke-topology.md` | Mermaid diagram scaffold for hub-spoke VNet topology |
| `templates/cidr-allocation.md` | CIDR allocation table for hub, spokes, and subnets |
| `templates/private-endpoint-dns-zones.md` | PaaS service → private endpoint → Private DNS zone mapping |
| `templates/nsg-rule-matrix.md` | NSG inbound/outbound rule matrix per subnet tier |

## Agent Pairing

This skill is designed to work alongside the `solution-architect` and `devops-engineer` agents. The `solution-architect` agent drives the overall design; this skill provides the network-layer reference patterns and templates.

For IaC output (Terraform or Bicep), pair with the `devops-engineer` agent and the `terraform` or `bicep` instruction files.

## References

- [Hub-spoke network topology on Azure](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Private Endpoint overview](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)
- [Azure Private DNS zones](https://learn.microsoft.com/azure/dns/private-dns-overview)
- [Azure Firewall overview](https://learn.microsoft.com/azure/firewall/overview)
- [Azure Virtual Network limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-resource-manager-virtual-networking-limits)
- [Network security groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [User-defined routes overview](https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
