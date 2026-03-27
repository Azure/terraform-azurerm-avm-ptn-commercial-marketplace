---
status: pending
priority: p2
issue_id: 003
tags: [code-review, validation, app-service, usability]
dependencies: []
---

# App Service Zone Balancing Validation

## Problem Statement

`app_service_zone_balancing` is documented as requiring a Premium or Isolated SKU and at least three workers, but the module does not validate those prerequisites. Invalid combinations fail late in Azure rather than early in Terraform.

## Findings

- `variables.tf:129` defines `app_service_zone_balancing`.
- `variables.tf:132` documents the constraints.
- `variables.tf:117` already validates the SKU enum, but there is no cross-variable validation for zone balancing.
- `appservice.tf:20` passes `var.app_service_zone_balancing` straight into the AVM App Service Plan module.
- `variables.tf:123` leaves `app_service_worker_count` unconstrained at the module boundary.

## Proposed Solutions

### Option 1

Add validation on `app_service_zone_balancing` and or `app_service_worker_count` to enforce compatible SKU and `worker_count >= 3`.

Pros: Fast, clear feedback to users.
Cons: Validation logic is slightly verbose.
Effort: Small
Risk: Low

### Option 2

Document the constraint only.

Pros: Minimal code change.
Cons: Still fails late and opaquely.
Effort: Small
Risk: Medium

## Recommended Action

TBD during triage.

## Technical Details

Affected components:

- Input validation
- App Service Plan provisioning path

## Acceptance Criteria

- Invalid zone-balancing combinations fail at `terraform validate` or `terraform plan` with a clear message.
- Valid Premium or Isolated configurations with three or more workers still pass.

## Work Log

- 2026-03-26: Review found that the constraint is documented but not enforced.

## Resources

- Branch under review: `feature/azapi-migration`
- Relevant files: `variables.tf`, `appservice.tf`
