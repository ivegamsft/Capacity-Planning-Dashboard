---
name: e2e-testing
title: E2E Testing - Playwright, Cypress, and Cross-Browser Patterns
description: Production E2E testing patterns with Playwright and Cypress, flakiness prevention, cross-browser matrices, accessibility testing, and CI/CD integration
compatibility: ["agent:e2e-test-strategy", "agent:contract-testing"]
metadata:
  domain: testing
  maturity: production
  audience: [qa-engineer, developer, test-automation-engineer]
allowed-tools: [bash, node, python, docker]
---

# E2E Testing Skill

Comprehensive patterns for building reliable, maintainable end-to-end test suites using modern testing frameworks.

## Playwright E2E Setup

### Installation & Configuration

```bash
npm install -D @playwright/test

# Generate configuration
npx playwright init

# Install browsers
npx playwright install
```

### playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory
  testDir: './tests/e2e',
  testMatch: '**/*.spec.ts',
  
  // Concurrent execution
  workers: 4,  // Run 4 tests in parallel
  
  // Timeouts
  timeout: 30 * 1000,  // 30 seconds per test
  expect: { timeout: 5 * 1000 },  // 5 seconds for assertions
  
  // Reporter
  reporter: [
    ['list'],  // Console output
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'test-results.json' }],
  ],
  
  // Shared settings for all the projects
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',  // Capture trace on retry
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  
  // Configure browsers
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    
    // Mobile
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  
  // Web server
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## Playwright Test Patterns

### Basic Test Structure

```typescript
import { test, expect } from '@playwright/test';

test('checkout flow', async ({ page }) => {
  // Arrange: Navigate to page
  await page.goto('/');
  
  // Act: Perform user actions
  await page.locator('[data-testid="search-input"]').fill('Blue Widget');
  await page.locator('button:has-text("Search")').click();
  
  // Assert: Verify expected outcome
  await expect(page.locator('text=Blue Widget')).toBeVisible();
});
```

### Smart Waits (No Magic Sleeps)

```typescript
// ❌ WRONG: Hardcoded sleep
await page.click('button');
await new Promise(r => setTimeout(r, 2000));
const text = await page.textContent('h1');

// ✅ RIGHT: Smart waits
await page.click('button');
await page.waitForSelector('h1:has-text("Loaded")');
const text = await page.textContent('h1');

// ✅ ALSO RIGHT: waitForFunction with custom logic
await page.waitForFunction(() => {
  const button = document.querySelector('button[data-loaded="true"]');
  return button !== null;
});
```

### Locator Selection (Robustness Order)

```typescript
// 1. Best: Test ID (most robust)
page.locator('[data-testid="submit-btn"]')

// 2. Good: Role (semantic, accessible)
page.locator('button:has-text("Submit")')
page.locator('role=button[name="Submit"]')

// 3. Okay: Text selector
page.locator('text="Submit"')

// ❌ AVOID: XPath or CSS nesting
page.locator('//div/div/button[3]')  // Fragile!
page.locator('div.container > div:nth-child(3) > button')  // Fragile!
```

### Data Fixtures & Setup

```typescript
import { test as base } from '@playwright/test';

type TestFixtures = {
  authenticatedPage: Page;
  testUser: { email: string; password: string };
};

export const test = base.extend<TestFixtures>({
  authenticatedPage: async ({ page }, use) => {
    // Setup: Navigate and authenticate
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'test-password');
    await page.click('button:has-text("Login")');
    await page.waitForNavigation();
    
    // Use authenticated page in test
    await use(page);
    
    // Cleanup: Logout if needed
    await page.click('button:has-text("Logout")');
  },
  
  testUser: [
    { email: 'test@example.com', password: 'test-password' },
  ],
});

// Use fixture in test
test('checkout with authenticated user', async ({ authenticatedPage, testUser }) => {
  await authenticatedPage.goto('/checkout');
  // Test continues with authenticated state
});
```

### API Mocking & Stubbing

```typescript
test('show error when API fails', async ({ page }) => {
  // Mock API endpoint
  await page.route('**/api/users/**', (route) => {
    route.abort('failed');  // Simulate network error
  });
  
  await page.goto('/users');
  await expect(page.locator('text=Error loading users')).toBeVisible();
});

test('intercept and modify API response', async ({ page }) => {
  // Intercept and modify response
  await page.route('**/api/products', (route) => {
    route.continue({
      response: {
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 1, name: 'Test Product', price: 9.99 }
        ]),
      },
    });
  });
  
  await page.goto('/products');
  await expect(page.locator('text=Test Product')).toBeVisible();
});
```

### Accessibility Testing

```typescript
import { test, expect } from '@playwright/test';
import { injectAxe, checkA11y } from 'axe-playwright';

test('page is accessible', async ({ page }) => {
  await page.goto('/');
  
  // Inject axe accessibility engine
  await injectAxe(page);
  
  // Check accessibility violations
  await checkA11y(page);
});

test('keyboard navigation works', async ({ page }) => {
  await page.goto('/checkout');
  
  // Tab through form fields
  await page.press('Tab');  // Focus shipping field
  await expect(page.locator('[name="address"]')).toBeFocused();
  
  await page.press('Tab');  // Focus city field
  await expect(page.locator('[name="city"]')).toBeFocused();
  
  // Enter key should submit
  await page.press('Enter');
  await expect(page.locator('text=Order confirmed')).toBeVisible();
});
```

### Performance Testing

```typescript
test('page loads within Core Web Vitals targets', async ({ page }) => {
  const navigationTiming = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0];
    return {
      fcp: nav.responseEnd,  // First Contentful Paint
      lcp: nav.domInteractive,  // Largest Contentful Paint
      cls: 0,  // Cumulative Layout Shift
    };
  });
  
  // LCP should be < 2.5 seconds
  expect(navigationTiming.lcp).toBeLessThan(2500);
});
```

## Cypress Patterns

### Installation & Configuration

```bash
npm install -D cypress

# Generate config
npx cypress open
```

### cypress.config.js

```javascript
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.js',
    supportFile: 'cypress/support/e2e.js',
    
    // Timeouts
    defaultCommandTimeout: 5000,
    requestTimeout: 5000,
    responseTimeout: 10000,
    
    // Viewport
    viewportWidth: 1280,
    viewportHeight: 720,
    
    // Screenshots & Videos
    screenshotOnRunFailure: true,
    video: true,
  },
});
```

### Cypress Test Example

```javascript
describe('Checkout flow', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.login('test@example.com', 'password');  // Custom command
  });

  it('should complete purchase', () => {
    // Search for product
    cy.get('[data-testid="search"]').type('Blue Widget');
    cy.get('button:contains("Search")').click();
    
    // Wait for product to appear (no magic sleep!)
    cy.contains('Blue Widget').should('be.visible');
    
    // Add to cart
    cy.get('[data-testid="add-to-cart"]').click();
    
    // Verify cart updated
    cy.get('[data-testid="cart-count"]').should('contain', '1');
    
    // Checkout
    cy.visit('/checkout');
    cy.get('[name="address"]').type('123 Main St');
    cy.get('[name="city"]').type('Springfield');
    cy.get('[name="zip"]').type('12345');
    cy.get('button:contains("Continue")').click();
    
    // Verify order confirmation
    cy.contains('Order Confirmed').should('be.visible');
  });
});
```

### Cypress Custom Commands

```javascript
// cypress/support/commands.js
Cypress.Commands.add('login', (email, password) => {
  cy.visit('/login');
  cy.get('[name="email"]').type(email);
  cy.get('[name="password"]').type(password);
  cy.get('button:contains("Login")').click();
  cy.url().should('not.include', '/login');
});

Cypress.Commands.add('logout', () => {
  cy.get('[data-testid="logout-btn"]').click();
  cy.url().should('include', '/login');
});

// Usage in tests
cy.login('test@example.com', 'password');
cy.logout();
```

## Flakiness Prevention Checklist

```yaml
Flakiness Prevention:

1. Eliminate Magic Sleeps:
   ❌ cy.wait(2000)
   ✅ cy.contains('Loaded').should('be.visible')
   
2. Use Smart Waits:
   ✅ cy.waitForFunction()
   ✅ cy.intercept() for API mocking
   ✅ cy.get().should('have.length', 5)
   
3. Isolate Tests (Fresh Fixtures):
   ✅ beforeEach: Setup fresh state
   ❌ Tests that depend on previous test order
   
4. Fix Brittle Locators:
   ❌ cy.get('div.container > div:nth-child(3) > button')
   ✅ cy.get('[data-testid="submit-btn"]')
   
5. Mock External Dependencies:
   ✅ cy.intercept('/api/**', { fixture: 'users.json' })
   ❌ Tests that hit real external APIs
   
6. Use Retry Logic:
   ✅ Playwright/Cypress retry failed tests
   ✅ Exponential backoff for API calls
   
7. Deterministic Environments:
   ✅ Use Docker for consistent test environment
   ✅ Reset database state per test
   ❌ Tests that depend on current date/time
```

## Cross-Browser CI/CD Matrix

### GitHub Actions Workflow

```yaml
name: E2E Tests

on: [pull_request, push]

jobs:
  smoke-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        browser: [chromium]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      
      - run: npm ci
      - run: npx playwright install
      - run: npm run test:e2e -- --project=${{ matrix.browser }}
      
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report-${{ matrix.browser }}
          path: playwright-report/

  full-matrix:
    runs-on: ${{ matrix.os }}
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        browser: [chromium, firefox, webkit]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      
      - run: npm ci
      - run: npx playwright install
      - run: npx playwright test --project=${{ matrix.browser }}
      
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report-${{ matrix.os }}-${{ matrix.browser }}
          path: playwright-report/
```

## Test Data Management

### Avoid Test Database Dependencies

```typescript
// ❌ WRONG: Depends on seed data in database
test('find user by email', async ({ page }) => {
  await page.goto('/users');
  await page.fill('[name="search"]', 'test@example.com');
  // Assumes this email exists in DB
  await expect(page.locator('text=test@example.com')).toBeVisible();
});

// ✅ RIGHT: Create test data in test
test('find user by email', async ({ page, request }) => {
  // Setup: Create test user via API
  const user = await request.post('/api/users', {
    data: { email: 'test@example.com', name: 'Test User' }
  });
  
  // Act
  await page.goto('/users');
  await page.fill('[name="search"]', 'test@example.com');
  
  // Assert
  await expect(page.locator('text=test@example.com')).toBeVisible();
  
  // Cleanup: Delete test user
  await request.delete(`/api/users/${user.id}`);
});
```

## Performance Baselines

Track Core Web Vitals over time:

```typescript
test('measure Core Web Vitals', async ({ page }) => {
  const vitals = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0];
    const paint = performance.getEntriesByType('paint');
    const largest = performance.getEntriesByType('largest-contentful-paint').pop();
    
    return {
      fcp: paint.find(p => p.name === 'first-contentful-paint')?.startTime || 0,
      lcp: largest?.startTime || 0,
      fid: 0,  // Would use PerformanceObserver for FID
      cls: 0,  // CLS calculation is complex
    };
  });
  
  console.log('Core Web Vitals:', vitals);
  
  // Assert performance targets
  expect(vitals.fcp).toBeLessThan(1800);  // FCP < 1.8s
  expect(vitals.lcp).toBeLessThan(2500);  // LCP < 2.5s
});
```

## Maintenance

### Test Suite Health Monitoring

- **Pass Rate:** Target 99%+ (investigate any below 95%)
- **Flaky Tests:** Track and remediate (dedicate 10% sprint capacity)
- **Execution Time:** Target < 5 minutes for smoke tests, < 30 minutes for full suite
- **Maintenance Cost:** Tests should cost less than 50% of feature development time

### Quarterly Audit Checklist

- [ ] Remove obsolete tests (features removed, workflows changed)
- [ ] Update locators if UI changed
- [ ] Verify cross-browser compatibility (newer browser versions)
- [ ] Performance baselines still relevant?
- [ ] Accessibility checks passing on latest WCAG?
- [ ] Test data fixtures still valid?
- [ ] CI/CD timeout values appropriate?
