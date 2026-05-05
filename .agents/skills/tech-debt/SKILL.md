---
name: tech-debt
description: Technical debt management frameworks, prioritization rubrics (RICE scoring), debt budgets, amortization tracking, and visualization templates
compatibility: "Works with VS Code, CLI, and Copilot Coding Agent. No external tools required."
metadata:
  category: "devex"
  keywords: "technical-debt, prioritization, RICE, budgeting, tracking, amortization"
  model-tier: "standard"
allowed-tools: "search/codebase"
---

# Technical Debt Management

## Debt Register Template

Centralize all debt in a single register to enable prioritization and tracking:

| ID | Category | Description | Effort (Story Points) | Impact (1-5) | Debt Score | Priority | Status | Sprint | Owner |
|----|----------|-------------|-----|--------|-------|----------|--------|--------|-------|
| TD-001 | Legacy Code | Refactor auth microservice (Node.js → TypeScript) | 8 | 4 | 32 | P1 | Backlog | TBD | @alice |
| TD-002 | Test Gap | Add integration tests for payment processor | 5 | 3 | 15 | P2 | In Progress | S12 | @bob |
| TD-003 | Dependency | Upgrade Express 4.x → 5.x | 3 | 2 | 6 | P3 | Backlog | TBD | @alice |
| TD-004 | Tech Stack | Replace custom logger with Winston | 2 | 1 | 2 | P4 | Backlog | TBD | @charlie |

### Debt Categories

| Category | Examples | Typical Impact |
|----------|----------|---|
| **Legacy Code** | Unmaintained modules, no tests, old patterns | High |
| **Test Gap** | Missing unit/integration tests | Medium |
| **Dependency** | Outdated libraries, security patches | Medium-High |
| **Tech Stack** | Wrong tool for job, repeated patterns | Low-Medium |
| **Documentation** | Missing runbooks, stale guides | Low |
| **Performance** | Slow queries, N+1 problems | Medium-High |

## RICE Prioritization Rubric

Score each debt item using RICE: **Reach × Impact × Confidence / Effort**

### Scoring Scale

**Reach** (How many users affected?)
- 1 = Affects <1% of users
- 2 = Affects 1-10% of users
- 3 = Affects 10-50% of users
- 4 = Affects 50-100% of users

**Impact** (Severity if not fixed?)
- 1 = Cosmetic / nice-to-have
- 2 = Minor inconvenience
- 3 = Moderate productivity loss
- 4 = Significant productivity loss
- 5 = Critical / complete blocker

**Confidence** (How sure are we about this score?)
- 0.5 = Wild guess
- 0.75 = Educated guess
- 1.0 = Data-backed, high confidence

**Effort** (Story points to fix)
- 1-3 = Quick win
- 4-8 = Medium effort
- 8+ = Large project

### Example Calculation

```
TD-001: Refactor auth microservice
  Reach: 4 (affects all users on login)
  Impact: 4 (significant productivity loss during issues)
  Confidence: 0.75 (good data on crash rates)
  Effort: 8 story points
  
  RICE Score = (4 × 4 × 0.75) / 8 = 12 / 8 = 1.5

TD-002: Add payment processor tests
  Reach: 3 (affects customers in US, not yet global)
  Impact: 5 (payment failures = critical)
  Confidence: 1.0 (0 tests means high risk)
  Effort: 5 story points
  
  RICE Score = (3 × 5 × 1.0) / 5 = 15 / 5 = 3.0  (Higher priority!)
```

## Debt Budget Framework

Allocate percentage of sprint capacity to debt vs. feature development:

### Budget by Team Maturity

| Maturity Level | Debt Allocation | Features | Maintenance |
|---|---|---|---|
| **Early Stage** (0-1 years) | 5-10% | 80-85% | 5-10% |
| **Growth** (1-3 years) | 15-20% | 70-75% | 5-10% |
| **Stable** (3+ years) | 20-30% | 60-70% | 5-10% |

### Budget Enforcement

Each sprint:
- Total capacity = 80 story points
- Debt allocation = 20% = 16 story points
- Feature allocation = remaining

```yaml
Sprint 12:
  Total Capacity: 80 SP
  Debt Bucket (20%): 16 SP
    - TD-001 (8 SP): Refactor auth
    - TD-002 (5 SP): Add tests
    - TD-004 (3 SP): Logger upgrade
  Feature Bucket (80%): 64 SP
    - Feature A (20 SP)
    - Feature B (30 SP)
    - Feature C (14 SP)
```

### Quarterly Planning

Review debt budget allocation each quarter:
- If debt backlog > debt capacity, increase allocation
- If debt backlog < debt capacity, shift to features
- Never allocate <10% debt (allows continuous maintenance)

## Amortization Tracking

Track how much debt is "paid down" each sprint:

```
Quarterly Review:
Quarter 2:
  - Debt capacity: 15% of sprints (5 sprints × 80 SP × 15% = 60 SP)
  - Debt completed: 62 SP (✓ Exceeded target)
    - TD-001: 8 SP ✓
    - TD-002: 5 SP ✓
    - TD-003: 3 SP ✓
    - TD-004: 2 SP ✓
    - TD-005: 44 SP ✓
  - Debt added: 28 SP (new items identified)
  - Net debt reduction: 62 - 28 = 34 SP
  
Quarter 3:
  - Target: Maintain quarterly amortization of 30+ SP
```

### Amortization Velocity Chart

```
Debt Paid Down (Story Points)
|
| ╱╲      ╱─────
| ╱  ╲    ╱
|╱    ╲__╱
└─────────────
  Q1 Q2 Q3 Q4

Target (dashed): 30 SP/quarter
Actual (solid):  Increasing trend = Debt under control
```

## Visualization Templates

### Debt Quadrant (Impact vs. Effort)

Prioritize quadrant by quadrant:

```
Impact
  │
5 │ ┌─────────────┐
  │ │  P1         │  Quick wins: High impact, low effort
4 │ │ TD-002✓     │  (Fix first)
  │ │ TD-001      │
3 │ │─────────────┼─────────┐
  │ │  P2         │ P3      │  Defer: Low impact, high effort
2 │ │ TD-003      │ TD-005  │
  │ │             │         │
1 │ └─────────────┴─────────┘
  │
  └─────────────────────────
    1   3   5   8   12+  (Effort)
```

### Debt Burndown (Quarterly)

```
Debt (Story Points)
│
│     Start: 200 SP
│      ╱─────────
200 │ ╱╱╱╱╱╱╱ Actual
│ ╱    ╱╱╱╱╱╱╱
│     ╱  Target (linear)
150 │   ╱╱╱╱╱
│  ╱╱╱╱╱
100 │ ╱╱╱╱╱
│
│
  └──────────────
  W1 W2 W3 W4 W5 W6 W7 W8 W9 W10 W11 W12 W13
```

## Governance Rules

### When to Add Debt

- Adding debt is a **conscious choice**, not an accident
- Must be approved by tech lead
- Must include remediation plan
- Must have target sprint for payoff
- Examples:
  - "Use quick prototype to validate user demand, refactor in Sprint 5"
  - "Skip tests for v1 MVP, add tests before production"

### When to Pay Debt

- Dedicate 15-20% of sprint capacity
- Prioritize by RICE score
- Never let debt backlog exceed 6 months of capacity
- Include debt in sprint planning (don't leave to the end)

### Debt Policies

- **No legacy code without tests** (pay down immediately)
- **No major version upgrades skipped** (security risk)
- **No new features on top of P1 debt** (instability)

## Debt Register Spreadsheet Template

Use this Google Sheets template to track debt:

```
Columns:
- A: ID (TD-001, TD-002, ...)
- B: Category (Legacy Code, Test Gap, ...)
- C: Description
- D: Effort (story points)
- E: Impact (1-5)
- F: Debt Score (Impact × Effort)
- G: RICE Score (Reach × Impact × Confidence / Effort)
- H: Priority (P0-P4)
- I: Status (Backlog, In Progress, Done)
- J: Sprint (S12, S13, ...)
- K: Owner (name)
- L: Payoff Timeline (Sprint X)
```

Sample: [Google Sheets Template](https://docs.google.com/spreadsheets/d/XXXXX)

## Quarterly Review Checklist

- [ ] Calculate debt-paid-down vs. debt-added
- [ ] Verify debt budget was allocated and spent
- [ ] Review top 10 items by RICE score
- [ ] Identify items that shifted priorities
- [ ] Adjust debt budget for next quarter
- [ ] Communicate debt status to leadership
- [ ] Celebrate completed debt items

## Related

- RICE Prioritization: https://www.reforge.com/RICE
- Technical Debt Quadrant: Martin Fowler's TDQ
- Related agent: `sprint-planner` (for sprint scheduling)
