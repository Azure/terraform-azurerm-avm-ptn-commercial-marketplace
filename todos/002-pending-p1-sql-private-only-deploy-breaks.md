---
status: pending
priority: p1
issue_id: 002
tags: [code-review, reliability, deployment, sql, networking]
dependencies: []
---

# SQL Private-Only Deploy Breaks

## Problem Statement

The module exposes a `sql_public_network_access` switch but the application deployment and migration flow still assumes SQL is reachable over the public endpoint with firewall rules. This makes a private-endpoints-only configuration fail during `terraform apply`.

## Findings

- `variables.tf:238` introduces `sql_public_network_access` and documents turning it off for private-endpoints-only use.
- `sql.tf:26` wires that variable into `public_network_access_enabled` on the SQL server.
- `deploy.tf:115` hard-codes the migration connection string to `local.sql_connection_string_public`.
- `deploy.tf:129` through `deploy.tf:152` creates a temporary SQL firewall rule for the caller IP before running migrations.
- `deploy.tf:164` and `deploy.tf:171` execute `sqlcmd` against the public server FQDN.
- There is no validation blocking `deploy_app_code = true` with `sql_public_network_access = false`.

## Proposed Solutions

### Option 1

Add variable validation that rejects `deploy_app_code = true && sql_public_network_access = false`.

Pros: Prevents a broken apply immediately.
Cons: Keeps private-only deployment unsupported.
Effort: Small
Risk: Low

### Option 2

Teach the deploy step to use private connectivity when private endpoints are enabled.

Pros: Supports the documented private-only scenario.
Cons: More moving parts for local execution and operator environment.
Effort: Large
Risk: Medium

### Option 3

Split infrastructure provisioning and app/database deployment more clearly and require infra-only mode for private-only SQL.

Pros: Operationally clear.
Cons: Still a workflow change for users.
Effort: Medium
Risk: Low

## Recommended Action

TBD during triage.

## Technical Details

Affected components:

- SQL server network exposure toggle
- Local-exec migration workflow
- App deployment path

## Acceptance Criteria

- Invalid combinations are rejected before apply, or the deployment flow supports them correctly.
- Private-endpoints-only SQL is either fully supported or clearly documented as infra-only.
- Tests cover the chosen behavior.

## Work Log

- 2026-03-26: Review confirmed a mismatch between SQL network configuration and the migration-deploy implementation.

## Resources

- Branch under review: `feature/azapi-migration`
- Relevant files: `variables.tf`, `sql.tf`, `deploy.tf`
