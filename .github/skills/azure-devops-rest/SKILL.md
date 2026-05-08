---

name: azure-devops-rest
description: "Azure DevOps REST API patterns — authentication, scopes, pagination, throttling, and endpoint taxonomy for work items, pipelines, repos, and artifacts."
context: fork
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure DevOps REST API Skill

Use this skill when building integrations, scripts, or agents that interact with Azure DevOps Services or Server via the REST API.

## Authentication

### Personal Access Tokens (PAT)

PATs are the most common auth method for scripts and local development.

```bash
# Base64 encode for HTTP Basic auth (username is empty)
TOKEN=$(echo -n ":$PAT" | base64)
curl -H "Authorization: Basic $TOKEN" \
  "https://dev.azure.com/{org}/{project}/_apis/wit/workitems?api-version=7.1"
```

```powershell
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
}
Invoke-RestMethod -Uri "https://dev.azure.com/$Org/$Project/_apis/wit/workitems?api-version=7.1" -Headers $headers
```

### PAT Scopes (Least Privilege)

Always request the **narrowest scope** needed:

| Task | Required Scope |
|------|---------------|
| Read work items | `vso.work` |
| Create/update work items | `vso.work_write` |
| Read repos/code | `vso.code` |
| Create pull requests | `vso.code_write` |
| Read pipelines | `vso.build` |
| Queue builds | `vso.build_execute` |
| Read artifacts/packages | `vso.packaging` |
| Manage service connections | `vso.serviceendpoint_manage` |

### Managed Identity / OIDC (CI/CD)

For Azure-hosted automation, prefer managed identity over PATs:

```yaml
# Azure Pipelines — use system access token
steps:
  - script: |
      curl -H "Authorization: Bearer $(System.AccessToken)" \
        "https://dev.azure.com/$(System.CollectionUri)/_apis/projects?api-version=7.1"
```

### PAT Lifecycle

- Set expiration to **≤90 days** — never create non-expiring tokens.
- Store PATs in Key Vault or GitHub Secrets — never in source code or environment files.
- Rotate PATs before expiration using automated reminders or Key Vault rotation policies.
- Revoke immediately when a team member leaves or a token is compromised.

## API Versioning

Always include `api-version` in every request:

```
https://dev.azure.com/{org}/{project}/_apis/{area}?api-version=7.1
```

- Current stable: `7.1`
- Preview features: `7.1-preview.1` (append preview suffix)
- Never rely on default version — it may change.

## Pagination

ADO REST APIs use **continuation tokens**, not page numbers:

```python
import requests

def get_all_work_items(org, project, query_id, headers):
    items = []
    url = f"https://dev.azure.com/{org}/{project}/_apis/wit/wiql/{query_id}?api-version=7.1"

    while url:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        items.extend(data.get("workItems", []))

        # Check for continuation token
        continuation = response.headers.get("x-ms-continuationtoken")
        if continuation:
            url = f"{url}&continuationToken={continuation}"
        else:
            url = None

    return items
```

### Pagination Rules

- Default page size varies by endpoint (typically 200 items).
- Use `$top` to control page size: `?$top=100&api-version=7.1`.
- Always check for `x-ms-continuationtoken` header — its absence means last page.
- Some endpoints use `$skip` instead of continuation tokens (e.g., Git refs).

## Throttling (Rate Limits)

ADO applies **per-user, per-org** rate limits using a Token Bucket algorithm.

### Detection

```
HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1620000000
```

### Handling

- **Always** check for `429` responses and respect `Retry-After`.
- Use exponential backoff with jitter when `Retry-After` is absent.
- Monitor `X-RateLimit-Remaining` proactively — back off before hitting zero.
- Batch operations where possible (e.g., update multiple work items in one call).

```csharp
if (response.StatusCode == HttpStatusCode.TooManyRequests)
{
    var retryAfter = response.Headers.RetryAfter?.Delta ?? TimeSpan.FromSeconds(30);
    Log.Warning("ADO rate limit hit. Waiting {Seconds}s", retryAfter.TotalSeconds);
    await Task.Delay(retryAfter);
    // Retry the request
}
```

## Endpoint Taxonomy

### Work Items

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Get work item | GET | `_apis/wit/workitems/{id}` |
| Create work item | POST | `_apis/wit/workitems/$Task` (PATCH body) |
| Update work item | PATCH | `_apis/wit/workitems/{id}` |
| Run WIQL query | POST | `_apis/wit/wiql` |
| Batch get | POST | `_apis/wit/workitemsbatch` |

Work item create/update uses JSON Patch format:

```json
[
  { "op": "add", "path": "/fields/System.Title", "value": "New task" },
  { "op": "add", "path": "/fields/System.State", "value": "Active" }
]
```

### Git / Repos

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List repos | GET | `_apis/git/repositories` |
| Get refs (branches) | GET | `_apis/git/repositories/{repoId}/refs` |
| Create PR | POST | `_apis/git/repositories/{repoId}/pullrequests` |
| Get PR | GET | `_apis/git/repositories/{repoId}/pullrequests/{prId}` |
| Get file contents | GET | `_apis/git/repositories/{repoId}/items?path=/file.txt` |

### Pipelines / Builds

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List pipelines | GET | `_apis/pipelines` |
| Get pipeline run | GET | `_apis/pipelines/{id}/runs/{runId}` |
| Queue run | POST | `_apis/pipelines/{id}/runs` |
| List build definitions | GET | `_apis/build/definitions` |
| Get build logs | GET | `_apis/build/builds/{buildId}/logs` |

### Artifacts / Packages

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List feeds | GET | `_apis/packaging/feeds` |
| List packages | GET | `_apis/packaging/feeds/{feedId}/packages` |
| Get package versions | GET | `_apis/packaging/feeds/{feedId}/packages/{packageId}/versions` |

## Common Pitfalls

- **Missing Content-Type**: work item PATCH requires `Content-Type: application/json-patch+json`, not `application/json`.
- **URL encoding**: project names with spaces need URL encoding (`My%20Project`).
- **Org vs collection URL**: ADO Services uses `dev.azure.com/{org}`, Server uses `{server}/{collection}`.
- **WIQL limits**: WIQL returns max 20,000 work item IDs — use `$top` and paging for larger sets.
- **Batch limits**: `workitemsbatch` accepts max 200 IDs per request.

## Review Lens

- Is `api-version` specified on every request?
- Are PAT scopes the minimum required for the task?
- Is pagination handled (continuation tokens checked)?
- Are 429 responses handled with proper backoff?
- Is the correct Content-Type used for PATCH operations?
