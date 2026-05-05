---

name: github-security-posture
description: "Audit GitHub org and repo security settings with traffic-light scoring and remediation guidance. Covers code security configs, rulesets, secret scanning, push protection, Dependabot alerts, branch protection, and CODEOWNERS."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# GitHub Security Posture Skill

Use this skill when the task involves auditing GitHub organization or repository security configurations, triaging security alerts, or producing a structured posture report with remediation guidance.

## When to Use

- Auditing GitHub org-level code security configurations
- Checking repository rulesets and branch protection rules
- Verifying secret scanning and push protection status
- Triaging open Dependabot or code scanning alerts
- Producing a traffic-light posture report for a security review
- Generating remediation commands for failing security checks

## How to Invoke

Reference this skill by attaching `skills/github-security-posture/SKILL.md` to your agent context, or instruct the agent:

> Use the github-security-posture skill. Run all org-level and repo-level checks, score each finding with the traffic-light rubric, and produce the posture report.

## Org-Level Checks

| # | Check | API Endpoint | Pass Condition | Risk if Failing |
|---|---|---|---|---|
| O1 | Code security configuration applied | `GET /orgs/{org}/code-security/configurations` | At least one configuration applied to repositories | Inconsistent security baseline across repos |
| O2 | Org rulesets defined | `GET /orgs/{org}/rulesets` | At least one active ruleset | Branch policies bypass risk |
| O3 | Secret scanning enabled at org level | Configuration → `secret_scanning: enabled` | Field is `enabled` | Secrets committed without detection |
| O4 | Dependabot security updates enabled | Configuration → `dependabot_security_updates: enabled` | Field is `enabled` | Vulnerable dependencies remain unpatched |

## Repo-Level Checks

| # | Check | API Endpoint | Pass Condition | Risk if Failing |
|---|---|---|---|---|
| R1 | Branch protection on default branch | `GET /repos/{owner}/{repo}/branches/{branch}/protection` | Rule exists with PR reviews and status checks | Direct pushes, force pushes, no approval gate |
| R2 | Repo ruleset active | `GET /repos/{owner}/{repo}/rulesets` | At least one active ruleset | Policy bypass via ruleset gaps |
| R3 | Secret scanning enabled | `GET /repos/{owner}/{repo}` → `security_and_analysis.secret_scanning.status` | `enabled` | Committed secrets undetected |
| R4 | Push protection enabled | `GET /repos/{owner}/{repo}` → `security_and_analysis.secret_scanning_push_protection.status` | `enabled` | Secrets pushed before detection |
| R5 | Code scanning configured | `GET /repos/{owner}/{repo}/code-scanning/alerts` | No 404 (tool configured); zero open critical/high alerts | Undetected code vulnerabilities |
| R6 | Dependabot alerts triaged | `GET /repos/{owner}/{repo}/dependabot/alerts?state=open&severity=critical,high` | Zero open critical or high alerts | Exploitable vulnerable dependencies |
| R7 | Signed commits required | Branch protection `required_signatures.enabled` | `true` | Commit author spoofing risk |
| R8 | CODEOWNERS file present | `CODEOWNERS`, `.github/CODEOWNERS`, or `docs/CODEOWNERS` exists | File found | Unowned code with no review ownership |

## API Quick Reference

```bash
# --- Authentication ---
gh auth status                                    # Verify active session and scopes

# --- Org-level ---
gh api /orgs/{org}/code-security/configurations   # Code security configs
gh api /orgs/{org}/rulesets                       # Org rulesets

# --- Repo-level ---
DEFAULT=$(gh api /repos/{owner}/{repo} --jq '.default_branch')

gh api /repos/{owner}/{repo}/branches/$DEFAULT/protection   # Branch protection
gh api /repos/{owner}/{repo}/rulesets                       # Repo rulesets
gh api /repos/{owner}/{repo} --jq '.security_and_analysis'  # Secret scanning status

gh api "/repos/{owner}/{repo}/code-scanning/alerts?state=open&per_page=100"
gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&severity=critical,high&per_page=100"

gh api /repos/{owner}/{repo}/branches/$DEFAULT/protection/required_signatures  # Signed commits

# CODEOWNERS presence check
gh api /repos/{owner}/{repo}/contents/.github/CODEOWNERS 2>/dev/null \
  || gh api /repos/{owner}/{repo}/contents/CODEOWNERS 2>/dev/null \
  || gh api /repos/{owner}/{repo}/contents/docs/CODEOWNERS 2>/dev/null
```

## Scoring Rubric

| Rating | Symbol | Criteria |
|---|---|---|
| Pass | 🟢 | Setting is enabled and fully configured as required |
| Warning | 🟡 | Partially configured, deprecated method used, or medium-severity open alerts |
| Fail | 🔴 | Setting disabled, absent, or critical/high open alerts present |

Overall posture score:

- **🟢 Green** — All checks are 🟢 Pass
- **🟡 Yellow** — No 🔴 Fail checks; one or more 🟡 Warning
- **🔴 Red** — One or more 🔴 Fail checks

## Templates in This Skill

| Template | Purpose |
|---|---|
| `posture-report-template.md` | Traffic-light posture report with org checks, repo checks, summary scorecard, and remediation commands |

## Agent Pairing

This skill is designed to be used alongside the `github-security-posture` agent. The agent drives the audit workflow; this skill provides the reference checks, API patterns, and report template.

For broader code-level security analysis, pair with the `security-analyst` agent and `security` skill.

## Conventions

- The folder name matches the `name` field in frontmatter.
- `SKILL.md` is the entry point for this skill.
- Requires standard GitHub token scopes: `repo`, `read:org`. No admin token required.
- Discovery keywords: org security, repo rulesets, secret scanning, Dependabot, branch protection, code scanning, push protection, CODEOWNERS, posture audit, GitHub security.
