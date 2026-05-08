---
name: ha-resilience
title: High-Availability & Resilience Design Patterns
description: Multi-AZ/region architectures, circuit breakers, retries, chaos testing, and SRE practices
compatibility: ["agent:ha-architect"]
metadata:
  domain: infrastructure
  maturity: production
  audience: [architect, sre, devops-engineer]
allowed-tools: [terraform, kubernetes, python, bash, docker]
---

# HA & Resilience Skill

Production patterns for designing and implementing highly available, resilient systems.

## Multi-Region Active-Active Pattern

```terraform
# AWS example: Multi-region RDS with DMS replication
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}

# Primary database
resource "aws_db_instance" "primary" {
  provider           = aws.primary
  engine             = "postgres"
  engine_version     = "14.7"
  instance_class     = "db.r6i.xlarge"
  allocated_storage  = 100
  storage_encrypted  = true
  multi_az           = true
  backup_retention_period = 30
  
  kms_key_id = aws_kms_key.db.arn
  publicly_accessible = false
}

# Secondary database (read replica)
resource "aws_db_instance" "secondary" {
  provider             = aws.secondary
  replicate_source_db  = aws_db_instance.primary.identifier
  skip_final_snapshot  = false
  auto_minor_version_upgrade = true
}

# Route 53 health check & failover routing
resource "aws_route53_health_check" "primary" {
  ip_address        = aws_db_instance.primary.address
  port              = 5432
  type              = "TCP"
  measure_latency   = true
  request_interval  = 10
  failure_threshold = 2
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "primary"
}
```

## Circuit Breaker Implementation

```go
package resilience

import (
    "sync"
    "time"
)

type CircuitState int

const (
    StateClosed CircuitState = iota
    StateOpen
    StateHalfOpen
)

type CircuitBreaker struct {
    mu                  sync.RWMutex
    state               CircuitState
    failureCount        int
    successCount        int
    failureThreshold    int
    successThreshold    int
    timeout             time.Duration
    lastFailureTime     time.Time
}

func NewCircuitBreaker(failureThreshold int, timeout time.Duration) *CircuitBreaker {
    return &CircuitBreaker{
        state:            StateClosed,
        failureThreshold: failureThreshold,
        successThreshold: 2,
        timeout:          timeout,
    }
}

func (cb *CircuitBreaker) Execute(fn func() error) error {
    cb.mu.Lock()
    defer cb.mu.Unlock()
    
    switch cb.state {
    case StateClosed:
        return cb.executeClosed(fn)
    case StateOpen:
        return cb.executeOpen(fn)
    case StateHalfOpen:
        return cb.executeHalfOpen(fn)
    }
    return nil
}

func (cb *CircuitBreaker) executeClosed(fn func() error) error {
    err := fn()
    if err != nil {
        cb.failureCount++
        if cb.failureCount >= cb.failureThreshold {
            cb.state = StateOpen
        }
        return err
    }
    cb.failureCount = 0
    return nil
}

func (cb *CircuitBreaker) executeOpen(fn func() error) error {
    if time.Since(cb.lastFailureTime) > cb.timeout {
        cb.state = StateHalfOpen
        return cb.executeHalfOpen(fn)
    }
    return ErrCircuitOpen
}

func (cb *CircuitBreaker) executeHalfOpen(fn func() error) error {
    err := fn()
    if err != nil {
        cb.state = StateOpen
        return err
    }
    cb.successCount++
    if cb.successCount >= cb.successThreshold {
        cb.state = StateClosed
    }
    return nil
}
```

## Retry with Exponential Backoff

```python
import random
import time

class RetryConfig:
    def __init__(self, max_attempts=3, initial_delay=1.0, max_delay=60.0):
        self.max_attempts = max_attempts
        self.initial_delay = initial_delay
        self.max_delay = max_delay

def retry_with_backoff(config: RetryConfig, fn, *args, **kwargs):
    """Retry function with exponential backoff and jitter."""
    for attempt in range(config.max_attempts):
        try:
            return fn(*args, **kwargs)
        except Exception as e:
            if attempt < config.max_attempts - 1:
                delay = min(
                    config.initial_delay * (2 ** attempt),
                    config.max_delay
                )
                jitter = delay * (0.5 + random.random())
                time.sleep(jitter)
            else:
                raise
```

## Bulkhead Pattern

```python
from concurrent.futures import ThreadPoolExecutor

class Bulkhead:
    def __init__(self, name: str, max_threads: int):
        self.name = name
        self.executor = ThreadPoolExecutor(max_workers=max_threads)

    def submit(self, fn, *args, **kwargs):
        return self.executor.submit(fn, *args, **kwargs)

# Usage
payment_bulkhead = Bulkhead("payment", max_threads=20)
cache_bulkhead = Bulkhead("cache", max_threads=50)
```

## Error Budget Tracking

```python
from datetime import datetime, timedelta

class ErrorBudget:
    def __init__(self, slo_target: float, window_days: int):
        self.slo_target = slo_target
        self.window_days = window_days
        self.incidents = []

    @property
    def total_budget_seconds(self) -> float:
        return self.window_days * 86400 * (1 - self.slo_target)

    @property
    def consumed_seconds(self) -> float:
        return sum(inc['duration'] for inc in self.incidents)

    @property
    def remaining_seconds(self) -> float:
        return max(0, self.total_budget_seconds - self.consumed_seconds)

    @property
    def burn_rate(self) -> float:
        if not self.incidents:
            return 0
        elapsed_days = (datetime.now() - self.incidents[0]['start']).days or 1
        return self.consumed_seconds / elapsed_days / (self.total_budget_seconds / self.window_days)

    def can_deploy(self) -> bool:
        return self.burn_rate <= 3.0
```

## Chaos Testing

```bash
#!/bin/bash
# Inject latency via network policy and verify recovery

set -e

NAMESPACE="production"
LATENCY="500ms"
DURATION="300s"

echo "Starting chaos test: Network latency injection"

# Baseline
curl -s https://api.example.com/health

# Inject latency
echo "Injecting ${LATENCY}..."
# (implementation: use tc, toxiproxy, or network policy)

# Monitor
sleep 60

# Recover
echo "Removing latency..."

# Verify
curl -s https://api.example.com/health
```

---

## References

- [AWS Well-Architected Framework: Reliability](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)
- [Release It! Design and Deploy Production-Ready Software](https://pragprog.com/titles/mnee2/release-it-second-edition/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
