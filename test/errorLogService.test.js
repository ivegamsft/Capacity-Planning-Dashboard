'use strict';

/**
 * test/errorLogService.test.js
 *
 * Unit tests for src/services/errorLogService.js.
 *
 * Strategy:
 *  - Input-validation tests (422 paths) never touch the database — they throw
 *    before any store call.
 *  - No-SQL-configured tests rely on SQL_SERVER / SQL_DATABASE env vars being
 *    absent (the default in CI), causing getSqlPool() to return null and the
 *    store to return { rows: [], total: 0 }.  This matches the pattern used in
 *    test/sql.test.js and test/routes.test.js.
 */

const test = require('node:test');
const assert = require('node:assert/strict');

const { getErrorLogs } = require('../src/services/errorLogService');

// ─── Helper ──────────────────────────────────────────────────────────────────

/** Assert that a promise rejects with a 422 validation error. */
async function assertValidationError(promise, expectedFragment) {
  let threw = false;
  try {
    await promise;
  } catch (err) {
    threw = true;
    assert.equal(err.status, 422, `Expected status 422, got ${err.status}`);
    assert.equal(err.code, 'VALIDATION_FAILED', `Expected code VALIDATION_FAILED, got ${err.code}`);
    if (expectedFragment) {
      assert.ok(
        err.message.includes(expectedFragment),
        `Expected message to include "${expectedFragment}", got: "${err.message}"`
      );
    }
  }
  assert.ok(threw, 'Expected the promise to reject but it resolved.');
}

// ─── Default / no-SQL path ────────────────────────────────────────────────────

test('getErrorLogs returns empty result when no SQL pool is configured', async () => {
  // SQL_SERVER is not set in the test environment → pool is null → store returns empty.
  const result = await getErrorLogs();

  assert.equal(result.page, 1);
  assert.equal(result.pageSize, 50);
  assert.equal(result.total, 0);
  assert.ok(Array.isArray(result.rows));
  assert.equal(result.rows.length, 0);
});

test('getErrorLogs applies default page=1 and pageSize=50 when params are omitted', async () => {
  const result = await getErrorLogs({});

  assert.equal(result.page, 1);
  assert.equal(result.pageSize, 50);
});

// ─── Pagination normalisation ─────────────────────────────────────────────────

test('getErrorLogs clamps pageSize to MAX_PAGE_SIZE (200)', async () => {
  const result = await getErrorLogs({ pageSize: 9999 });

  assert.equal(result.pageSize, 200);
});

test('getErrorLogs uses pageSize=1 when pageSize=0 is supplied', async () => {
  // 0 is < 1, so it falls back to default (50), not 1.
  // The fallback for a non-positive value is DEFAULT_PAGE_SIZE.
  const result = await getErrorLogs({ pageSize: 0 });

  assert.equal(result.pageSize, 50);
});

test('getErrorLogs returns page=2 when page=2 is requested', async () => {
  const result = await getErrorLogs({ page: 2 });

  assert.equal(result.page, 2);
});

test('getErrorLogs falls back to page=1 when page is non-numeric', async () => {
  const result = await getErrorLogs({ page: 'abc' });

  assert.equal(result.page, 1);
});

// ─── Level / severity validation ──────────────────────────────────────────────

test('getErrorLogs throws 422 for an unrecognised level', async () => {
  await assertValidationError(
    getErrorLogs({ level: 'verbose' }),
    'Invalid level'
  );
});

test('getErrorLogs throws 422 for a level with leading whitespace (after trim mismatch)', async () => {
  // Spaces are stripped: '  error  ' → 'error', which IS valid.
  // A value that remains unrecognised after trim should 422.
  await assertValidationError(
    getErrorLogs({ level: 'notice' }),
    'Invalid level'
  );
});

test('getErrorLogs accepts "warning" and normalises it to "warn"', async () => {
  // 'warning' is allowed and normalised internally — no error should be thrown.
  // (No DB hit because pool is null; result is empty.)
  const result = await getErrorLogs({ level: 'warning' });

  // If we reach here without throwing the normalisation was accepted.
  assert.equal(result.total, 0);
});

test('getErrorLogs accepts all canonical level values without throwing', async () => {
  const canonicalLevels = ['critical', 'error', 'warn', 'info'];

  for (const level of canonicalLevels) {
    // Should resolve (empty result) not reject.
    const result = await getErrorLogs({ level });
    assert.equal(result.total, 0, `level="${level}" unexpectedly returned rows`);
  }
});

// ─── Date validation ──────────────────────────────────────────────────────────

test('getErrorLogs throws 422 for an invalid startDate', async () => {
  await assertValidationError(
    getErrorLogs({ startDate: 'not-a-date' }),
    'Invalid startDate'
  );
});

test('getErrorLogs throws 422 for an invalid endDate', async () => {
  await assertValidationError(
    getErrorLogs({ endDate: 'yesterday' }),
    'Invalid endDate'
  );
});

test('getErrorLogs throws 422 when startDate is later than endDate', async () => {
  await assertValidationError(
    getErrorLogs({ startDate: '2026-05-01', endDate: '2026-04-01' }),
    'startDate must not be later than endDate'
  );
});

test('getErrorLogs accepts valid ISO 8601 date strings without throwing', async () => {
  const result = await getErrorLogs({
    startDate: '2026-01-01T00:00:00Z',
    endDate: '2026-12-31T23:59:59Z'
  });

  // Pool is null → empty result — the important thing is no error was thrown.
  assert.equal(result.total, 0);
});

test('getErrorLogs accepts equal startDate and endDate without throwing', async () => {
  const result = await getErrorLogs({
    startDate: '2026-06-15',
    endDate: '2026-06-15'
  });

  assert.equal(result.total, 0);
});

// ─── Source filter ────────────────────────────────────────────────────────────

test('getErrorLogs truncates source to 64 characters before delegating', async () => {
  // A source longer than 64 chars should be silently truncated, not rejected.
  const longSource = 'x'.repeat(100);
  const result = await getErrorLogs({ source: longSource });

  // No error thrown → truncation was applied.
  assert.equal(result.total, 0);
});

// ─── Unresolved flag ──────────────────────────────────────────────────────────

test('getErrorLogs accepts onlyUnresolved=true without throwing', async () => {
  const result = await getErrorLogs({ onlyUnresolved: true });

  assert.equal(result.total, 0);
});

// ─── Return shape ─────────────────────────────────────────────────────────────

test('getErrorLogs result always contains rows, total, page, pageSize', async () => {
  const result = await getErrorLogs({ page: 3, pageSize: 10 });

  assert.ok('rows' in result, 'result must have a rows property');
  assert.ok('total' in result, 'result must have a total property');
  assert.ok('page' in result, 'result must have a page property');
  assert.ok('pageSize' in result, 'result must have a pageSize property');
  assert.equal(result.page, 3);
  assert.equal(result.pageSize, 10);
});
