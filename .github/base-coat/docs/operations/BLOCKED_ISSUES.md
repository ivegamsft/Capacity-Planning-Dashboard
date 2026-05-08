---
description: Tracking for known limitations and prerequisites for certain features.
---

# Known Limitations & Blocked Issues

## Blocked by External Constraints

### #283: GitHub API Per-Model Premium Billing Data

**Status:** WONTFIX (API Limitation)

**Description:** GitHub API does not expose per-model premium billing breakdown. This data is only available through the GitHub web UI's billing dashboard.

**Why It's Blocked:**
- GitHub REST API v3 and GraphQL API do not include granular billing data per model
- Enterprise billing aggregation only available via web UI

**Workaround:**
- Navigate to: GitHub Settings → Billing and plans → Usage metrics
- Export billing data manually from web dashboard
- Use Azure Cost Management for Azure OpenAI consumption instead

**Related:** Model optimization discussions require this data (see docs/MODEL_OPTIMIZATION.md)

---

### #282: Copilot Usage Metrics Policy Configuration

**Status:** BLOCKED (Enterprise Admin Gate)

**Description:** Enterprise admin must enable "Copilot usage metrics" policy in GitHub Enterprise settings before any usage data collection.

**Why It's Blocked:**
- Only enterprise admins have permission to enable this policy
- Feature requires GitHub Enterprise Cloud subscription
- Organization-level settings insufficient (enterprise scope required)

**Prerequisite Actions:**
1. Contact your GitHub Enterprise admin
2. Navigate to GitHub Enterprise settings → "Code security and analysis"
3. Enable "Copilot usage metrics collection"
4. Wait 24-48 hours for data pipeline initialization

**Then Available:**
- Organization-level Copilot usage reports
- Per-seat metrics (active users, chats, completions)
- Model adoption trends

**Documentation:** See `docs/COPILOT_METRICS_SETUP.md` for post-enablement configuration.

---

## Design Limitations

### Skill Refactoring (>5KB Files) — Phase 2 #330

**Status:** IN PROGRESS

**Challenge:** Large skills (15-20KB) are difficult to navigate in editor UIs.

**Solution:** Modular pattern with `references/` subdirectory

**Example:** `skills/security-operations/SKILL.md` split into:
```
skills/security-operations/
  ├─ SKILL.md (overview, 5KB)
  ├─ references/
  │  ├─ threat-detection.md (5KB)
  │  ├─ incident-response.md (4KB)
  │  ├─ secrets-rotation.md (2KB)
  │  └─ audit-logging.md (2KB)
```

**Why Needed:**
- IDEs (VS Code, etc) show previews up to ~5KB
- Documentation sites render better below 10KB per page
- Cognitive load reduced with focused, single-topic files

**Next Steps:**
- Identify all skills >5KB
- Apply modular refactoring pattern
- Update main SKILL.md with navigation links
- Update related agents' `allowed-tools` references

---

## Enterprise Prerequisites

### Copilot Usage Metrics

**Requires:**
- ✅ GitHub Enterprise Cloud subscription
- ⏳ Enterprise admin enablement (external action)
- ⏳ 24-48h activation period
- ⏳ Permissions: `admin:enterprise` scope

**Post-Enablement:**
- Organization usage dashboard available
- Per-seat active user tracking
- Model adoption metrics
- Cost per seat reporting

---

## Workarounds & Alternatives

| Blocked Feature | Workaround | Alternative |
|---|---|---|
| GitHub API per-model billing | Manual export from web UI | Azure Cost Analysis for Azure OpenAI models |
| Copilot metrics collection | Enable enterprise policy (admin action) | GitHub API audit logs (`GET /repos/{owner}/{repo}/audit-log`) |
| Large skill navigation | Modular `references/` pattern | Link to specific reference file in SKILL.md nav |

---

## Issue Resolution Path

### For Blocked Issues
1. **Assess blocker type:** External (API), Enterprise prerequisite, or Design limitation
2. **Document prerequisite:** Link to setup guides or admin actions
3. **Provide workaround:** Offer alternative if available
4. **Label issue:** `blocked`, `prerequisite`, or `wontfix`
5. **Re-evaluate quarterly:** Check if API limitations lifted or enterprise policies updated

### For Design Limitations
1. **Prototype solution:** Create proof-of-concept (e.g., modular skill refactoring)
2. **Test at scale:** Apply to 2-3 large skills before full rollout
3. **Document pattern:** Add to `docs/` for future contributors
4. **Track effort:** Estimate hours needed for full implementation
5. **Prioritize:** Include in next sprint if high-value

---

**Last Updated:** 2026-05-02  
**Reviewed By:** Copilot  
**Next Review:** 2026-06-02
