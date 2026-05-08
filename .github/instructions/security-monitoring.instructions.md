---
description: >
  Security monitoring standards for SIEM integration, alert configuration,
  detection rule development, and incident escalation workflows.
applyTo: agents/security-monitor.agent.md, agents/config-auditor.agent.md, agents/incident-responder.agent.md
---

# Security Monitoring Standards

## Overview

When instrumenting applications for security monitoring, follow these standards:

## SIEM Integration

### Event Ingestion

- **Normalization:** Map all log formats to common schema (CEF, Syslog, JSON)
- **Enrichment:** Add context (user, asset, location, threat intelligence)
- **Parsing:** Define field extraction patterns for each source type
- **Retention:** Define based on compliance (SOC2: 90 days, HIPAA: 6 years, PCI-DSS: 1 year minimum)

Example: Splunk props.conf for nginx access logs
```ini
[nginx:access]
TRANSFORMS-extract = extract-fields
LINE_BREAKER = \n
TIME_PREFIX = \[
TIME_FORMAT = %d/%b/%Y:%H:%M:%S %z
```

### Alert Rules

Define SIEM alerts following this pattern:

```yaml
Alert Template:
  Name: "Suspicious PowerShell Execution"
  Type: "Correlation" | "Anomaly" | "Threshold"
  Severity: "Critical" | "High" | "Medium" | "Low"
  MITRE ATT&CK: "T1027 (Obfuscated Files or Information)"
  
  Detection Query:
    # Splunk SPL, KQL, or vendor-native syntax
    index=windows EventCode=4688 
    | where process_name="powershell.exe"
    | where command LIKE "%IEX%" OR command LIKE "%DownloadString%"
    | stats count by user, hostname, command
    | where count > 3
  
  Baseline: "200 events/day (normal PowerShell activity)"
  Threshold: "5 events/hour (anomalous spike)"
  
  Response Actions:
    - Severity: Critical → Alert SOC immediately, open incident
    - Severity: High → Alert SOC within 1 hour
    - Severity: Medium → Queued for daily review
    - Severity: Low → Logged, no alert
  
  Escalation:
    1. SOC Analyst reviews alert
    2. If confirmed: Incident Handler (Response playbook)
    3. If critical: Incident Commander (mobilize response)
    4. If data exfiltration: Legal + PR notification
```

### False Positive Tuning

- **Whitelist known-good activity:** Service accounts, scheduled jobs, automation
- **Baseline adjustment:** Update thresholds as systems scale
- **Correlation:** Reduce alert noise by combining weak signals into strong ones
- **Playbook:** Define investigation checklist to confirm true positive

Example: Reduce false positives in "Multiple Failed Logins" alert
```yaml
Baseline:
  - Normal failed logins: 10/day (typos, forgotten passwords)
  - Anomalous: 50+ failed logins/hour

Whitelist:
  - Service accounts: svc_app, svc_batch (expected failures)
  - VPN clients: [VPN_IP_RANGE] (brief authentication storms)

Threshold: 25 failed logins in 5 minutes from single user
  - This filters out human typos but catches brute force
```

## Detection Rule Development

### MITRE ATT&CK Mapping

Every detection rule maps to MITRE ATT&CK technique:

```yaml
Rule Anatomy:
  MITRE ATT&CK Tactic: "Persistence"
  MITRE ATT&CK Technique: "T1547 (Boot or Logon Autostart Execution)"
  Sub-technique: "T1547.001 (Registry Run Keys / Startup Folder)"
  
  Example Indicators:
    - Registry write to HKLM\Software\Microsoft\Windows\CurrentVersion\Run
    - New .lnk file in C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
    - New scheduled task with system privilege
```

### Detection Query Templates

**Template 1: Behavioral Anomaly (Statistical)**
```sql
-- Baseline normal behavior, detect spike
SELECT user, hostname, action, COUNT(*) as count
FROM events
WHERE timestamp > now() - interval 5 minutes
GROUP BY user, hostname, action
HAVING count > (SELECT avg(count) FROM events WHERE timestamp > now() - interval 7 days) * 3
```

**Template 2: Known Malware Indicator (IoC Match)**
```sql
-- Match against threat intelligence feeds
SELECT * FROM events
WHERE ip IN (SELECT ip FROM threat_intel WHERE source='CISA' AND type='malware_c2')
OR file_hash IN (SELECT file_hash FROM threat_intel WHERE source='VirusTotal' AND verdict='malicious')
```

**Template 3: Impossible Travel (Location-Based)**
```sql
-- User logged in from geographically impossible locations
SELECT user, location1, location2, 
       (miles / time_seconds * 3600 / 3.6e6) as mph
FROM (
  SELECT user, 
    LAG(location) OVER (PARTITION BY user ORDER BY timestamp) as location1,
    location as location2,
    LAG(timestamp) OVER (PARTITION BY user ORDER BY timestamp) as time1,
    timestamp as time2,
    calculate_distance(LAG(location), location) as miles,
    (timestamp - LAG(timestamp)) as time_seconds
)
WHERE mph > 900  -- Faster than commercial jet
```

## Incident Escalation

### Severity Mapping

| Severity | Example | Response Time | Action |
|----------|---------|---|---|
| **P0 / Critical** | Active data exfiltration, ransomware encryption observed, authentication bypassed | 15 min | Incident Commander → Full mobilization |
| **P1 / High** | Lateral movement detected, privilege escalation, suspicious process, credential theft | 1 hour | SOC Analyst → Incident Handler |
| **P2 / Medium** | Multiple failed login attempts, suspicious network traffic, policy violation | 4 hours | SOC Analyst → Investigation queue |
| **P3 / Low** | Single failed login, known-good process, informational event | 1 day | Logged for trends analysis |

### Escalation Workflow

```
1. ALERT TRIGGERED
   ├─ SIEM rule fires
   └─ Alert routed to on-call SOC analyst
   
2. TRIAGE (15 min)
   ├─ Confirm severity level
   ├─ Is this a false positive?
   │   ├─ YES → Tune rule, document whitelist
   │   └─ NO → Proceed to investigation
   
3. INVESTIGATION (30 min - 2 hours)
   ├─ Determine scope (1 user? 100 users? 1 system? entire network?)
   ├─ Identify attack pattern (reconnaissance? exploitation? exfiltration?)
   ├─ Correlate with other events
   └─ Gather evidence (logs, network captures, forensics)
   
4. ESCALATION DECISION
   ├─ Confirmed incident? → Open incident ticket
   ├─ Requires immediate action? → Page incident commander
   ├─ Data exfiltration? → Notify legal + PR
   └─ Containment needed? → Begin remediation playbook
   
5. RESPONSE
   ├─ Isolate affected systems
   ├─ Kill malicious processes
   ├─ Reset compromised credentials
   ├─ Patch vulnerabilities
   └─ Monitor for re-compromise
```

### On-Call Rotations

- **SOC Analyst (24/7 rotation):** Triage alerts, initial investigation
- **Incident Handler (24/7 rotation):** Confirmed incidents, remediation playbooks
- **Incident Commander (on-demand):** P0/P1 incidents, stakeholder communication
- **Forensics (business hours + escalation):** Post-incident analysis

## Log Standardization

### Event Schema

All security logs should include:

```json
{
  "timestamp": "2024-05-03T14:22:31.234Z",
  "event_id": "uuid",
  "event_type": "authentication_attempt | process_creation | file_write | network_connect",
  "severity": "critical | high | medium | low | info",
  "source": {
    "user": "alice@example.com",
    "hostname": "laptop-001",
    "ip": "192.168.1.100",
    "process_name": "powershell.exe",
    "process_id": 1234
  },
  "resource": {
    "type": "file | registry | network | credential",
    "name": "C:\\Windows\\System32\\config\\SAM",
    "action": "read | write | delete | execute"
  },
  "threat_intel": {
    "matched_indicators": ["APT.Lazarus.C2.Domain"],
    "risk_score": 85
  },
  "context": {
    "mitre_attck": ["T1005 (Data from Local System)"],
    "compliance": ["PCI-DSS.10.2.1"]
  }
}
```

## Compliance Mappings

### SOC2 CC7.2 (Monitor System Components & Information for Anomalies)

Demonstrate detection of anomalies:
- Real-time alerting (not just log review)
- Baseline establishment and monitoring
- Anomaly investigation documented
- Response time SLAs met

### HIPAA Security Rule §164.308(a)(3)(ii)(H) (Monitoring & Reporting)

Log and monitor:
- Access to ePHI (electronic protected health information)
- System events (login, logout, data access, modifications)
- Retention: Minimum 6 years

### PCI-DSS Requirement 10.3 (Security Event Logging)

Monitor and log:
- All access to cardholder data
- Administrative access to critical systems
- Invalid access attempts
- Disabled logging mechanisms

## References

- [NIST CSF 2.0 — Detect Function](https://csrc.nist.gov/publications/detail/cswp/29)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [OWASP Top 10 A09:2021 — Logging and Monitoring Failures](https://owasp.org/Top10/A09_2021-Logging_and_Monitoring_Failures/)
- [CIS Controls v8 — Control 8 & 9](https://www.cisecurity.org/controls)
- [SOC2 CC7.2](https://us.aicpa.org/)
