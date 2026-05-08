---
description: "Use when changing UI, client-side state, styling, forms, or interactions. Covers frontend best practices for accessibility, responsive behavior, and UX clarity."
applyTo: "**/*"
---

# Frontend Standards

Use this instruction for UI and frontend work.

## Expectations

- Preserve the product's existing visual language unless redesign is requested.
- Maintain accessibility for keyboard, focus, contrast, semantics, and screen readers.
- Keep responsive behavior intentional, not incidental.
- Prefer straightforward state flow over clever abstractions.
- Validate loading, empty, error, and success states.
- Keep forms and async actions recoverable: preserve user input when requests fail.
- Avoid layout shift and confusing motion during initial load and async refreshes.

## Review Lens

- Is the UI understandable at common breakpoints?
- Are interactions accessible without a mouse?
- Are network and async states communicated clearly?
- Does the implementation fit existing patterns in the codebase?
- Are copy, affordances, and error states specific enough to help the user recover?
