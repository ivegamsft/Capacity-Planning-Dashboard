---
name: twelve-factor
description: "12-Factor App methodology: codebase, dependencies, configuration, backing services, build/run/release, processes, port binding, concurrency, disposability, dev/prod parity, logs, and admin tasks"
compatibility: "Works with VS Code, CLI, and Copilot Coding Agent. Language-agnostic."
metadata:
  category: "architecture"
  keywords: "twelve-factor, app-architecture, cloud-native, stateless, configuration, processes"
  model-tier: "standard"
allowed-tools: "search/codebase"
---

# 12-Factor App Methodology

The 12-Factor App is a methodology for building modern, scalable, cloud-native applications. Use this checklist to audit your application.

## Factor 1: Codebase

**✓ Single codebase tracked in version control; one app per repository**

- [ ] One Git repository per application (not monorepo)
- [ ] All code tracked in Git (no loose files, no manual changes)
- [ ] All team members have access to same codebase
- [ ] Multiple deployments (prod, staging) use same codebase, different config

### Anti-patterns

```
❌ Multiple repos for same app (splits codebase logic)
❌ Manual file changes on production (breaks reproducibility)
✓ Same repo → prod, staging, dev (only config changes)
```

## Factor 2: Dependencies

**✓ Explicitly declare and isolate dependencies**

### Lock Files

```
✓ Node.js: package-lock.json in repo
✓ Python: requirements.txt or pipenv
✓ Java: pom.xml
✓ Go: go.mod
```

### Isolation

```bash
# ✓ Use containers/virtual environments
docker build ...
pip install -r requirements.txt --target ./vendor

# ❌ Never rely on system-installed dependencies
❌ apt-get install python3-pandas  # Not reproducible
```

## Factor 3: Config

**✓ Store config in environment variables (not in code)**

### Secrets

```python
# ✓ Read from environment at runtime
DB_PASSWORD = os.environ['DB_PASSWORD']
API_KEY = os.environ['API_KEY']

# ❌ Hardcode in code
❌ PASSWORD = "supersecret123"
```

### Environment-Specific Settings

```yaml
# ✓ Use env vars for:
- Database connection strings (DEV_DB_URL, PROD_DB_URL)
- API endpoints (DEV_API_URL, PROD_API_URL)
- Feature flags (ENABLE_FEATURE_X)
- Log levels (LOG_LEVEL=debug or production)

# Config file: .env (for local dev only)
# .env (in .gitignore)
DB_HOST=localhost
DB_USER=admin
```

## Factor 4: Backing Services

**✓ Treat databases, caches, message queues as attached resources (not hardcoded dependencies)**

```python
# ✓ Read backing service URLs from config
import pymongo

db_url = os.environ['MONGODB_URL']
client = pymongo.MongoClient(db_url)

# Swap production MongoDB with staging without code change
# Just change env var: MONGODB_URL=mongodb://staging-server
```

### Backing Services Checklist

- [ ] Database (connection string via env var)
- [ ] Cache (Redis/Memcached URL via env var)
- [ ] Message queue (RabbitMQ/Kafka brokers via env var)
- [ ] Email service (SendGrid API key via env var)
- [ ] File storage (S3 bucket name via env var)

## Factor 5: Build, Release, Run

**✓ Strictly separate build, release, and run stages**

```
Code
  ↓
Build Stage: Compile, test, create artifact
  ↓ (artifact: Docker image or JAR)
Release Stage: Combine artifact + config
  ↓ (release: Docker image + env vars)
Run Stage: Execute (immutable, stateless)
```

### Example: Docker

```dockerfile
# Build stage
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run test && npm run build
# Result: /app/dist/

# Release stage (immutable)
FROM node:18-slim
WORKDIR /app
COPY --from=build /app/dist ./dist
ENV PORT=${PORT:-8080}
CMD ["node", "dist/server.js"]
```

### CI/CD Pipeline

```
Push to main
  ↓
Build: npm test, npm build, docker build → image:v1.0.0
  ↓
Release: tag image, push to registry (immutable)
  ↓
Run: Pull image, set env vars, docker run
```

## Factor 6: Processes

**✓ Execute app as one or more stateless processes**

- [ ] No in-memory session state (use Redis/database instead)
- [ ] No local file uploads (use object storage: S3, Azure Blob)
- [ ] No sticky sessions (use load balancer, not app-level affinity)
- [ ] All processes share same code/config

### Anti-patterns

```python
# ❌ Store session in memory
sessions = {}  # Lost on restart!
sessions[user_id] = {"name": "Alice"}

# ✓ Store session in persistent layer
redis.setex(f"session:{user_id}", 3600, json.dumps({"name": "Alice"}))
```

## Factor 7: Port Binding

**✓ Export HTTP service via port binding (app is self-contained)**

```python
# ✓ App binds to port, doesn't rely on external server
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello'

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
```

### Kubernetes

```yaml
# ✓ Pod runs app directly (no Apache/Nginx inside)
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: my-app:v1.0.0
    ports:
    - containerPort: 8080  # App's own port binding
```

## Factor 8: Concurrency

**✓ Design for horizontal scaling (stateless processes)**

```python
# ✓ Stateless process can be replicated
# Process 1, 2, 3, ... all identical
# Load balancer distributes traffic

# Example: 10 processes to handle 10x traffic
# Just start more instances, no code change
```

### Process Type Separation

```
Web tier:   5 × web process (handles requests)
Worker tier: 2 × worker process (handles jobs)
Scheduler:  1 × clock process (handles periodic tasks)
```

## Factor 9: Disposability

**✓ Processes can start quickly and shut down gracefully**

### Fast Startup

- [ ] Precompile dependencies (no lazy loading on start)
- [ ] No expensive initialization (defer if possible)
- [ ] Target startup time: <10 seconds

### Graceful Shutdown

```python
import signal

def graceful_shutdown(signum, frame):
    logger.info("Shutting down gracefully...")
    # Finish processing current requests
    # Close database connections
    # Exit with code 0
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)  # Docker SIGTERM → graceful
```

### Kubernetes Example

```yaml
spec:
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 15"]  # Drain connections
```

## Factor 10: Dev/Prod Parity

**✓ Keep development, staging, and production environments identical**

| Aspect | Dev | Prod | Parity |
|--------|-----|------|--------|
| OS | Ubuntu 22.04 | Ubuntu 22.04 | ✓ |
| Language | Python 3.11 | Python 3.11 | ✓ |
| DB | PostgreSQL 14 | PostgreSQL 14 | ✓ |
| Redis | Redis 7 | Redis 7 | ✓ |
| Deploy method | Docker | Docker | ✓ |
| Configs | .env file | Env vars | ✓ (same source) |

### Docker Compose for Dev

```yaml
# docker-compose.yml (local dev mirrors prod)
version: '3'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=postgres
      - DB_USER=admin
      - DB_PASSWORD=devpass
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_PASSWORD=devpass
```

## Factor 11: Logs

**✓ Write logs to stdout; don't manage logfiles**

```python
# ✓ Write to stdout
print("User login: alice@example.com")
logger.info("User login: alice@example.com")

# Kubernetes/Docker captures stdout → log aggregation service
# Don't write to files; container file system is ephemeral
```

### Log Aggregation

```
App → stdout
  ↓
Docker → Container logs
  ↓
ELK Stack / Datadog / Azure Monitor
  ↓
Searchable dashboard
```

## Factor 12: Admin Tasks

**✓ One-off admin tasks run in same environment as app processes**

### Database Migration Example

```python
# migrations/script.py (same codebase, same config)
import os
from app import db

# Read config from environment (like app does)
db_url = os.environ['DB_URL']
db.connect(db_url)

# Run migration
db.execute("ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE")
```

### Running Admin Task

```bash
# Docker: Run same image, different command
docker run my-app:v1.0.0 python migrations/script.py

# Kubernetes: One-off job
kubectl run -i --rm --restart=Never --image=my-app:v1.0.0 -- python migrations/script.py
```

## Audit Checklist

Run through this before deploying:

- [ ] **Codebase**: Single repo, all code tracked in Git
- [ ] **Dependencies**: Explicit lock file, no system dependencies
- [ ] **Config**: All secrets/env-vars in environment, not hardcoded
- [ ] **Backing services**: URLs read from config, swappable
- [ ] **Build/Release/Run**: Clearly separated stages, immutable artifacts
- [ ] **Processes**: Stateless, shareable config, no sticky sessions
- [ ] **Port binding**: App self-contained, binds to port
- [ ] **Concurrency**: Horizontal scaling possible, processes interchangeable
- [ ] **Disposability**: Fast startup/shutdown, graceful termination
- [ ] **Dev/Prod parity**: Identical environments (use Docker)
- [ ] **Logs**: Stdout only, log aggregation configured
- [ ] **Admin tasks**: Run in app environment, use same config

## See Also

- 12-Factor App: https://12factor.net/
- Cloud-Native Application Architecture: https://www.oreilly.com/library/view/cloud-native-app/9781491984321/
- Related: `architecture.instructions.md`, `deployment.instructions.md`
