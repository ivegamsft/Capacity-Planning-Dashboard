---

name: devops
description: "Use when designing CI/CD pipelines, writing IaC templates, planning deployments, or setting up observability. Provides workflow templates, deployment checklists, rollback runbooks, and environment promotion guides."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# DevOps Skill

Use this skill when the task involves CI/CD pipeline design, infrastructure as code, deployment workflows, rollback planning, or observability configuration.

## When to Use

- Designing or modifying a GitHub Actions workflow
- Creating or reviewing infrastructure as code (Bicep, Terraform, or other)
- Planning a deployment to a new environment
- Documenting rollback procedures for a service
- Defining environment promotion gates and approval workflows
- Setting up monitoring, alerting, or health checks

## How to Invoke

Reference this skill by attaching `skills/devops/SKILL.md` to your agent context, or instruct the agent:

> Use the devops skill. Apply the GitHub Actions template, deployment checklist, and environment promotion template to the service being deployed.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `github-actions-template.md` | GitHub Actions workflow skeleton with build, test, scan, and deploy stages |
| `deployment-checklist.md` | Pre-deployment and post-deployment verification checklist |
| `rollback-runbook-template.md` | Step-by-step rollback runbook template with decision criteria |
| `environment-promotion-template.md` | Environment promotion path definition with gates and approval rules |

## Related Guardrails

| Guardrail | When to apply |
|---|---|
| [`runner-routing.md`](../../docs/guardrails/runner-routing.md) | Choosing self-hosted vs GitHub-hosted runners; routing patterns and fallback strategy |

## Agent Pairing

This skill is designed to be used alongside the `devops-engineer` agent. The agent drives the workflow; this skill provides the reference templates and standards.

For application-level concerns, coordinate with the `backend-dev` or `frontend-dev` agents. Route database migration questions to the `data-tier` agent.
