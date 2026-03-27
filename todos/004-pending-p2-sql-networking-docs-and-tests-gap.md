---
status: pending
priority: p2
issue_id: 004
tags: [code-review, documentation, testing, sql]
dependencies: [002]
---

# SQL Networking Docs And Tests Gap

## Problem Statement

The new SQL public and private access control was added without matching documentation or test coverage. That makes the broken deployment combination easier to miss and leaves consumers without a working private-only reference.

## Findings

- `variables.tf:238` defines `sql_public_network_access`.
- The generated inputs section in `README.md` jumps from `sql_database_sku` to `sql_server_name` between `README.md:280` and `README.md:294`; the new variable is absent.
- `terraform.tfvars.example` documents `enable_private_endpoints` and Key Vault options but omits `sql_public_network_access`.
- `examples/complete/main.tf:53` enables private endpoints but does not show the corresponding SQL public-access choice.
- `tests/default.tftest.hcl:6` and `tests/complete.tftest.hcl:13` are plan smoke tests only and do not exercise the new SQL access-mode matrix.

## Proposed Solutions

### Option 1

Regenerate module docs, update `terraform.tfvars.example`, and add at least one test or example covering the intended private-only or public-plus-private behavior.

Pros: Aligns docs and tests with actual behavior.
Cons: Slightly wider change set.
Effort: Medium
Risk: Low

### Option 2

Document the limitation only and defer tests.

Pros: Quick.
Cons: Leaves the regression surface largely unguarded.
Effort: Small
Risk: Medium

## Recommended Action

TBD during triage.

## Technical Details

Affected components:

- Generated documentation
- Example configurations
- Terraform test coverage

## Acceptance Criteria

- `README.md` includes `sql_public_network_access` with accurate guidance.
- `terraform.tfvars.example` shows how to configure SQL public and private access.
- At least one example or test covers the chosen SQL connectivity pattern.

## Work Log

- 2026-03-26: Review found the new SQL networking option missing from docs and untested in the current suite.

## Resources

- Branch under review: `feature/azapi-migration`
- Relevant files: `variables.tf`, `README.md`, `terraform.tfvars.example`, `examples/complete/main.tf`, `tests/default.tftest.hcl`, `tests/complete.tftest.hcl`
