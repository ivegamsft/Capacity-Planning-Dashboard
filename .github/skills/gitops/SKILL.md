---
name: gitops
description: GitOps fundamentals, Flux/ArgoCD workflows, desired-state reconciliation, multi-cluster topology, and secrets management patterns
compatibility: "Requires kubectl and Git. Works with VS Code, CLI, and Copilot Coding Agent."
metadata:
  category: "infrastructure"
  keywords: "gitops, flux, argocd, kubernetes, desired-state, declarative"
  model-tier: "premium"
allowed-tools: "search/codebase bash kubectl"
---

# GitOps

## GitOps Fundamentals

GitOps is a set of practices that use Git as the single source of truth for declaring the desired state of infrastructure and applications.

### Core Principles

1. **Declarative** — Define desired state in Git, not imperative commands
2. **Versioned & Immutable** — All changes tracked in Git history
3. **Pulled, not Pushed** — Operators pull from Git, don't push from CI/CD
4. **Continuously Reconciled** — Operator detects drift and auto-corrects

### Workflow: Design → Apply → Verify

```
Application Developer
    ↓
Commits manifests to Git (infrastructure-repo/)
    ↓
Git webhook triggers GitOps Operator (Flux/ArgoCD)
    ↓
Operator pulls manifests from Git
    ↓
Operator applies to Kubernetes (kubectl apply)
    ↓
Operator continuously monitors:
  - Is actual state == desired state?
  - If not, auto-correct (reconcile)
```

## Flux: Declarative GitOps for Kubernetes

Flux automatically pulls manifests from Git and applies them to the cluster.

### Installation

```bash
# Install Flux operator on cluster
flux install --namespace=flux-system

# Bootstrap: configure Flux to manage itself
flux bootstrap github \
  --owner=my-org \
  --repository=flux-config \
  --branch=main \
  --path=./clusters/prod \
  --personal
```

### Repository Structure

```
flux-config/
├── clusters/
│   ├── prod/
│   │   ├── flux-system/        # Flux operator config
│   │   ├── apps.yaml           # Application refs
│   │   └── infrastructure.yaml  # Infrastructure refs
│   └── staging/
└── apps/
    ├── backend/
    │   ├── kustomization.yaml
    │   └── deployment.yaml
    └── frontend/
        ├── kustomization.yaml
        └── deployment.yaml
```

### Basic Kustomization

File: `clusters/prod/apps.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
metadata:
  name: backend-app
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-config
  path: ./apps/backend
  postBuild:
    substitute:
      env: prod
      image_tag: v1.2.3
```

### Multi-Environment Promotion

Promote changes from staging → prod via Git PR:

```
1. Developer commits to staging branch
2. Flux deploys to staging cluster
3. QA tests in staging
4. Developer creates PR: staging → prod
5. Approver merges PR
6. Flux detects change, deploys to prod
```

File: `clusters/prod/backend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: default
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: backend
        image: my-registry/backend:v1.2.3  # Tag from Git, pulled by Flux
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

## ArgoCD: GitOps with Web UI

ArgoCD provides a web UI for GitOps workflows and multi-cluster management.

### Installation

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access web UI
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Browse: https://localhost:8080
# Default user: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Application Definition

File: `argocd-apps/backend.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/my-org/app-config
    targetRevision: main
    path: apps/backend
  
  destination:
    server: https://kubernetes.default.svc  # Local cluster
    namespace: default
  
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Auto-sync on cluster drift
    syncOptions:
    - CreateNamespace=true
```

### Multi-Cluster Topology

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod-us
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/my-org/app-config
    targetRevision: main
    path: apps/backend
  
  destination:
    server: https://prod-us-cluster-api:6443  # US region
    namespace: default
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Repeat for each cluster/region:
```
prod-us, prod-eu, staging-us, staging-eu, ...
```

## Secrets Management in GitOps

**Never commit secrets to Git!** Use one of:

### Option 1: External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-keyvault
spec:
  provider:
    azurekv:
      authSecretRef:
        clientID:
          name: azure-credentials
          key: client-id
      tenantID: 12345678-1234-1234-1234-123456789012
      vaultURL: https://my-vault.vault.azure.net
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: azure-keyvault
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: db-password
    remoteRef:
      key: db-password
```

### Option 2: Sealed Secrets

```bash
# Install sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.x.x/controller.yaml

# Create secret on cluster, then seal for Git
echo -n mypassword | kubectl create secret generic app-secrets --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal -f - > sealed-secret.yaml

# Commit sealed-secret.yaml to Git
# Controller automatically unseals when applied to cluster
```

### Option 3: Kyverno (Policy Engine)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-unencrypted-secrets
spec:
  validationFailureAction: audit
  rules:
  - name: check-secret-not-in-plaintext
    match:
      resources:
        kinds:
        - Secret
    validate:
      message: "Secrets must be sealed or external"
      pattern:
        kind: Secret
        metadata:
          labels:
            sealed: "true"  # Only allow sealed secrets
```

## Desired-State Reconciliation

GitOps operators continuously compare actual cluster state with desired state in Git:

```
Every 30 seconds (configurable):
  1. Read desired state from Git
  2. Read actual state from cluster
  3. Calculate diff
  4. If diff exists, reconcile (kubectl apply)
  5. Report status
```

### Monitoring Reconciliation

```bash
# Watch Flux reconciliation status
flux get kustomizations --watch

# Watch ArgoCD application sync status
argocd app list
argocd app get my-app --refresh

# View recent operations
flux logs --follow
```

### Common Drift Scenarios

| Scenario | Cause | Resolution |
|----------|-------|-----------|
| Manual `kubectl apply` in prod | Operator forgot to commit | Revert, commit to Git, let Flux reconcile |
| Cluster autoscaler scaled pod | Pod resource limits too high | Update limits in Git, reapply |
| Image tag changed | CI/CD pushed new tag without Git update | Update tag in Git, reconcile |

## Multi-Cluster Deployment

### Hub-and-Spoke Topology

Central hub cluster runs GitOps controller; spoke clusters are managed targets:

```
                    ┌─ Spoke-US (prod-us)
                    ├─ Spoke-EU (prod-eu)
       Hub Cluster ─┤
    (ArgoCD Server) ├─ Spoke-Staging (staging)
                    └─ Spoke-DR (disaster recovery)
```

### Setup

1. Install ArgoCD on hub cluster
2. Register spoke clusters (provide API endpoint + credentials)
3. Deploy applications to multiple clusters via single Git repository

```bash
# Register spoke cluster
argocd cluster add my-spoke-us --name prod-us
argocd cluster list
```

4. Create applications targeting each cluster

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod-us
spec:
  destination:
    server: https://prod-us-api:6443  # Spoke cluster API
    namespace: default
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod-eu
spec:
  destination:
    server: https://prod-eu-api:6443  # Spoke cluster API
    namespace: default
```

## Best Practices

- **Separate config by environment** — Use Git branches or directory structure
- **Automate everything** — Avoid manual `kubectl apply` commands
- **Review all changes** — Require PR approval before merging to main
- **Implement RBAC** — Restrict who can merge to main branch
- **Monitor reconciliation** — Alert if GitOps operator falls out of sync
- **Use namespaces** — Isolate applications and teams
- **Version images explicitly** — Don't use `latest` tags

## See Also

- Flux: https://fluxcd.io/
- ArgoCD: https://argo-cd.readthedocs.io/
- GitOps Best Practices: https://opengitops.dev/
