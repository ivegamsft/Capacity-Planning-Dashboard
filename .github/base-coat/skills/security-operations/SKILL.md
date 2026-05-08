---
name: security-operations
title: Security Operations & Threat Detection
description: Threat detection patterns, SIEM rules, secrets management, audit logging, and incident response automation
compatibility: ["agent:security-operations"]
metadata:
  domain: security
  maturity: production
  audience: [sre, security-engineer, devops-engineer]
allowed-tools: [bash, terraform, kubectl, azure-cli, docker]
---

# Security Operations Skill

Use this skill when implementing threat detection, secrets management, audit logging, and incident response automation. Covers cloud-native (Azure, AWS) and Kubernetes environments.

## Threat Detection Patterns

See \eferences/threat-detection-patterns.md\ for threat detection guidance including:
- Authentication attack detection (Azure AD anomalies, Kubernetes API attacks)
- Data access anomalies (database queries, Azure Blob Storage)
- Privilege escalation detection (RBAC role changes)
- KQL and Bash detection queries

## Secrets Management

See \eferences/secrets-management.md\ for secrets management including:
- Automated credential rotation (Kubernetes, Python scripts)
- Secret access auditing with HashiCorp Vault
- Rotation policies and schedules
- Audit logging for all secret access

## Audit Logging

See \eferences/audit-logging.md\ for centralized audit logging including:
- ELK Stack configuration (Filebeat, Elasticsearch, Logstash)
- Log parsing and enrichment
- Immutable audit trails with Azure Blob Storage
- Retention and versioning policies

## Incident Response Automation

See \eferences/incident-response-automation.md\ for incident response automation including:
- Alert triage and prioritization
- False positive detection
- Threat intelligence correlation
- Automated escalation workflows
- Incident ticket creation and forensics

## Monitoring & Metrics

See \eferences/monitoring-metrics.md\ for security metrics and monitoring including:
- Key security metrics to track
- Alert configuration patterns
- Dashboarding strategies

## Security Operations Playbooks

See \eferences/security-operations-playbooks.md\ for incident response runbooks and playbooks including:
- Common incident types and responses
- Escalation procedures
- Post-incident analysis templates

## References

- **Azure Security Center**: Unified security management across Azure resources
- **Kubernetes Security**: Best practices for securing container workloads
- **Cloud Security Posture Management (CSPM)**: Continuous compliance monitoring
