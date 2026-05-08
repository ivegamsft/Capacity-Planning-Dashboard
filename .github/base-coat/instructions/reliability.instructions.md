---
description: "Use when changing code paths where uptime, retries, background work, or dependency failures matter. Covers common reliability and operability best practices."
applyTo: "**/*"
---

# Reliability Standards

Use this instruction when a change depends on external systems, asynchronous work, or long-running processes.

## Expectations

- Make failure modes visible and bounded with timeouts, cancellation, and clear error handling.
- Use retries only for transient failures, with limits and backoff.
- Design background and scheduled work to be idempotent when practical.
- Emit enough logs or telemetry to reconstruct what happened during failures.
- Avoid partial writes or split-brain behavior when multiple systems must stay consistent.
- Prefer health checks and graceful shutdown behavior for services that stay running.

## Review Lens

- What happens when a dependency is slow, unavailable, or returns bad data?
- Can the operation be retried safely?
- Is there enough observability to diagnose a production issue without reproducing locally?
- Does the change create hidden coupling between independent systems?
