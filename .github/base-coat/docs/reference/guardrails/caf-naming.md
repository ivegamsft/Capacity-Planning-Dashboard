# Guardrail: CAF Naming Conventions for Azure Resources

**Status:** Active
**Applies to:** All Azure resources provisioned by this repository or any repo that inherits from it.

---

## Rule

All Azure resources **MUST** follow [Microsoft Cloud Adoption Framework (CAF) naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming).

Non-compliant resource names will be rejected during code review and should be caught by validation tooling before deployment.

---

## Naming Table

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-{workload}-{env}` | `rg-myapp-prod` |
| Container App | `ca-{workload}-{env}-{location}-{instance}` | `ca-myapp-prod-eastus-001` |
| Container Registry | `cr{workload}{env}{location}{instance}` | `crmyappprodeastus001` |
| Storage Account | `st{workload}{env}{location}{instance}` | `stmyappprodeastus001` |
| Key Vault | `kv-{workload}-{env}` | `kv-myapp-prod` |

### Placeholder Definitions

| Placeholder | Description | Example values |
|-------------|-------------|----------------|
| `{workload}` | Short name for the workload or application | `myapp`, `api`, `web` |
| `{env}` | Environment identifier | `dev`, `staging`, `prod` |
| `{location}` | Azure region short name | `eastus`, `westus2`, `swedencentral` |
| `{instance}` | Zero-padded instance number | `001`, `002` |

---

## Validation Rules

### Character Limits and Constraints

| Resource | Max Length | Allowed Characters |
|----------|-----------|-------------------|
| Resource Group | 90 | Alphanumerics, hyphens, underscores, periods, parentheses |
| Container App | 32 | Lowercase alphanumerics and hyphens |
| Container Registry | 50 | Alphanumerics only (no hyphens or special characters) |
| Storage Account | 24 | Lowercase alphanumerics only |
| Key Vault | 24 | Alphanumerics and hyphens; must start with a letter |

### How to Validate

1. **Manual review** — Check resource names in Bicep/Terraform files against the naming table above before opening a PR.
2. **Azure Policy** — Deploy `Require tag and its value on resources` or custom naming policies to enforce conventions at the subscription level.
3. **CI linting** — Use tools like [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/) to validate naming conventions in pull request checks.

---

## References

- [CAF — Define your naming convention](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [CAF — Abbreviations for Azure resource types](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [Azure naming rules and restrictions](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)
