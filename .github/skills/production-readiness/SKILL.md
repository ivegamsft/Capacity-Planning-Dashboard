---
name: production-readiness
title: Production Readiness Review & Release Management
description: PRR gates, business continuity planning, disaster recovery procedures, and FMEA templates
compatibility: ["agent:production-readiness"]
metadata:
  domain: operations
  maturity: production
  audience: [release-manager, sre, architect]
allowed-tools: [python, bash, terraform, kubernetes]
---

# Production Readiness Skill

Comprehensive patterns for production readiness review, BCP/DRP planning, and failure mode analysis.

## PRR Gate Checklist

```yaml
Production Readiness Review Criteria:

Deployment Readiness:
  - Deployment automation tested end-to-end
  - Rollback procedure documented and tested
  - Database migrations reversible
  - Feature flags configured for safe rollout
  - Canary deployment plan established
  - Health checks passing on staging

Security & Compliance:
  - Security review completed (SAST, DAST, penetration test)
  - No hardcoded credentials
  - Compliance checklist completed
  - Data privacy impact assessment done
  - Access controls verified

Performance & Scalability:
  - Load testing completed (peak + 2x)
  - Database query performance validated
  - Cache strategy documented
  - Auto-scaling policies configured
  - CDN/edge caching setup

Observability:
  - Logging centralized
  - Metrics/dashboards created
  - Alerting rules configured
  - Distributed tracing enabled
  - Error budget tracked

Incident Response:
  - On-call rotation established
  - Runbooks created
  - Escalation procedures documented
  - War room setup complete
  - Post-mortem process defined

Documentation:
  - Architecture diagram current
  - Runbooks written
  - Disaster recovery plan documented
  - Known issues documented
  - Team trained
```

## PRR Gate Decision Logic

```python
class PRRGate:
    def __init__(self, checklist_results):
        self.results = checklist_results

    def evaluate(self):
        required_items = [
            "deployment-automation-tested",
            "security-review-completed",
            "load-testing-completed",
            "monitoring-configured",
        ]
        
        failed = [item for item in required_items if not self.results.get(item)]
        
        if not failed:
            return {"decision": "APPROVED"}
        elif len(failed) <= 2:
            return {"decision": "APPROVED_WITH_CONDITIONS", "conditions": failed}
        else:
            return {"decision": "REJECTED", "blockers": failed}
```

## Incident Response Runbook

```markdown
# High Error Rate Incident Runbook

## Symptoms
- Error rate > 1% for > 5 minutes

## Immediate Actions (0-5 min)
1. Create incident ticket
2. Start war room
3. Check recent deployments
4. Check metrics dashboard

## Diagnosis (5-15 min)
1. Check error logs
2. Check error rates by endpoint
3. Check database performance

## Quick Fixes
- Recent deploy: rollout undo
- Database timeout: restart connection pool
- Cache miss: clear and warm cache

## Escalation
If not resolved in 15 minutes, page VP Engineering

## Post-Mortem
- Schedule within 24h
- Document root cause
- Create prevention tickets
```

---

## References

- [NIST Incident Response Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf)
- [ISO 22301: Business Continuity](https://www.iso.org/standard/75106.html)
- [AWS Disaster Recovery Strategies](https://aws.amazon.com/blogs/architecture/disaster-recovery-dr-architecture-on-aws/)
