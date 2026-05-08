# MCP Deployment

This document explains how to run Base Coat as a deployable MCP server.

## Purpose

The Base Coat MCP server exposes the packaged standards catalog through a read-only stdio server so AI clients can discover and retrieve approved Base Coat assets without granting write access.

## Included Package

- `mcp/package.json`
- `mcp/index.js`
- `mcp/Dockerfile`
- `mcp/README.md`

## Deployment Modes

### Local Node Runtime

1. Extract the published Base Coat release artifact.
2. Change into `mcp/`.
3. Run `npm install`.
4. Start the server with `npm start`.

### Container Runtime

1. Build the image from repository root:

```bash
docker build -f mcp/Dockerfile -t basecoat-mcp .
```

1. Run the container with stdio attached:

```bash
docker run --rm -i basecoat-mcp
```

## Available Tools

- `basecoat_inventory`
- `basecoat_read_asset`
- `basecoat_search_assets`

## Security Notes

- The server is read-only.
- Asset access is restricted to approved Base Coat directories and top-level files.
- Secrets and credentials are not required for the default local deployment model.
- For production use, pin the container image digest or release artifact version.

## Validation

Run the package self-test:

```bash
cd mcp
npm install
npm run self-test
```
