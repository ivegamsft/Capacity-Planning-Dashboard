---

name: manual-test-strategy
description: "Use when defining where human judgment is still required, how exploratory work is captured, and which repeated checks should graduate into automation. Provides templates for decision rubrics, exploratory charters, regression checklists, and defect evidence."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Manual Test Strategy

Use this skill when a feature, risk inventory, or change needs a structured decision about what stays manual, what gets automated next, and how evidence moves between both.

## When to Use

- A new feature or risk area lacks explicit manual testing scope.
- Exploratory coverage is informal or undocumented.
- A manual regression checklist needs to be made repeatable by a new team member.
- Automation candidates need to be captured and prioritized from manual work.
- A defect requires a structured evidence record for filing or future automation.

## How Agents Invoke This Skill

Agents should load the relevant template from this skill's directory before producing artifacts:

| Template | When to use |
| --- | --- |
| `rubric-template.md` | Classifying behaviors as manual-only, automate-now, or hybrid |
| `charter-template.md` | Structuring a time-boxed exploratory session |
| `checklist-template.md` | Building a repeatable manual regression checklist |
| `defect-template.md` | Capturing defect evidence for filing, triage, or automation handoff |

## Workflow

1. Inventory behaviors: list all behaviors that could be tested, noting change frequency, business risk, and existing scripted coverage.
2. Apply the rubric: classify each behavior using `rubric-template.md`.
3. Produce artifacts: charter, checklist, or both depending on what the rubric produces.
4. Capture evidence: use `defect-template.md` for any found defects.
5. Identify automation candidates: any hybrid or automate-now row that is not yet scripted becomes a backlog candidate.
6. File GitHub Issues for automation candidates using the `gh issue create` pattern defined in the relevant agent.

## Output Expectations

- Every behavior is classified; no implicit scope.
- Evidence is rich enough for a new team member to reproduce findings without tribal knowledge.
- Automation handoff is explicit: candidates are named, prioritized, and tracked as GitHub Issues.
- Artifacts remain stack-agnostic: no tooling-specific references in templates.
