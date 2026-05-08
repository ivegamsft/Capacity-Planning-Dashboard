---

name: security
description: "Use when performing security audits, threat modeling, vulnerability assessments, or dependency reviews. Provides OWASP checklists, STRIDE templates, vulnerability report structures, and dependency audit formats."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Security Skill

Use this skill when the task involves auditing code for security vulnerabilities, modeling threats, reviewing dependencies for known CVEs, or enforcing secure coding standards.

## When to Use

- Performing an OWASP Top 10 review on an application
- Conducting STRIDE threat modeling for a new feature or architecture change
- Scanning for hardcoded secrets or credentials in source code
- Auditing dependency manifests for known vulnerabilities
- Documenting security findings in a structured vulnerability report
- Reviewing code for secure coding compliance

## How to Invoke

Reference this skill by attaching `skills/security/SKILL.md` to your agent context, or instruct the agent:

> Use the security skill. Apply the OWASP checklist and STRIDE threat model template to the modules being audited.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `owasp-checklist.md` | OWASP Top 10 evaluation checklist with pass/fail tracking per category |
| `stride-threat-model-template.md` | STRIDE threat modeling template for enumerating and rating threats per component |
| `vulnerability-report-template.md` | Structured vulnerability report for compiling all findings with severity ratings |
| `dependency-audit-template.md` | Dependency audit template for documenting CVEs, affected packages, and remediation |

## Agent Pairing

This skill is designed to be used alongside the `security-analyst` agent. The agent drives the audit workflow; this skill provides the reference templates and checklists.

For backend-specific security concerns, pair with the `backend-dev` agent's security defaults. For frontend-specific concerns (CSP, XSS, CORS), pair with the `frontend-dev` agent.

## Related Guardrails

- [Security Findings Triage](../../docs/guardrails/security-findings-triage.md) — SLA-based triage process for severity classification, ownership, and remediation tracking
