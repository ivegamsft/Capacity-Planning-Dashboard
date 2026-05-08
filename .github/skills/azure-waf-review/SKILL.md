---

name: azure-waf-review
description: "Use when performing an Azure Well-Architected Framework (WAF) assessment against a workload, IaC templates, or architecture description. Covers all five pillars: Reliability, Security, Cost Optimization, Operational Excellence, and Performance Efficiency. Produces scored assessments, prioritized findings, and Bicep/Terraform remediation snippets."
context: fork
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure Well-Architected Framework Review Skill

Use this skill when the task involves assessing an Azure workload against the five pillars of the Well-Architected Framework, generating a scored findings report, and producing prioritized remediation guidance with IaC templates.

## When to Use

- Evaluating a workload description, architecture diagram, or IaC templates against WAF pillars
- Generating a structured WAF assessment report with per-pillar scores
- Prioritizing architectural improvements by impact and implementation effort
- Producing Bicep or Terraform remediation snippets for identified gaps
- Conducting a pre-production architecture review for Azure-hosted workloads
- Preparing for an official Azure Architecture Review or advisory engagement

## How to Invoke

Reference this skill by attaching `skills/azure-waf-review/SKILL.md` to your agent context, or instruct the agent:

> Use the azure-waf-review skill. Accept the IaC templates below, assess them against all five WAF pillars, score each pillar, and produce a remediation action plan with Bicep snippets.

## Workflow

1. **Gather input** — Accept workload description, architecture diagrams, or IaC templates (Bicep, Terraform, ARM).
2. **Evaluate per pillar** — Assess the workload against each of the five WAF pillars using the scoring rubric in `pillar-scoring-rubric.md`.
3. **Score findings** — Assign a 1–5 score per pillar; flag individual findings with severity (Critical / High / Medium / Low).
4. **Prioritize** — Rank findings by a combined impact × effort matrix; surface quick wins first.
5. **Generate report** — Populate the `waf-assessment-report-template.md` with findings, scores, and executive summary.
6. **Produce remediation templates** — Emit Bicep or Terraform snippets for each high/critical finding using the `remediation-action-plan-template.md`.
7. **Review and hand off** — Summarize open risks and recommended next steps; link to relevant Azure documentation.

## WAF Pillars Covered

| Pillar | Key Concerns |
|---|---|
| **Reliability** | High availability, disaster recovery, fault tolerance, health probes, retry policies |
| **Security** | Zero trust, encryption at rest and in transit, managed identity, Key Vault, network segmentation |
| **Cost Optimization** | Right-sizing, reserved instances, spot/preemptible workloads, idle resource cleanup, cost alerts |
| **Operational Excellence** | Infrastructure as Code, monitoring, alerting, automated deployments, runbooks |
| **Performance Efficiency** | Auto-scaling, caching strategies, CDN, database indexing, connection pooling |

## Templates in This Skill

| Template | Purpose |
|---|---|
| `waf-assessment-report-template.md` | Full WAF assessment report with per-pillar scores, findings table, and executive summary |
| `pillar-scoring-rubric.md` | Scoring rubric (1–5) for each WAF pillar with pass/fail criteria and evidence prompts |
| `remediation-action-plan-template.md` | Prioritized action plan with Bicep and Terraform remediation snippets |

## Guardrails

- Scope assessments to Azure workloads only; do not apply WAF pillars to non-Azure targets.
- Do not emit secrets, connection strings, or credentials in any generated IaC snippet.
- Always cite the relevant WAF documentation URL for each finding.
- If the workload input is ambiguous, ask clarifying questions before scoring.
- Scores are advisory; always recommend a human architecture review for critical workloads.

## Agent Pairing

This skill is designed to be used alongside the `solution-architect` agent for full architecture assessments. Pair with the `security-analyst` agent for deep-dive security pillar analysis, and the `devops-engineer` agent for Operational Excellence remediation.

For IaC remediation, the `devops-engineer` agent can apply generated Bicep/Terraform snippets. For cost workload analysis, pair with the `product-manager` agent to align optimization priorities with business goals.

## References

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [WAF Assessment Tool](https://learn.microsoft.com/assessments/azure-architecture-review/)
- [Reliability pillar](https://learn.microsoft.com/azure/well-architected/reliability/)
- [Security pillar](https://learn.microsoft.com/azure/well-architected/security/)
- [Cost Optimization pillar](https://learn.microsoft.com/azure/well-architected/cost-optimization/)
- [Operational Excellence pillar](https://learn.microsoft.com/azure/well-architected/operational-excellence/)
- [Performance Efficiency pillar](https://learn.microsoft.com/azure/well-architected/performance-efficiency/)
