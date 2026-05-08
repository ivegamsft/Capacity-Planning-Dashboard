---

name: performance-profiling
description: "Use when code is slow, latency regressed, or a hot path needs measurement. Covers profiling best practices, baseline capture, bottleneck isolation, and post-fix verification."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Performance Profiling

Use this skill when a user asks why code is slow, where latency comes from, or how to profile a hot path.

## Workflow

1. Reproduce the slowness with a measurable command, request, or test.
2. Separate startup cost, I/O cost, and steady-state runtime.
3. Use the platform's profiler or timing tools before changing code.
4. Identify the highest-cost path and validate it with data.
5. Implement the smallest fix that improves the measured bottleneck.
6. Re-run the same measurement and report the delta.

## Output

- Baseline measurement
- Likely bottleneck
- Change made
- Post-change measurement
- Remaining risks or follow-ups
