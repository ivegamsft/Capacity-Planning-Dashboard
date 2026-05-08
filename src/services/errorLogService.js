'use strict';

/**
 * errorLogService — service layer for querying the DashboardErrorLog table.
 *
 * Responsibilities:
 *  - Input validation and normalization (page, pageSize, level, startDate, endDate)
 *  - Delegation to the SQL store (listDashboardErrorLogsPaginated)
 *  - Returning a consistent paginated envelope: { rows, total, page, pageSize }
 *
 * Validation failures throw an Error with `.status = 422` and `.code = 'VALIDATION_FAILED'`
 * so callers can map them to 422 HTTP responses without special-casing here.
 *
 * Stack traces are intentionally NOT included in list results — they are available
 * via individual record retrieval if a detail view is ever added.
 */

const { listDashboardErrorLogsPaginated } = require('../store/sql');

/** Severity values recognised by the DashboardErrorLog schema. */
const ALLOWED_LEVELS = new Set(['critical', 'error', 'warn', 'warning', 'info']);

const DEFAULT_PAGE_SIZE = 50;
const MAX_PAGE_SIZE = 200;

/**
 * Parse a value as a positive integer within [1, max].
 * Returns `fallback` when the value is missing, non-numeric, or < 1.
 */
function parsePositiveInt(value, fallback, max) {
  if (value == null || value === '') return fallback;
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.trunc(n), max);
}

/**
 * Parse a value as a Date.
 * Returns null when the value is absent.
 * Returns undefined (sentinel) when the value is present but not a valid date.
 */
function parseDate(value) {
  if (!value) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return undefined;
  return d;
}

/**
 * Build a 422 validation error with a machine-readable code.
 * @param {string} message
 * @returns {Error}
 */
function validationError(message) {
  const err = new Error(message);
  err.status = 422;
  err.code = 'VALIDATION_FAILED';
  return err;
}

/**
 * Retrieve a paginated, filtered slice of the DashboardErrorLog table.
 *
 * @param {object}  [params]
 * @param {number}  [params.page=1]            - 1-based page number
 * @param {number}  [params.pageSize=50]        - Rows per page (max 200)
 * @param {string}  [params.level]              - Filter by severity level
 * @param {string}  [params.startDate]          - ISO 8601 lower bound (occurredAtUtc >=)
 * @param {string}  [params.endDate]            - ISO 8601 upper bound (occurredAtUtc <=)
 * @param {string}  [params.source]             - Filter by errorSource (exact match)
 * @param {boolean} [params.onlyUnresolved]     - When true, only return unresolved entries
 * @returns {Promise<{ rows: object[], total: number, page: number, pageSize: number }>}
 * @throws {Error} status=422 / code='VALIDATION_FAILED' on invalid input
 */
async function getErrorLogs(params = {}) {
  // ── Pagination ──────────────────────────────────────────────────────────────
  const page = parsePositiveInt(params.page, 1, 10_000);
  const pageSize = parsePositiveInt(params.pageSize, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE);

  // ── Severity / level ────────────────────────────────────────────────────────
  const rawLevel = params.level ? String(params.level).trim().toLowerCase() : null;
  if (rawLevel && !ALLOWED_LEVELS.has(rawLevel)) {
    throw validationError(
      `Invalid level "${params.level}". Allowed values: ${[...ALLOWED_LEVELS].join(', ')}.`
    );
  }
  // Normalise 'warning' → 'warn' to match the stored column values.
  const severity = rawLevel === 'warning' ? 'warn' : rawLevel;

  // ── Date bounds ─────────────────────────────────────────────────────────────
  const startDate = parseDate(params.startDate);
  const endDate = parseDate(params.endDate);

  if (startDate === undefined) {
    throw validationError(
      `Invalid startDate: "${params.startDate}" is not a valid ISO 8601 date.`
    );
  }
  if (endDate === undefined) {
    throw validationError(
      `Invalid endDate: "${params.endDate}" is not a valid ISO 8601 date.`
    );
  }
  if (startDate && endDate && startDate > endDate) {
    throw validationError('startDate must not be later than endDate.');
  }

  // ── Other filters ───────────────────────────────────────────────────────────
  // Trim and cap source to match the column length (NVARCHAR(64)).
  const source = params.source ? String(params.source).trim().substring(0, 64) : null;
  const onlyUnresolved = Boolean(params.onlyUnresolved);

  // ── Delegate to store ───────────────────────────────────────────────────────
  const offset = (page - 1) * pageSize;

  const { rows, total } = await listDashboardErrorLogsPaginated({
    offset,
    pageSize,
    severity,
    startDate,
    endDate,
    source,
    onlyUnresolved
  });

  return { rows, total, page, pageSize };
}

module.exports = { getErrorLogs };
