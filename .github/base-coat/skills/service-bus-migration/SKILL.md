---
name: service-bus-migration
title: MSMQ to Azure Service Bus Migration
description: Migrate enterprise messaging from MSMQ to Azure Service Bus with patterns for mapping, serialization, resilience, and hybrid bridge architecture
compatibility: ["agent:backend-dev", "agent:devops-engineer"]
metadata:
  domain: infrastructure
  maturity: production
  audience: [backend-engineer, devops-engineer, architect]
allowed-tools: [csharp, azure-cli, docker]
---

# Service Bus Migration Skill

Comprehensive guidance for migrating enterprise messaging systems from Microsoft Message Queuing (MSMQ) to Azure Service Bus. Covers migration patterns, architecture decisions, and operational best practices for zero-downtime transitions.

## Quick Navigation

**New to this migration?** Start here:
1. Review [Migration Patterns](references/migration-patterns.md) for strategy options
2. Study [Dead-Letter & Retry](references/dead-letter-and-retry.md) for resilience
3. Explore [Advanced Patterns](references/advanced-patterns.md) for hybrid bridge and transactional messaging

## Overview

This refactored skill is organized into focused references for better navigation:

- **[references/migration-patterns.md](references/migration-patterns.md)** — Direct lift-and-shift vs gradual migration, topic/subscription mapping, message serialization conversion
- **[references/dead-letter-and-retry.md](references/dead-letter-and-retry.md)** — Dead-letter queue processing, exponential backoff, transient error classification
- **[references/advanced-patterns.md](references/advanced-patterns.md)** — Outbox pattern for atomicity, hybrid bidirectional bridge, migration control plane, phased cutover checklist

## Key Migration Phases

1. **Phase 0: MSMQ Only** — Baseline, no changes
2. **Phase 1: MSMQ Primary → Service Bus Secondary** — Shadow writes, validate conversions
3. **Phase 2: Service Bus Primary → MSMQ Secondary** — Safe fallback, monitor closely
4. **Phase 3: Service Bus Only** — MSMQ decommissioned

## Migration Checklist Highlights

- [ ] Audit MSMQ topology and message volumes
- [ ] Plan Service Bus tier (Standard vs Premium) and partitioning
- [ ] Implement message serialization adapter (Binary → JSON)
- [ ] Deploy hybrid bridge for parallel operation
- [ ] Run extended validation period (1-2 weeks typical)
- [ ] Monitor error rates, DLQ, and latency throughout cutover
- [ ] Decommission MSMQ only after Phase 3 validation

## Best Practices

- **Favor the Outbox Pattern** for guaranteed message delivery without distributed transactions
- **Classify errors carefully** — transient (retry-safe) vs permanent (dead-letter)
- **Use feature flags** for staged routing mode transitions
- **Monitor dead-letter queues** as early warning indicators
- **Preserve correlation IDs** through serialization conversions

## Additional Resources

- [Azure Service Bus Documentation](https://learn.microsoft.com/azure/service-bus-messaging/)
- [Migrate from MSMQ to Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-migrate-msmq-to-service-bus)
- [Outbox Pattern for Microservices](https://learn.microsoft.com/dotnet/architecture/microservices/multi-container-microservice-docker-application/subscribe-events#designing-atomicity-and-idempotency-when-publishing-integration-events-across-microservices)
