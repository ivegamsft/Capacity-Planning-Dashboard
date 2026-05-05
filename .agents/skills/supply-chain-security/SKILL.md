---
name: supply-chain-security
title: Supply Chain Security - SLSA, SBOM, Sigstore
description: Artifact signing, SBOM generation, provenance tracking, and vulnerability scanning
compatibility: ["agent:supply-chain-security"]
metadata:
  domain: security
  maturity: production
  audience: [devops-engineer, security-engineer, release-manager]
allowed-tools: [bash, python, docker, kubernetes]
---

# Supply Chain Security Skill

Comprehensive patterns for securing software supply chains through artifact signing, SBOM generation, and SLSA framework implementation.

## Artifact Signing with Sigstore

```bash
#!/bin/bash
# Sign and verify container images with Cosign

IMAGE="registry.example.com/my-app:v1.0.0"

# 1. Generate keypair (or use ambient OIDC)
cosign generate-key-pair

# 2. Build and push image
docker build -t "$IMAGE" .
docker push "$IMAGE"

# 3. Sign with private key
cosign sign --key cosign.key "$IMAGE"

# 4. Verify signature
cosign verify --key cosign.pub "$IMAGE"

# 5. Attach SBOM to image
syft "$IMAGE" -o json | cosign attach sbom --sbom - "$IMAGE"

# 6. Verify SBOM
cosign tree "$IMAGE"
```

## SBOM Generation (CycloneDX/SPDX)

```bash
#!/bin/bash
# Generate Software Bill of Materials

APP_IMAGE="my-app:latest"
OUTPUT_DIR="sbom"

mkdir -p "$OUTPUT_DIR"

# 1. Generate SBOM using Syft
syft "$APP_IMAGE" \
  -o cyclonedx-json \
  > "$OUTPUT_DIR/cyclonedx.json"

# 2. Generate SPDX format
syft "$APP_IMAGE" \
  -o spdx-json \
  > "$OUTPUT_DIR/spdx.json"

# 3. Scan for vulnerabilities in SBOM
grype "$APP_IMAGE" \
  --output json \
  > "$OUTPUT_DIR/vulnerabilities.json"

# 4. Validate SBOM structure
jq '.' "$OUTPUT_DIR/cyclonedx.json" > /dev/null || exit 1
```

## SLSA Level 2/3 Implementation

```yaml
# GitHub Actions - SLSA L3 Provenance
name: SLSA Build & Release

on:
  push:
    tags:
      - v*

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      hashes: ${{ steps.hash.outputs.hashes }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Build artifact
        run: |
          mkdir artifacts
          go build -o artifacts/my-app .
          sha256sum artifacts/* > artifacts/hashes.txt
      
      - id: hash
        run: |
          echo "hashes=$(cat artifacts/hashes.txt | base64 -w0)" >> $GITHUB_OUTPUT
      
      - uses: actions/upload-artifact@v3
        with:
          name: artifacts
          path: artifacts/

  provenance:
    needs: build
    permissions:
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v1.7.0
    with:
      base64-subjects: ${{ needs.build.outputs.hashes }}
      upload-assets: true
```

## Dependency Vulnerability Scanning

```python
import subprocess
import json

def scan_python_deps(requirements_file):
    """Scan Python dependencies with pip-audit."""
    result = subprocess.run(
        ["pip-audit", "--desc", "--format", "json", "--requirements", requirements_file],
        capture_output=True, text=True
    )
    vulnerabilities = json.loads(result.stdout)
    
    critical = [v for v in vulnerabilities if v['severity'] == 'critical']
    if critical:
        print(f"CRITICAL: Found {len(critical)} critical vulnerabilities")
        return False
    return True

def scan_container(image):
    """Scan container image with Trivy."""
    result = subprocess.run(
        ["trivy", "image", "--format", "json", image],
        capture_output=True, text=True
    )
    results = json.loads(result.stdout)
    
    total_vulns = sum(len(r.get('Results', [])) for r in results.get('Results', []))
    print(f"Container vulnerabilities: {total_vulns}")
    return total_vulns == 0
```

---

## References

- [SLSA Framework](https://slsa.dev/)
- [Sigstore Documentation](https://docs.sigstore.dev/)
- [CycloneDX SBOM](https://cyclonedx.org/)
- [SPDX Specification](https://spdx.dev/)
