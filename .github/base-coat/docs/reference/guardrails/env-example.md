# Guardrail: `.env.example` for Every Repository

## Rule

Every repository that requires environment variables **MUST** include a `.env.example` file at the repository root. This file documents all required variables so that new contributors can onboard without guessing configuration.

---

## Requirements

The `.env.example` file must contain:

1. **Every required environment variable** — no undocumented vars
2. **A placeholder value** — never a real secret or credential
3. **A description comment** above each variable or group

---

## Minimum Variables for Azure Repos

Any repository that deploys to or authenticates with Azure must include at least:

```env
# Azure Service Principal / OIDC
AZURE_CLIENT_ID=<your-client-id>
AZURE_TENANT_ID=<your-tenant-id>
AZURE_SUBSCRIPTION_ID=<your-subscription-id>

# Resource naming
NAME_PREFIX=<project-name>
ENVIRONMENT=<dev|staging|prod>
AZURE_LOCATION=<azure-region>
```

Add additional variables as needed for the specific project (e.g., database connection strings, feature flags, API endpoints).

---

## Git Rules

| File | Git Status |
|---|---|
| `.env.example` | **Committed** — always checked in |
| `.env` | **Gitignored** — contains real values, never committed |
| `.env.local` | **Gitignored** — local overrides, never committed |

Ensure `.gitignore` includes:

```gitignore
.env
.env.local
```

---

## Developer Workflow

```bash
# 1. Copy the example file
cp .env.example .env

# 2. Fill in your values
# Edit .env with your editor — never commit this file

# 3. (Optional) Local overrides
cp .env.example .env.local
# .env.local takes precedence for local-only settings
```

---

## Placeholder Format

Use angle-bracket placeholders that clearly describe the expected value:

```env
# Good — descriptive placeholders
DATABASE_URL=<postgresql://user:pass@host:5432/dbname>
API_KEY=<your-api-key-from-portal>

# Bad — empty or ambiguous
DATABASE_URL=
API_KEY=changeme
```

---

## Relationship to CONFIG_PATTERN.md

This guardrail complements [`docs/CONFIG_PATTERN.md`](/docs/CONFIG_PATTERN.md), which defines the broader configuration management pattern. `.env.example` is the implementation artifact that makes that pattern work for local development.

---

## Enforcement

- **PR review**: Any PR that adds a new environment variable must also update `.env.example`.
- **CI check (optional)**: Repositories may add a CI step that verifies `.env.example` lists all variables referenced in code.
- **Onboarding**: New contributors should be able to run the project using only the variables documented in `.env.example`.
