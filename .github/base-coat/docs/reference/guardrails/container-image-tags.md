# Guardrail: Container Image Tags Must Include Git SHA

## Rule

Every container image pushed from CI/CD **must** be tagged with the full git commit SHA.
Tagging only with `:latest` is **forbidden**.

## Why

| Reason | Detail |
|---|---|
| **Reproducible deployments** | A SHA tag pins a deployment to an exact commit, eliminating "works on my machine" drift. |
| **Rollback capability** | Rolling back means redeploying a known SHA — no guesswork about what `:latest` pointed to yesterday. |
| **Audit trail** | Security and compliance reviews can trace any running container back to the source commit that produced it. |

## Pattern

In GitHub Actions, set `IMAGE_TAG` in the workflow `env` block:

```yaml
env:
  IMAGE_TAG: ${{ github.sha }}
steps:
  - run: docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE }}:${{ env.IMAGE_TAG }} .
  - run: docker push ${{ env.REGISTRY }}/${{ env.IMAGE }}:${{ env.IMAGE_TAG }}
```

### Optional: Also tag with `:latest`

You **may** additionally push a `:latest` tag for convenience (e.g., local dev pulls), but the SHA tag is always mandatory:

```yaml
steps:
  - run: |
      docker tag ${{ env.REGISTRY }}/${{ env.IMAGE }}:${{ env.IMAGE_TAG }} \
                 ${{ env.REGISTRY }}/${{ env.IMAGE }}:latest
      docker push ${{ env.REGISTRY }}/${{ env.IMAGE }}:latest
```

## How to Verify

**Docker CLI:**

```bash
docker inspect <image>:<sha> --format '{{ index .RepoTags }}'
```

**Azure Container Registry:**

```bash
az acr repository show-tags --name <registry> --repository <image> --output table
```

Confirm the SHA tag appears in the tag list alongside any convenience tags.

## Enforcement

- All workflow PRs are reviewed against this guardrail.
- If a workflow pushes a container image without a SHA tag, the PR must be blocked until corrected.
