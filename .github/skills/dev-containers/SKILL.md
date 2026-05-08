---
name: dev-containers
description: VS Code Dev Containers for reproducible development environments. Covers devcontainer.json configuration, Docker image selection, feature references, VS Code extensions in containers, GitHub Codespaces setup, and environment reproducibility.
compatibility: ["devops-engineer", "backend-dev", "frontend-dev"]
metadata:
  category: "Development & Operations"
  tags: ["dev-containers", "docker", "codespaces", "devcontainer", "reproducible-environments"]
  maturity: "production"
  audience: ["developers", "devops-engineers", "team-leads"]
allowed-tools: ["docker", "bash", "json", "yaml"]
---

# VS Code Dev Containers

Professional patterns for defining reproducible development environments using VS Code Dev Containers and GitHub Codespaces.

## Overview

Dev Containers enable consistent development environments across machines and team members. They eliminate "works on my machine" problems by bundling language runtimes, tools, and extensions in a Docker container.

**Benefits**
- Reproducible environments: identical setup on laptop, CI, and Codespaces
- No local toolchain installation: all dependencies in container
- Easy onboarding: new team members clone repo and open in container
- Isolated per-project: no conflicts with global installations
- CI/CD consistency: dev environment matches build/test/deployment environment

## devcontainer.json Structure

`devcontainer.json` defines the container configuration for VS Code and Codespaces.

**Minimal devcontainer.json**

```json
{
  "name": "My Project",
  "image": "mcr.microsoft.com/vscode/devcontainers/python:3.12",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "python.linting.enabled": true,
        "python.linting.pylintEnabled": true
      }
    }
  },
  "forwardPorts": [5000, 8000],
  "postCreateCommand": "pip install -r requirements.txt"
}
```

**Complete devcontainer.json with All Options**

```json
{
  "name": "Full-Stack Development",
  "image": "mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04",

  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20",
      "nodeGypModule": true
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.12",
      "installTools": true
    },
    "ghcr.io/devcontainers/features/docker-in-docker:2": {
      "version": "latest",
      "moby": true
    },
    "ghcr.io/devcontainers/features/git:1": {
      "ppa": true,
      "version": "latest"
    }
  },

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.remote-explorer",
        "ms-python.python",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "ms-azuretools.vscode-docker",
        "GitHub.copilot"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "[python]": {
          "editor.defaultFormatter": "ms-python.python"
        },
        "python.linting.enabled": true,
        "python.testing.pytestEnabled": true
      }
    }
  },

  "forwardPorts": [3000, 5000, 8000, 8080, 5432],
  "portsAttributes": {
    "3000": {
      "label": "Frontend",
      "onAutoForward": "notify"
    },
    "5432": {
      "label": "PostgreSQL",
      "onAutoForward": "silent"
    }
  },

  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "postStartCommand": "bash .devcontainer/post-start.sh",

  "remoteUser": "vscode",

  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,readonly"
  ],

  "runArgs": [
    "--cap-add=SYS_PTRACE",
    "--security-opt=seccomp=unconfined"
  ]
}
```

## Docker Image Selection

Choose the base image based on your stack's primary language or framework.

| Image | Use Case | Pre-installed |
|---|---|---|
| `mcr.microsoft.com/vscode/devcontainers/python:3.12` | Python projects | Python 3.12, pip, venv, git, curl |
| `mcr.microsoft.com/vscode/devcontainers/node:20` | Node.js projects | Node 20, npm, yarn, git, curl |
| `mcr.microsoft.com/vscode/devcontainers/dotnet:8.0` | .NET projects | .NET 8, C#, git, curl |
| `mcr.microsoft.com/vscode/devcontainers/go:1.21` | Go projects | Go 1.21, git, curl |
| `mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04` | Multi-language | Ubuntu 22.04, git, curl; add languages via features |
| `mcr.microsoft.com/devcontainers/universal:2` | Full stack | Multiple languages preinstalled; heavyweight |

**Recommendation**: Use language-specific images for single-stack projects; use `base:ubuntu` + features for multi-language projects.

## Features

Features are modular packages that add tools, runtimes, or services to the base image.

**Common Features**

```json
{
  "features": {
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
    "ghcr.io/devcontainers/features/node:1": { "version": "20" },
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/postgres:1": { "version": "15" },
    "ghcr.io/devcontainers/features/redis:1": { "version": "7" }
  }
}
```

## VS Code Extensions

Specify extensions to install automatically in the container.

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-vscode.remote-explorer",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

## Post-Create Command

Run setup tasks once when container is created.

```json
{
  "postCreateCommand": "bash .devcontainer/post-create.sh"
}
```

**.devcontainer/post-create.sh**

```bash
#!/usr/bin/env bash
set -e

echo "Setting up development environment..."

if [ -f "requirements.txt" ]; then
  pip install -r requirements.txt
fi

if [ -f "package.json" ]; then
  npm ci
fi

echo "Environment ready"
```

## Port Forwarding

Forward container ports to access running services.

```json
{
  "forwardPorts": [3000, 5000, 8000, 5432],
  "portsAttributes": {
    "3000": { "label": "Frontend", "onAutoForward": "notify" },
    "5432": { "label": "PostgreSQL", "onAutoForward": "silent" }
  }
}
```

## Mounts

Mount host directories for credentials and configuration.

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,readonly",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,readonly"
  ]
}
```

## GitHub Codespaces

Codespaces automatically uses `devcontainer.json`. Configure machine type:

```json
{
  "codespaces": {
    "machineType": "standardLinux32gb"
  }
}
```

**Options**: `basicLinux32gb`, `standardLinux32gb`, `standardLinux64gb`

## Best Practices

1. Check `devcontainer.json` into git for team consistency.
2. Version features and images; avoid `latest`.
3. Minimize container size; only include necessary dependencies.
4. Document onboarding in README.
5. Test in Codespaces regularly.
6. Never embed credentials in Dockerfile or devcontainer.json.
7. Use lifecycle hooks for setup and verification.

## Standards and References

- **VS Code Dev Containers Documentation** — Official specification and patterns.
- **Dev Containers Specification** — Open Container Initiative specification.
- **Docker Best Practices** — Image optimization and Dockerfile patterns.
- **GitHub Codespaces** — Cloud-based dev containers with Codespaces integration.
