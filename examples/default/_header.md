# Default Example

This deploys the SaaS Accelerator with minimal required inputs plus a few developer-friendly overrides:

- A random prefix is generated to avoid naming collisions.
- AAD app registrations are created automatically.
- App Service SKU is set to `S1`.
- Key Vault network default action is set to `Allow`.
- Infrastructure-only mode is enabled (`deploy_app_code = false`).
