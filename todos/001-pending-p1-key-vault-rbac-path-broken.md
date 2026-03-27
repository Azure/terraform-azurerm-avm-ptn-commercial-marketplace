---
status: pending
priority: p1
issue_id: 001
tags: [code-review, security, reliability, key-vault, rbac]
dependencies: []
---

# Key Vault RBAC Path Broken

## Problem Statement

The RBAC-enabled Key Vault path is not functional. When `key_vault_enable_rbac = true`, the configuration disables legacy access policies but never creates equivalent Azure RBAC role assignments for either the deployer principal or the web app managed identities.

## Findings

- `keyvault.tf:23` sets `legacy_access_policies_enabled = !var.key_vault_enable_rbac`.
- `keyvault.tf:49`, `keyvault.tf:63`, and `keyvault.tf:73` create access policies only when RBAC is disabled.
- There are no `azurerm_role_assignment` resources anywhere in the module for Key Vault data-plane access.
- `examples/complete/main.tf:58` enables `key_vault_enable_rbac = true`, so the shipped complete example selects the broken path.
- `keyvault.tf:85` and `keyvault.tf:94` still attempt to write secrets into the vault, and both web apps reference those secrets at runtime from `appservice.tf:52`, `appservice.tf:63`, `appservice.tf:108`, and `appservice.tf:118`.

## Proposed Solutions

### Option 1

Add Key Vault RBAC role assignments when `key_vault_enable_rbac = true`.

Pros: Fixes the feature as documented; keeps RBAC support.
Cons: Requires choosing the minimal correct roles for deployer and app identities.
Effort: Medium
Risk: Medium

### Option 2

Temporarily force legacy access policies until RBAC wiring is implemented.

Pros: Low-effort unblock.
Cons: Regresses the intended security model and leaves the example misleading.
Effort: Small
Risk: Medium

### Option 3

Disable the RBAC example path and document RBAC as unsupported for now.

Pros: Honest behavior for consumers.
Cons: Removes a desirable feature.
Effort: Small
Risk: Low

## Recommended Action

TBD during triage.

## Technical Details

Affected components:

- Key Vault module configuration
- Secret provisioning during apply
- Web app Key Vault references
- Complete example

## Acceptance Criteria

- `key_vault_enable_rbac = true` succeeds in plan/apply for the complete example.
- The deployer can create both Key Vault secrets without legacy access policies.
- Both web app managed identities can resolve the referenced secrets at runtime.
- The RBAC roles granted are least-privilege and documented.

## Work Log

- 2026-03-26: Review identified that the RBAC path removes access policies but adds no RBAC replacements.

## Resources

- Branch under review: `feature/azapi-migration`
- Relevant files: `keyvault.tf`, `appservice.tf`, `examples/complete/main.tf`
