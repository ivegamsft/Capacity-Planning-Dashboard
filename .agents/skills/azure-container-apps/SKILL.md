---
name: azure-container-apps
title: Azure Container Apps Deployment & Operations
description: Deploy, scale, and manage containerized applications on Azure Container Apps with Dapr, revision management, and advanced networking
compatibility: ["agent:containerization-planner", "agent:devops-engineer"]
metadata:
  domain: infrastructure
  maturity: production
  audience: [devops-engineer, backend-engineer, platform-engineer]
allowed-tools: [bash, azure-cli, docker, kubectl, terraform]
---


# Azure Container Apps Skill

Azure Container Apps (ACA) is a fully managed serverless container service for building and deploying modern applications at scale. This skill covers deployment patterns, Dapr integration, scaling strategies, revision management, and multi-container environments.

## Deployment Patterns

See \eferences/deployment-patterns.md\ for comprehensive deployment pattern examples including:
- Basic container deployment
- Using Azure Container Registry with managed identity
- Best practices for image management

## Dapr Integration

See \eferences/dapr-integration.md\ for Dapr integration guidance including:
- Enabling Dapr sidecars
- State management components
- Service invocation patterns

## Scaling Rules

See \eferences/scaling-rules.md\ for scaling configuration including:
- HTTP-based scaling rules
- KEDA scaling definitions
- Azure Event Hub scaling
- Custom metrics

## Revision Management

See \eferences/revision-management.md\ for revision management including:
- Creating new revisions
- Traffic splitting and blue-green deployments
- Listing and managing revisions

## Ingress Configuration

See \eferences/ingress-configuration.md\ for ingress setup including:
- External ingress with TLS
- Internal ingress
- Custom domains and SSL binding

## Managed Identity

See \eferences/managed-identity.md\ for managed identity configuration including:
- System-assigned and user-assigned identities
- Role assignment
- Key Vault and ACR access patterns

## Health Probes

See \eferences/health-probes.md\ for health probe configuration including:
- Liveness probes
- Readiness probes
- Startup probes
- Configuration via CLI, YAML, and Bicep

## Azure Container Apps Jobs

See \eferences/container-apps-jobs.md\ for container app jobs including:
- Scheduled jobs (cron)
- Event-driven jobs
- Job scaling and execution

## Multi-Container Environments

See \eferences/multi-container-environments.md\ for multi-container setup including:
- Environment creation
- Internal service-to-service communication
- DNS naming conventions

## Bicep Templates

For complete infrastructure-as-code examples, see the detailed reference sections above for Bicep template snippets embedded in each deployment pattern.

## Related Topics

- **Container Registry**: Manage container images with Azure Container Registry
- **Azure Functions**: Serverless compute for event-driven workloads
- **App Service**: Alternative platform for application hosting
