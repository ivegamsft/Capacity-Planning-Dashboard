# Investigation: Managed Identity RBAC Scope — Placement Scores

**Issue:** #6  
**Status:** Workaround in place (subscription-level assignments)  
**Affected component:** `functions/CapacityWorker/shared/Get-AzVMAvailability/AzVMAvailability/Private/Azure/Get-PlacementScores.ps1`

---

## Symptom

The worker managed identity has `Compute Recommendations Role` (role definition ID `e82342c9-ac7f-422b-af64-e426d2e12b2d`) assigned at management-group scope via `infra/bicep/modules/worker-management-group-rbac-assignment.bicep`. Despite the role containing `Microsoft.Compute/locations/placementScores/generate/action`, calls to `Invoke-AzSpotPlacementScore` fail with HTTP 403 when the identity's only assignment is at MG scope.

**Workaround:** Assigning the same role directly at subscription scope resolves the 403. `scripts/grant-quota-rbac.ps1` provides bulk subscription-scope assignment across all subscriptions under the MG.

---

## Root Cause Analysis

### Primary cause — Custom role `assignableScopes` mismatch

The Bicep assigns the role at `managementGroup()` scope (line 33 of `worker-management-group-rbac-assignment.bicep`). However, **Azure RBAC requires the role definition's `assignableScopes` to include the scope at which it is being assigned**. If the `Compute Recommendations Role` definition was originally created with `assignableScopes` restricted to one or more subscription paths (e.g., `/subscriptions/<id>`), then:

- The Bicep `roleAssignment` resource will deploy without error (ARM accepts the assignment).
- The authorization evaluation at request time will fail because the effective scope of the definition does not cover the MG.
- The 403 is returned by the Compute RP, not by ARM RBAC validation at deploy time.

**To verify:** Run `az role definition list --name "Compute Recommendations Role" --query "[].assignableScopes"`. If the output contains only subscription paths (not `/providers/Microsoft.Management/managementGroups/<id>` or `/`), this is confirmed as the root cause.

### Secondary cause — Data-plane action evaluated at subscription scope

`Microsoft.Compute/locations/placementScores/generate/action` is invoked via the ARM path:

```
POST https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Compute/locations/{location}/placementScores/spot/generate
```

The authorization check for this path resolves the identity's effective permissions **rooted at the subscription**, not at the management group. While control-plane RBAC (e.g., `Microsoft.Compute/virtualMachines/read`) reliably inherits from MG assignments, certain data-plane-adjacent actions on the Compute RP go through a registration-aware code path that resolves permissions at the subscription level only. MG assignments are not always included in that traversal.

This is a documented Azure limitation for some Compute data-plane actions and explains why the same role works at subscription scope but not at MG scope.

### Contributing factor — ARM provider registration

`Microsoft.Compute` must be registered in each subscription under the management group for placement score calls to succeed. A subscription where the provider is not registered will return a different error (400/404), but an unregistered subscription in the batch can surface as a 403 if the Compute RP validation pre-checks registration before evaluating the role assignment.

---

## Recommended Fix

### Option A — Update `assignableScopes` to include the management group (preferred long-term)

```powershell
# Get the current role definition
$roleDef = Get-AzRoleDefinition -Name "Compute Recommendations Role"

# Add the management group to assignableScopes
$mgScope = "/providers/Microsoft.Management/managementGroups/<your-mg-name>"
if ($roleDef.AssignableScopes -notcontains $mgScope) {
    $roleDef.AssignableScopes.Add($mgScope)
    Set-AzRoleDefinition -Role $roleDef
}
```

After updating `assignableScopes`:
1. Delete and re-create the MG-scope role assignment (updates to existing assignments are not required — the definition change applies automatically).
2. Wait up to 5 minutes for authorization cache propagation.
3. Re-test `Invoke-AzSpotPlacementScore` from the worker.

### Option B — Keep subscription-scope assignments (current workaround)

Use `scripts/grant-quota-rbac.ps1` to assign at each subscription scope under the MG:

```powershell
.\scripts\grant-quota-rbac.ps1 `
    -PrincipalObjectId "<worker-mi-object-id>" `
    -ManagementGroupId "<mg-name>" `
    -WhatIf   # remove -WhatIf to apply
```

This is stable and resilient. The only maintenance burden is running the script again when new subscriptions are added under the MG.

### Option C — Assign a built-in role that includes the action at MG scope

The built-in **Contributor** role covers `Microsoft.Compute/locations/placementScores/generate/action` and its `assignableScopes` always includes `/` (root). However, Contributor is overly broad. A narrower option is to check whether the built-in **VM Contributor** or a future Compute-specific built-in role includes the placement scores action — if so, that role can be assigned at MG scope without the `assignableScopes` gap.

---

## Current Workaround (Intentional)

Subscription-level assignment is the current deployed state. The Bicep MG-scope assignment (`infra/bicep/modules/worker-management-group-rbac-assignment.bicep`) remains in place to be activated once Option A is verified, but has no effect until `assignableScopes` is updated.

`scripts/grant-quota-rbac.ps1` manages the subscription-scope assignments. Run it:
- After initial deployment
- Whenever a new subscription is added under the management group
- As part of the release verification checklist (see `docs/runbooks/release-verification.md`)

---

## Verification Steps

1. Confirm `assignableScopes` on the role definition:
   ```powershell
   az role definition list --name "Compute Recommendations Role" --query "[0].assignableScopes" -o json
   ```

2. Confirm subscription-scope assignment exists for the worker MI:
   ```powershell
   az role assignment list --assignee "<worker-mi-object-id>" --query "[?roleDefinitionName=='Compute Recommendations Role']" -o table
   ```

3. Confirm `Microsoft.Compute` is registered in each target subscription:
   ```powershell
   az provider show --namespace Microsoft.Compute --subscription "<sub-id>" --query "registrationState" -o tsv
   ```

4. Test placement score call (from within the worker or via `Connect-AzAccount -Identity`):
   ```powershell
   Invoke-AzSpotPlacementScore -Location "eastus" -Sku "Standard_D4s_v5" -DesiredCount 1
   ```

---

## References

- `infra/bicep/modules/worker-management-group-rbac-assignment.bicep` — Bicep MG-scope assignment
- `infra/bicep/modules/worker-management-group-rbac.bicep` — Tenant-scope wrapper
- `scripts/grant-quota-rbac.ps1` — Bulk subscription-scope assignment script
- `functions/CapacityWorker/shared/Get-AzVMAvailability/AzVMAvailability/Private/Azure/Get-PlacementScores.ps1` — Caller; catches 403 and emits a warning without failing the scan
- [Azure RBAC assignable scopes](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-definitions#assignablescopes)
- [Management group RBAC inheritance limitations](https://learn.microsoft.com/en-us/azure/governance/management-groups/overview#azure-custom-role-definition-and-assignment)
