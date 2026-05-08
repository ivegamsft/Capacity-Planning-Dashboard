# Code Review Escalation

> **Rule:** Categorize every review finding by type. Escalate bugs and security issues to blocking issues; handle nits inline.

## Finding Categories

| Category | Severity | Action |
|----------|----------|--------|
| **Bug** | Blocking | Must be fixed before merge; file issue if complex |
| **Security** | Blocking | Must be fixed before merge; follow [security-findings-triage](security-findings-triage.md) |
| **Tech-debt** | Non-blocking | File issue for backlog; do not block the PR |
| **Nit** | Non-blocking | Inline comment only; author may address or decline |

## When to Create a Blocking Issue

Create a separate issue (rather than just an inline comment) when:

- The fix requires changes beyond the scope of the current PR
- The finding affects multiple files or components
- The finding requires input from someone not on the review
- Remediation has a defined SLA (security findings)
- The finding will otherwise be lost in a resolved conversation thread

## Issue Creation Template

When escalating a review finding to an issue, include:

```markdown
## Review Finding

**PR:** #<pr-number>
**File:** `<file-path>#L<line>`
**Category:** bug | security | tech-debt
**Severity:** critical | high | medium | low

## Description

<What the issue is and why it matters>

## Suggested Fix

<Proposed approach or constraints>

## Acceptance Criteria

- [ ] <Specific condition that proves the fix is complete>
- [ ] Tests cover the identified scenario
- [ ] No regression in existing behavior
```

## Assignment Strategy

| Situation | Assignee |
|-----------|----------|
| Bug in code the PR author wrote | PR author fixes before merge |
| Bug in pre-existing code touched by the PR | PR author or team backlog (author's choice) |
| Security finding (any severity) | CODEOWNER per [security-findings-triage](security-findings-triage.md) |
| Tech-debt in unrelated code | Team backlog; assign during sprint planning |
| Complex fix requiring design discussion | File issue → assign to tech lead for triage |

## Re-Review Requirements

After a reviewer requests changes, the following apply before merge:

| Change type | Re-review required? | Who re-reviews? |
|-------------|---------------------|-----------------|
| Bug fix (blocking) | Yes | Original reviewer who flagged it |
| Security fix | Yes | Original reviewer + CODEOWNER |
| Tech-debt addressed proactively | No | Author self-certifies |
| Nit addressed | No | No re-review needed |

### Re-review checklist

- [ ] The specific finding is resolved (not just worked around)
- [ ] No new issues introduced by the fix
- [ ] Tests added or updated to cover the scenario
- [ ] CI passes on the updated branch

## Escalation Path

```text
Finding identified in review
│
├─ Is it a nit?
│  ├─ Yes → Inline comment → Author decides → No block
│  └─ No ↓
│
├─ Is it a bug or security issue?
│  ├─ Yes → Request changes on PR
│  │        ├─ Fixable in this PR? → Author fixes → Re-review
│  │        └─ Too complex? → File blocking issue → Link in PR
│  └─ No ↓
│
├─ Is it tech-debt?
│  ├─ Yes → File non-blocking issue → Label `tech-debt`
│  └─ No → Discuss with team; re-categorize
```

## Quick Reference

| Decision | Recommendation |
|----------|---------------|
| Bug found? | Block PR; author fixes or issue filed |
| Security found? | Block PR; follow security triage SLAs |
| Tech-debt found? | File issue; don't block PR |
| Nit? | Inline comment; no block |
| Re-review needed? | Only for blocking findings |
| Issue template? | Use the standard template above |
