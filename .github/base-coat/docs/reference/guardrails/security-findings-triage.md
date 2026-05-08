# Security Findings Triage

> **Rule:** Triage every security finding within 24 hours of detection. Assign an SLA based on severity and track remediation to completion.

## Severity Definitions and SLAs

| Severity | Description | SLA to Remediate | Example |
|----------|-------------|------------------|---------|
| **Critical** | Actively exploitable, public-facing, no mitigating controls | 24 hours | RCE in production dependency, leaked secret |
| **High** | Exploitable with moderate complexity or limited blast radius | 7 days | SQL injection behind auth, privilege escalation |
| **Medium** | Requires specific conditions or has partial mitigation in place | 30 days | XSS in internal tool, outdated TLS configuration |
| **Low** | Informational or defense-in-depth improvement | 90 days | Missing security header on non-sensitive endpoint |

SLA clock starts at detection time (alert creation), not when a human first views it.

## Ownership and Responsibility

| Role | Responsibility |
|------|---------------|
| **CODEOWNERS** | Primary remediation owner for findings in their area |
| **Security rotation** | Daily triage of new findings; assigns severity and owner |
| **Copilot agent** | May auto-remediate Low/Medium findings with passing CI |
| **Engineering manager** | Escalation point when SLA is at risk of breach |

## Merge-Blocking vs Tech Debt

### Block the merge when

- Finding is Critical or High severity
- Finding introduces a new vulnerability not present on the base branch
- Dependency has a known exploit in the wild (CISA KEV catalog)

### Track as tech debt when

- Finding is Medium or Low severity on pre-existing code
- Remediation requires a broader refactor beyond the PR scope
- A compensating control already mitigates the risk

Tech debt items must be filed as issues with the `security-debt` label and assigned an owner before the PR merges.

## Handling False Positives and Exceptions

1. **Verify** — Confirm the finding is not exploitable in context
2. **Document** — Add a comment explaining why it is a false positive
3. **Suppress** — Use the tool-specific suppression mechanism (inline annotation, `.sarif` suppression, or alert dismissal)
4. **Review** — False positive suppressions require approval from a CODEOWNER or security rotation member

Exceptions (accepted risk) follow the same flow but require engineering manager sign-off and a scheduled re-evaluation date (max 90 days).

## Dependabot Alert Dismissal Policy

Dependabot alerts must not be dismissed without:

- A documented reason (one of: `fix_started`, `inaccurate`, `no_bandwidth`, `not_used`, `tolerable_risk`)
- Approval from a CODEOWNER or security rotation member
- An associated issue when reason is `no_bandwidth` or `tolerable_risk`

Alerts dismissed as `inaccurate` must include evidence (e.g., proof the vulnerable code path is unreachable).

## Decision Tree

```text
New finding detected
│
├─ Is it a false positive?
│  ├─ Yes → Document reason → Get CODEOWNER approval → Suppress
│  └─ No ↓
│
├─ Assign severity (Critical / High / Medium / Low)
│
├─ Is it Critical or High?
│  ├─ Yes → Block merge → Assign to CODEOWNER → Remediate within SLA
│  └─ No ↓
│
├─ Is it in new code (introduced by this PR)?
│  ├─ Yes → Request changes on PR → Author remediates before merge
│  └─ No ↓
│
├─ File issue with `security-debt` label
├─ Assign owner and SLA deadline
└─ Track in security debt backlog
```

## Quick Reference

| Decision | Recommendation |
|----------|---------------|
| Triage timeline | Within 24 hours of detection |
| Block merge? | Critical/High or new-in-PR findings |
| False positive? | Document + CODEOWNER approval to suppress |
| Dismiss Dependabot alert? | Requires reason + approval + issue if deferred |
| SLA breach? | Escalate to engineering manager |
