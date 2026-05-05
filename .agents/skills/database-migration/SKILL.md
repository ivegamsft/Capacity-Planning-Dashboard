---
name: database-migration
description: Zero-downtime database migration patterns, blue-green deployments, rollback strategies, and schema versioning for production systems
compatibility: "Requires database access tools. Works with VS Code, CLI, and Copilot Coding Agent."
metadata:
  category: "data"
  keywords: "database, migration, flyway, liquibase, zero-downtime, blue-green"
  model-tier: "standard"
allowed-tools: "search/codebase bash sql"
---

# Database Migration

## Zero-Downtime Pattern: Expand-Contract

The expand-contract pattern ensures zero downtime by separating schema changes from data migration:

**Phase 1: Expand** — Add new infrastructure without removing old
```sql
ALTER TABLE users ADD COLUMN email_normalized VARCHAR(255);
UPDATE users SET email_normalized = LOWER(email) WHERE email_normalized IS NULL LIMIT 10000;
```

**Phase 2: Migrate** — Switch application to new schema
```sql
UPDATE users SET email_normalized = LOWER(email) WHERE email_normalized IS NULL;
-- Deploy application: reads/writes from new column only
-- Monitor for 24-48 hours
```

**Phase 3: Contract** — Remove old schema
```sql
ALTER TABLE users DROP COLUMN email;
```

### Key Properties

| Property | Value |
|----------|-------|
| Downtime | **Zero** |
| Rollback | Simple (revert code, keep old column) |
| Duration | Hours to days |
| Tools | Flyway, Liquibase, custom scripts |

## Blue-Green Database Deployments

Run two identical database instances; switch traffic after validation:

```
┌──────────────┐         ┌──────────────┐
│  Blue DB     │         │  Green DB    │
│  (Current)   │         │  (Staging)   │
│ v4 Schema    │         │  v5 Schema   │
└──────────────┘         └──────────────┘
     100% traffic             0% traffic
```

### Cutover Steps

1. Provision Green (identical to Blue)
2. Restore backup to Green + apply migrations
3. Validate against Green (row counts, data integrity, performance)
4. Redirect traffic to Green
5. Monitor 24-48 hours
6. Keep Blue as rollback target for 30 days
7. Decommission Blue

### Cost Optimization

```
Week 1-2: Both instances (full cost)
Week 3-4: Scale Blue down to minimal SKU (~$5/day)
After: Decommission Blue
```

## Rollback Strategies

### Point-in-Time Restore (Fast)

For schema mistakes, restore to pre-migration timestamp:

```sql
RESTORE DATABASE appdb FROM BACKUP appdb_v4.bak WITH RECOVERY
```

**Pros**: Fast (minutes)  
**Cons**: Loses transactions during migration  
**Best for**: Small windows (<1 hour)

### Dual-Write Fallback

Application writes to both databases; reads from primary:

```python
def query(sql):
    try:
        return self.primary.execute(sql)
    except:
        logger.warn("Primary failed, using fallback")
        return self.fallback.execute(sql)
```

**Pros**: Zero data loss  
**Cons**: Complexity  
**Best for**: High-reliability systems

### Feature Flag + Canary

Deploy feature flag to gradually shift traffic:

```
100% → v5 (deployment day)
75% → v5, 25% → v4 (hour 1)
50% → v5, 50% → v4 (hour 2)
0% → v5, 100% → v4 (rollback complete)
```

## Schema Versioning with Flyway

### Project Structure

```
migrations/
├── sql/
│   ├── V1__initial_schema.sql
│   ├── V4__migrate_email.sql
│   └── U4__rollback_email_migration.sql
└── flyway.conf
```

### Migration File Format

Naming: `V{version}__{description}.sql`

```sql
-- V4__migrate_email_to_normalized.sql

ALTER TABLE users ADD COLUMN email_normalized VARCHAR(255);
CREATE INDEX idx_users_email_normalized ON users(email_normalized);

-- Backfill: handled by application, not migration script
INSERT INTO migration_log (version, step, status) 
VALUES (4, 'expand_email_normalized', 'COMPLETED');
```

Rollback: `U{version}__{description}.sql`

```sql
-- U4__rollback_email_migration.sql

ALTER TABLE users DROP COLUMN email_normalized;
DROP INDEX idx_users_email_normalized ON users;
DELETE FROM migration_log WHERE version = 4;
```

### Flyway Commands

```bash
flyway info          # Check current schema version
flyway validate      # Validate migrations
flyway migrate       # Run pending migrations
flyway undo          # Rollback to previous version
```

### CI/CD Integration

```yaml
# .github/workflows/db-migrate.yml
name: Database Migration

on:
  push:
    branches: [main]
    paths: ['migrations/**']

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate migrations
        run: ./flyway validate
      
      - name: Migrate production
        env:
          FLYWAY_URL: ${{ secrets.DB_URL }}
          FLYWAY_USER: ${{ secrets.DB_USER }}
          FLYWAY_PASSWORD: ${{ secrets.DB_PASSWORD }}
        run: ./flyway migrate
      
      - name: Verify
        run: |
          sqlcmd -Q "SELECT COUNT(*) FROM migration_log"
```

## Pre-Migration Checklist

- [ ] Backup production database
- [ ] Test on staging (same data volume)
- [ ] Calculate duration (backfill + testing)
- [ ] Schedule during low-traffic window
- [ ] Disable auto-scaling during migration
- [ ] Have DBA on-call for rollback
- [ ] Document rollback procedure
- [ ] Prepare status communication template

## Monitoring During Migration

| Metric | Target | Tool |
|--------|--------|------|
| Connection pool utilization | <80% | APM |
| Query latency (p95) | <200ms | Azure Monitor |
| Lock wait time | <1s | sys.dm_exec_requests |
| Transaction log usage | <80% | SQL Server DMV |

### Query: Monitor Long-Running Transactions

```sql
SELECT 
    session_id, command, status,
    DATEDIFF(SECOND, start_time, GETUTCDATE()) AS duration_seconds,
    percent_complete
FROM sys.dm_exec_requests
WHERE status = 'running'
ORDER BY start_time;
```

## Related

- Flyway: https://flywaydb.org/
- Liquibase: https://www.liquibase.org/
- Blue-Green Deployments: https://martinfowler.com/bliki/BlueGreenDeployment.html
