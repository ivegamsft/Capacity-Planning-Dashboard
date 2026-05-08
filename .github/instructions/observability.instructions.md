---
description: >
  OpenTelemetry instrumentation standards — trace context propagation,
  structured logging schema, metrics naming, and dashboard patterns.
applyTo: agents/observability-engineer.agent.md, agents/devops-engineer.agent.md, agents/sre-engineer.agent.md
---

# Observability Standards

## When Instrumenting Applications

Every application should emit **logs, metrics, and traces** following these standards:

## Trace Context Propagation

Always propagate trace context across service boundaries:

### HTTP Headers

**Standard: W3C Trace Context**

```yaml
Request Headers:
  traceparent: "<version>-<trace_id>-<span_id>-<trace_flags>"
  tracestate: "vendor-specific-context"

Example:
  traceparent: "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
  tracestate: "dd=s:-1;o:rum"

Components:
  version: 00 (current version)
  trace_id: 4bf92f3577b34da6a3ce929d0e0e4736 (128-bit hex)
  span_id: 00f067aa0ba902b7 (64-bit hex)
  trace_flags: 01 (sampled) or 00 (not sampled)
```

### Implementation Requirements

- **Inbound:** Extract trace context from request headers
- **Outbound:** Inject trace context into downstream calls
- **Logging:** Include trace_id in every log line
- **Metrics:** Tag metrics with trace_id when relevant
- **Sampling:** Respect trace_flags (don't sample everything in prod)

### Example (Python with Flask + OTEL)

```python
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Auto-instrument Flask and requests library
FlaskInstrumentor().instrument()
RequestsInstrumentor().instrument()

# Trace context automatically propagated:
# 1. Flask extracts traceparent from inbound request
# 2. User code calls requests.get() 
# 3. requests library injects traceparent into outbound request
# 4. Downstream service receives same trace_id
```

## Structured Logging

All logs must be structured (JSON, not free text):

### Schema

```json
{
  "timestamp": "2024-05-03T14:22:31.234567Z",
  "level": "INFO",
  "logger": "auth.service",
  "message": "User authentication successful",
  
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "request_id": "req-12345",
  
  "context": {
    "service": "auth-service",
    "environment": "production",
    "version": "1.2.3",
    "instance_id": "pod-abc123"
  },
  
  "user": {
    "id": "usr_12345",
    "email": "redacted"
  },
  
  "http": {
    "method": "POST",
    "path": "/api/auth/login",
    "status_code": 200,
    "duration_ms": 145
  },
  
  "custom": {
    "auth_method": "oauth2",
    "provider": "google",
    "ip_address": "203.0.113.42"
  }
}
```

### Rules

**DO:**
- Include trace_id + span_id for tracing correlation
- Include request_id for user-centric analysis
- Sanitize PII (never log passwords, tokens, credit cards, SSNs)
- Include duration for performance analysis
- Include error_type + error_message (not stack trace in log line)
- Use consistent field names across all services

**DON'T:**
- Log unstructured free text (must be JSON)
- Include stack traces in log line (ship separately)
- Log secrets (DB passwords, API keys, credentials)
- Log raw request/response bodies (extract meaningful fields only)

### Logging Anti-patterns

```python
# ✗ BAD: Unstructured, includes sensitive data
logger.info(f"User {user_email} logged in from {ip} with password {pwd}")

# ✓ GOOD: Structured, sanitized
logger.info("authentication.success", extra={
    "trace_id": trace_id,
    "user_id": user_id,
    "ip_address": ip,
    "auth_method": auth_method,
})
```

## Metrics Naming Convention

### Naming Format

```
<namespace>.<component>.<metric_name>.<unit>
```

**Examples:**

```yaml
# HTTP metrics
http.request.count (requests)
http.request.duration (milliseconds)
http.request.size (bytes)
http.response.size (bytes)

# Database metrics
database.connection.pool.size (connections)
database.query.duration (milliseconds)
database.query.count (queries)

# Cache metrics
cache.hit.count (operations)
cache.miss.count (operations)
cache.size (bytes)

# System metrics
process.memory.usage (bytes)
process.cpu.usage (percent)
system.disk.usage (bytes)
```

### Metric Labels

Include labels for dimensionality:

```yaml
http.request.count:
  labels: [method, path, status_code]
  example: http.request.count{method="POST", path="/api/users", status_code="200"} = 42

database.query.duration:
  labels: [operation, table, status]
  example: database.query.duration{operation="SELECT", table="users", status="success"} = 123ms
```

## Sampling Strategy

### Production Sampling

**Problem:** Tracing every request = too much data, high cost

**Solution:** Sample intelligently

```yaml
Sampling Strategies:

1. Fixed Sampling (Simple):
   - Sample 1% of all requests
   - Bias: May miss rare, important events
   - Pro: Simple to implement

2. Dynamic Sampling (Recommended):
   - Sample 100% of errors
   - Sample 10% of normal requests
   - Sample 100% of slow requests (> 1 second)
   - Bias-free: Captures all events that matter
   
3. Tail Sampling (Advanced):
   - Collect all spans initially
   - Post-processing decides if worth keeping
   - Criteria: Error? Slow? Contains specific attribute?
   - Pro: Most flexible
   - Con: Memory overhead during collection
```

**Implementation:**

```python
from opentelemetry.sdk.trace.sampling import Sampler, Decision

class SmartSampler(Sampler):
  def should_sample(self, trace_id, parent_context, span_name, attributes):
    # Always sample errors
    if attributes.get('error'):
      return Decision.RECORD_AND_SAMPLE
    
    # Always sample slow requests (> 1s)
    if attributes.get('duration_ms', 0) > 1000:
      return Decision.RECORD_AND_SAMPLE
    
    # Sample 5% of normal requests
    import random
    if random.random() < 0.05:
      return Decision.RECORD_AND_SAMPLE
    
    return Decision.DROP
```

## Dashboard Requirements

Every service should have dashboards for:

### Service Dashboard (Overview)

- Request rate (req/sec)
- P50/P95/P99 latency
- Error rate (%)
- Top slow endpoints
- Top error endpoints

### Application Dashboard (Deeper)

- HTTP method breakdown
- Response size distribution
- Database query performance
- Cache hit ratio
- External service dependencies

### Infrastructure Dashboard (System)

- CPU usage
- Memory usage
- Disk I/O
- Network I/O
- Container restarts

### SLO Dashboard (Compliance)

- SLO target (99.9%)
- Current compliance (%)
- Error budget remaining (hours)
- Burn rate (hours/day)

## Correlation ID Pattern

All logs/traces should share correlation ID across services:

```
User Request → Load Balancer
  trace_id = "abc123" (generated by LB)
  ↓
Service A
  logs: trace_id = "abc123"
  calls downstream with traceparent header
  ↓
Service B
  receives trace_id = "abc123"
  logs: trace_id = "abc123"
  calls downstream
  ↓
Database
  query logs: trace_id = "abc123"
  
Result: Every log, trace, metric tagged with "abc123"
        Query logs can be correlated with API logs
```

## Log Aggregation Architecture

```
Logs Emitted (JSON stdout)
  ↓
Log Collector (Fluentd, Filebeat)
  ↓ (structured parsing)
Centralized Log Store (Loki, ELK, Datadog)
  ↓ (indexed)
Search/Query Interface
  ↓
Alert Rules (CloudWatch, Prometheus)
  ↓
PagerDuty / Incident Management
```

## Compliance Mappings

### SOC2 CC7.2 — System Monitoring

Demonstrate:
- Real-time dashboards showing service health
- Alert rules with SLA response times
- Trace requests across service boundaries
- Log retention compliant with policy (90+ days)

### HIPAA Security Rule §164.308(a)(3)(ii)(H)

- Log all access to ePHI (electronic protected health information)
- Include timestamp, user, action, resource
- Retention: minimum 6 years
- Sanitize: Never log PHI in traces/metrics

### PCI-DSS Requirement 10.1

- Log all access to cardholder data
- Log administrative access
- Log failed access attempts
- Retention: minimum 1 year, 3 months online

## References

- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
- [OpenTelemetry Best Practices](https://opentelemetry.io/docs/instrumentation/best-practices/)
- [Prometheus Metrics Naming](https://prometheus.io/docs/practices/naming/)
- [ELK Stack Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-best-practices.html)
- [Google SRE Book — Monitoring](https://sre.google/books/)
