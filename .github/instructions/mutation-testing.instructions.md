---
description: >
  Mutation testing standards — use when verifying test quality. Mutation testing checks whether existing tests
  actually catch bugs (don't just pass silently on bad code). Covers test effectiveness measurement,
  mutation score interpretation, and actionable mutation fix strategies.
applyTo: agents/contract-testing.agent.md, agents/e2e-test-strategy.agent.md, instructions/testing.instructions.md
---

# Mutation Testing Standards

## When to Apply

**Mutation testing answers:** "Do my tests actually detect bugs, or just pass silently while code breaks?"

Use this instruction when:

- A test suite has high line coverage (80%+) but you want to verify it catches real bugs
- Validating critical system behavior that must not regress
- Hardening a test suite before releasing to production
- Investigating false confidence from tests (low failure rate, but bugs slipping through)
- Measuring test effectiveness across teams or projects

**Key insight:** Line coverage (80% passing tests) is a poor proxy for test quality. A test that executes a line of code but never asserts on the result is worthless. Mutation testing exposes this gap.

## How Mutation Testing Works

### 1. Generate Mutations

The mutation tester introduces deliberate bugs into your code:

```python
# Original code
def calculate_discount(price, customer_type):
    if customer_type == 'premium':
        return price * 0.9  # 10% discount
    return price

# Mutation 1: Change operator (* to +)
def calculate_discount(price, customer_type):
    if customer_type == 'premium':
        return price + 0.9  # BUG: adds instead of multiplies
    return price

# Mutation 2: Delete condition
def calculate_discount(price, customer_type):
    # if customer_type == 'premium':  # BUG: condition deleted
    return price * 0.9  # Always applies discount
    # return price
```

### 2. Run Tests Against Mutations

For each mutation, run the full test suite. If tests still pass, the mutation **survived** (bad test quality). If tests fail, the mutation was **killed** (good test quality).

### 3. Calculate Mutation Score

```
Mutation Score = (Killed Mutations / Total Mutations) × 100

Example:
  Total mutations generated: 100
  Killed mutations (tests caught): 75
  Survived mutations (tests missed): 25
  Mutation Score: 75%
  
Target: > 80% mutation score (higher is better, but diminishing returns > 90%)
```

## Mutation Testing Tools

### Python: Mutmut

```bash
# Install
pip install mutmut pytest

# Run mutation testing
mutmut run --paths-to-mutate src/

# Generate report
mutmut results

# Show HTML report
mutmut html
```

**mutmut configuration** (setup.cfg):

```ini
[mutmut]
paths_to_mutate = src/
tests_dir = tests/
mutants_per_file = 8  # Limit mutations per file for performance
```

### JavaScript/TypeScript: Stryker

```bash
# Install
npm install -D @stryker-mutator/core @stryker-mutator/jest-runner

# Initialize
npx stryker init

# Run mutation testing
npx stryker run

# Generate report
# Automatically creates HTML report in reports/
```

**stryker.conf.json:**

```json
{
  "testRunner": "jest",
  "jest": {
    "projectType": "custom"
  },
  "mutate": [
    "src/**/*.ts",
    "!src/**/*.spec.ts",
    "!src/**/*.test.ts"
  ],
  "reporters": ["html", "json"],
  "concurrency": 4,
  "mutationThreshold": {
    "high": 80,
    "medium": 70,
    "low": 60
  }
}
```

### Java: PIT

```bash
# Maven plugin
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>1.14.0</version>
  <configuration>
    <targetClasses>
      <param>com.example.calculator*</param>
    </targetClasses>
    <targetTests>
      <param>com.example.calculator*Test</param>
    </targetTests>
  </configuration>
</plugin>

# Run
mvn org.pitest:pitest-maven:mutationCoverage
```

## Interpreting Mutation Reports

### High Mutation Score (> 85%)

✅ **Good test quality** — tests catch most bugs.

```yaml
Example:
  Mutation Score: 88%
  Killed: 88 mutations
  Survived: 12 mutations
  Status: Production-ready
```

**Action:** No immediate action needed. Consider these survived mutations acceptable edge cases or harmless rewrites.

### Acceptable Mutation Score (70-85%)

⚠️ **Borderline** — acceptable for most systems, but room for improvement.

```yaml
Example:
  Mutation Score: 76%
  Killed: 76 mutations
  Survived: 24 mutations
  Status: Acceptable, plan improvements
```

**Action:** 
1. Investigate top 10 survived mutations (highest value bugs)
2. Add tests for these edge cases
3. Target 85%+ within next sprint

### Low Mutation Score (< 70%)

❌ **Poor test quality** — tests miss significant bugs.

```yaml
Example:
  Mutation Score: 52%
  Killed: 52 mutations
  Survived: 48 mutations
  Status: REMEDIATION REQUIRED
```

**Action:**
1. **Immediate:** Halt feature development, fix critical gaps
2. **Audit:** Review test quality (coverage % is misleading)
3. **Examples of survived mutations:**
   - Boundary conditions (off-by-one, < vs <=)
   - Error handling (exception paths untested)
   - Data validation (no assertions on invalid inputs)
4. **Add tests** for each survived mutation category
5. **Retest** until score reaches 80%+

## Common Survived Mutations & Fixes

### 1. Boundary Condition Mutations

```python
# Code
def is_valid_age(age):
    return age >= 18  # Boundary: 18

# Mutation: >= becomes >
def is_valid_age(age):
    return age > 18  # BUG: age 18 rejected

# Missing test
assert is_valid_age(18) == True  # ← This test catches the mutation

# Add boundary test
def test_is_valid_age_boundary():
    assert is_valid_age(17) == False
    assert is_valid_age(18) == True  # Catches >= vs > mutation
    assert is_valid_age(19) == True
```

### 2. Conditional Deletion Mutations

```python
# Code
def process_order(order, user):
    if not user.is_authenticated:
        raise Unauthorized()
    
    if order.total > 1000:
        require_approval = True
    else:
        require_approval = False
    
    return submit_order(order, require_approval)

# Mutation: Delete entire condition
def process_order(order, user):
    # if not user.is_authenticated:  ← BUG: condition deleted
    #     raise Unauthorized()
    
    require_approval = False  # Always False
    return submit_order(order, require_approval)

# Missing test
def test_large_orders_require_approval():
    user = User(authenticated=True)
    order = Order(total=5000)
    result = process_order(order, user)
    assert result.requires_approval == True  # Catches deletion
    
def test_unauthenticated_blocked():
    user = User(authenticated=False)
    order = Order(total=100)
    with pytest.raises(Unauthorized):
        process_order(order, user)  # Catches deletion
```

### 3. Operator Mutations

```python
# Code
def calculate_total(subtotal, tax_rate):
    return subtotal * (1 + tax_rate)

# Mutation: * becomes / or +
def calculate_total(subtotal, tax_rate):
    return subtotal / (1 + tax_rate)  # BUG: divide instead of multiply

# Missing test
def test_tax_calculation():
    # With tax_rate=0.1 and subtotal=100:
    # Expected: 100 * 1.1 = 110
    # Wrong code (/) returns: 100 / 1.1 ≈ 90.9
    result = calculate_total(100, 0.1)
    assert result == 110.0  # Catches * vs / mutation
```

### 4. Return Value Mutations

```python
# Code
def validate_email(email):
    if '@' not in email:
        return False
    if '.' not in email:
        return False
    return True

# Mutation: Return True instead of False
def validate_email(email):
    if '@' not in email:
        return True  # BUG: returns True instead of False
    if '.' not in email:
        return False
    return True

# Missing test
def test_validate_email_invalid():
    assert validate_email('invalid') == False  # Catches return mutation
    assert validate_email('no-at-sign.com') == False  # Catches second return
    assert validate_email('valid@example.com') == True
```

## Mutation Testing Strategy

### Phase 1: Baseline (1 sprint)

1. **Run mutation testing** on current test suite
2. **Record baseline** (e.g., 62% mutation score)
3. **Identify top 20** survived mutations (highest-value bugs)
4. **Create test cases** for each top 20

**Expected outcome:** 70-75% mutation score

### Phase 2: Close Critical Gaps (2-3 sprints)

1. **Analyze all survived mutations** by category
   - Boundary conditions: +20%
   - Error handling: +15%
   - Data validation: +10%
   - ...
2. **Add targeted tests** for each category
3. **Retest** after each batch

**Expected outcome:** 80-85% mutation score

### Phase 3: Hardening (ongoing)

1. **Monitor mutation score** on every commit
2. **Automatically fail CI** if mutation score drops
3. **Dedicate 5-10% of sprint** to mutation fixes
4. **Target: Maintain 85%+ permanently**

## CI/CD Integration

### Python (mutmut + GitHub Actions)

```yaml
name: Mutation Testing

on: [pull_request, push]

jobs:
  mutmut:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: 3.11
      
      - run: pip install mutmut pytest
      - run: mutmut run --paths-to-mutate src/
      - run: mutmut results --print-coverage
      
      # Fail if score drops below threshold
      - run: |
          SCORE=$(mutmut results --print-coverage | grep -oP '\d+(?=%)')
          if [ "$SCORE" -lt 80 ]; then
            echo "Mutation score too low: $SCORE%"
            exit 1
          fi
```

### JavaScript (Stryker + GitHub Actions)

```yaml
name: Mutation Testing

on: [pull_request, push]

jobs:
  stryker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      
      - run: npm ci
      - run: npm run test  # Run regular tests first
      - run: npx stryker run
      
      # Upload report
      - uses: actions/upload-artifact@v4
        with:
          name: stryker-report
          path: reports/
```

## Test Quality Checklist

Before considering a test suite production-ready:

- [ ] **Line coverage >= 80%** (minimum, not sufficient)
- [ ] **Mutation score >= 85%** (better proxy for quality)
- [ ] **All error paths tested** (exception handling, null checks)
- [ ] **Boundary conditions tested** (off-by-one, edge values)
- [ ] **Invalid inputs rejected** (validation tests)
- [ ] **Concurrent/async operations handled** (race conditions, timeouts)
- [ ] **Performance regression tests** (critical paths timed)
- [ ] **Integration tests** (dependencies validated)

## Common Mistakes

❌ **Mistake 1: High coverage, low mutation score**
- Tests exist but don't assert on results
- Fix: Add assertions that verify behavior, not just execution

❌ **Mistake 2: Ignoring mutation categories**
- Fixing random mutations without understanding patterns
- Fix: Group survived mutations by type, fix systematically

❌ **Mistake 3: Mutation score as silver bullet**
- Assuming 90% mutation score means production-ready
- Fix: Still need manual testing, security audits, performance validation

## References

- **Stryker Documentation:** https://stryker-mutator.io/
- **PIT (Java):** http://pitest.org/
- **Mutmut (Python):** https://mutmut.readthedocs.io/
- **Testing Strategies Paper:** "Are Your Tests Really Testing Your Code?" (Google Testing Blog)
