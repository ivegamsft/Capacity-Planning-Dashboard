---

name: mcp-development
description: "Use when building MCP servers, defining tools, or configuring transports. Provides server scaffolds, tool definition templates, and transport configuration boilerplate."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# MCP Development Skill

Use this skill when the task involves designing, scaffolding, or implementing MCP (Model Context Protocol) servers, tool definitions, or transport configurations.

## When to Use

- Scaffolding a new MCP server project
- Defining tool contracts (name, description, input schema, output shape)
- Configuring transport protocols (stdio, SSE, Streamable HTTP)
- Reviewing MCP server implementations for correctness and security
- Integrating an MCP server with clients or deployment pipelines

## How to Invoke

Reference this skill by attaching `skills/mcp-development/SKILL.md` to your agent context, or instruct the agent:

> Use the mcp-development skill. Apply the server template, tool definition template, and transport config template to the feature being built.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `mcp-server-template.md` | MCP server scaffold with initialization, lifecycle hooks, and tool registration |
| `tool-definition-template.md` | Tool definition boilerplate with JSON Schema input, handler structure, and error handling |
| `transport-config-template.md` | Transport protocol configuration for stdio, SSE, and Streamable HTTP |

## Agent Pairing

This skill is designed to be used alongside the `mcp-developer` agent. The agent drives the workflow; this skill provides the reference templates and standards.

For MCP servers that expose API backends, pair with the `backend-dev` agent for service layer implementation. For deployment and CI/CD concerns, pair with the `devops-engineer` agent.
