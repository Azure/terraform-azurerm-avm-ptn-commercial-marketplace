# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Application Code Build & Deployment (via null_resource + local-exec)
#
# These resources are gated by var.deploy_app_code (default: true).
# Set deploy_app_code = false to provision infrastructure only.
#
# NOTE: This is a pattern-module convenience for deploying the .NET application.
# For production CI/CD pipelines, set deploy_app_code = false and use
# GitHub Actions, Azure DevOps, or another deployment tool.
#
# Execution order:
#   1. build_app          — dotnet publish all three projects
#   2. package_app        — zip the publish outputs
#   3. deploy_database    — EF Core migration + managed identity SQL grants
#   4. deploy_admin_app   — az webapp deploy (Admin Portal)
#   5. deploy_portal_app  — az webapp deploy (Customer Portal)
#   6. cleanup_publish    — remove temporary build artifacts
# ==============================================================================

# ==============================================================================
# 1. Build — dotnet publish all .NET projects
# ==============================================================================

resource "null_resource" "build_app" {
  count = var.deploy_app_code ? 1 : 0

  triggers = {
    src_hash = sha1(join("", [
      fileexists("${local.src_dir}/AdminSite/AdminSite.csproj") ? filesha1("${local.src_dir}/AdminSite/AdminSite.csproj") : "na",
      fileexists("${local.src_dir}/CustomerSite/CustomerSite.csproj") ? filesha1("${local.src_dir}/CustomerSite/CustomerSite.csproj") : "na",
      fileexists("${local.src_dir}/MeteredTriggerJob/MeteredTriggerJob.csproj") ? filesha1("${local.src_dir}/MeteredTriggerJob/MeteredTriggerJob.csproj") : "na",
      fileexists("${local.src_dir}/Services/Services.csproj") ? filesha1("${local.src_dir}/Services/Services.csproj") : "na",
      fileexists("${local.src_dir}/DataAccess/DataAccess.csproj") ? filesha1("${local.src_dir}/DataAccess/DataAccess.csproj") : "na",
    ]))
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e

      if ! dotnet --list-sdks | grep -q '^8\.'; then
        echo "Missing .NET 8 SDK (required by global.json)."
        echo "Install .NET SDK 8.0.303 (or compatible 8.x), then re-run terraform apply."
        echo "If you want infra only, run: terraform apply -var='deploy_app_code=false'"
        exit 1
      fi

      echo "==> Building Admin Site..."
      dotnet publish "${local.src_dir}/AdminSite/AdminSite.csproj" \
        -c release -o "${path.module}/.publish/AdminSite/" -v q

      echo "==> Building Metered Trigger Job..."
      dotnet publish "${local.src_dir}/MeteredTriggerJob/MeteredTriggerJob.csproj" \
        -c release \
        -o "${path.module}/.publish/AdminSite/app_data/jobs/triggered/MeteredTriggerJob/" \
        -v q --runtime win-x64 --self-contained true

      echo "==> Building Customer Site..."
      dotnet publish "${local.src_dir}/CustomerSite/CustomerSite.csproj" \
        -c release -o "${path.module}/.publish/CustomerSite/" -v q

      echo "==> Build complete."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# ==============================================================================
# 2. Package — Zip the publish outputs
# ==============================================================================

resource "null_resource" "package_app" {
  count = var.deploy_app_code ? 1 : 0

  triggers = {
    build_id = null_resource.build_app[0].id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      cd "${path.module}/.publish"

      echo "==> Packaging Admin Site..."
      rm -f AdminSite.zip
      cd AdminSite && zip -r ../AdminSite.zip . -q && cd ..

      echo "==> Packaging Customer Site..."
      rm -f CustomerSite.zip
      cd CustomerSite && zip -r ../CustomerSite.zip . -q && cd ..

      echo "==> Packaging complete."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [null_resource.build_app]
}

# ==============================================================================
# 3. Database Migration — EF Core migrations + Managed Identity SQL grants
# ==============================================================================

resource "null_resource" "deploy_database" {
  count = var.deploy_app_code ? 1 : 0

  triggers = {
    build_id    = null_resource.build_app[0].id
    db_id       = module.sql_server.resource_databases["saas_db"].resource_id
    server_fqdn = module.sql_server.resource.fully_qualified_domain_name
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      CONNECTION_STRING="${local.sql_connection_string_public}"
      MIGRATION_FW_RULE="AllowTerraformMigration"

      if [ -n "${var.allowed_client_ip}" ]; then
        CLIENT_IP="${var.allowed_client_ip}"
      else
        CLIENT_IP="$(curl -s https://api.ipify.org)"
      fi

      if [ -z "$CLIENT_IP" ]; then
        echo "Unable to determine client IP for SQL migration firewall rule."
        exit 1
      fi

      echo "==> Creating temporary SQL firewall rule for migration ($CLIENT_IP)..."
      az sql server firewall-rule create \
        --resource-group "${azurerm_resource_group.this.name}" \
        --server "${local.sql_server_name}" \
        --name "$MIGRATION_FW_RULE" \
        --start-ip-address "$CLIENT_IP" \
        --end-ip-address "$CLIENT_IP" \
        --output none

      cleanup_firewall_rule() {
        echo "==> Removing temporary SQL firewall rule..."
        az sql server firewall-rule delete \
          --resource-group "${azurerm_resource_group.this.name}" \
          --server "${local.sql_server_name}" \
          --name "$MIGRATION_FW_RULE" \
          --yes \
          --output none || true
      }

      trap cleanup_firewall_rule EXIT

      echo "==> Generating EF Core migration script..."

      cat > "${local.src_dir}/AdminSite/appsettings.Development.json" <<APPSETTINGS
      {"ConnectionStrings": {"DefaultConnection": "$CONNECTION_STRING"}}
APPSETTINGS

      dotnet-ef migrations script \
        --output "${path.module}/.publish/migration.sql" \
        --idempotent \
        --context SaaSKitContext \
        --project "${local.src_dir}/DataAccess/DataAccess.csproj" \
        --startup-project "${local.src_dir}/AdminSite/AdminSite.csproj"

      echo "==> Applying EF Core migration to database..."
      sqlcmd \
        -i "${path.module}/.publish/migration.sql" \
        -S "${module.sql_server.resource.fully_qualified_domain_name}" \
        -d "${local.sql_database_name}" \
        --authentication-method=ActiveDirectoryDefault \
        -C

      echo "==> Granting database access to web app managed identities..."
      sqlcmd \
        -S "${module.sql_server.resource.fully_qualified_domain_name}" \
        -d "${local.sql_database_name}" \
        --authentication-method=ActiveDirectoryDefault \
        -C \
        -Q "
          IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${local.webapp_admin_name}')
          BEGIN
            CREATE USER [${local.webapp_admin_name}] FROM EXTERNAL PROVIDER;
          END;

          IF NOT EXISTS (
            SELECT 1
            FROM sys.database_role_members drm
            INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
            INNER JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
            WHERE r.name = 'db_datareader' AND m.name = '${local.webapp_admin_name}'
          )
          BEGIN
            ALTER ROLE db_datareader ADD MEMBER [${local.webapp_admin_name}];
          END;

          IF NOT EXISTS (
            SELECT 1
            FROM sys.database_role_members drm
            INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
            INNER JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
            WHERE r.name = 'db_datawriter' AND m.name = '${local.webapp_admin_name}'
          )
          BEGIN
            ALTER ROLE db_datawriter ADD MEMBER [${local.webapp_admin_name}];
          END;

          GRANT EXEC TO [${local.webapp_admin_name}];

          IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${local.webapp_portal_name}')
          BEGIN
            CREATE USER [${local.webapp_portal_name}] FROM EXTERNAL PROVIDER;
          END;

          IF NOT EXISTS (
            SELECT 1
            FROM sys.database_role_members drm
            INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
            INNER JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
            WHERE r.name = 'db_datareader' AND m.name = '${local.webapp_portal_name}'
          )
          BEGIN
            ALTER ROLE db_datareader ADD MEMBER [${local.webapp_portal_name}];
          END;

          IF NOT EXISTS (
            SELECT 1
            FROM sys.database_role_members drm
            INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
            INNER JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
            WHERE r.name = 'db_datawriter' AND m.name = '${local.webapp_portal_name}'
          )
          BEGIN
            ALTER ROLE db_datawriter ADD MEMBER [${local.webapp_portal_name}];
          END;

          GRANT EXEC TO [${local.webapp_portal_name}];
        "

      # Clean up temporary files
      rm -f "${local.src_dir}/AdminSite/appsettings.Development.json"
      rm -f "${path.module}/.publish/migration.sql"

      echo "==> Database migration complete."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.build_app,
    module.sql_server,
    module.webapp_admin,
    module.webapp_portal,
  ]
}

# ==============================================================================
# 4. Deploy Admin Portal — az webapp deploy
# ==============================================================================

resource "null_resource" "deploy_admin_app" {
  count = var.deploy_app_code ? 1 : 0

  triggers = {
    package_id = null_resource.package_app[0].id
    webapp_id  = module.webapp_admin.resource_id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "==> Deploying Admin Portal to ${local.webapp_admin_name}..."
      az webapp deploy \
        --resource-group "${azurerm_resource_group.this.name}" \
        --name "${local.webapp_admin_name}" \
        --src-path "${path.module}/.publish/AdminSite.zip" \
        --type zip \
        --output none

      echo "==> Admin Portal deployment complete."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.package_app,
    null_resource.deploy_database,
    module.webapp_admin,
    module.key_vault,
  ]
}

# ==============================================================================
# 5. Deploy Customer Portal — az webapp deploy
# ==============================================================================

resource "null_resource" "deploy_portal_app" {
  count = var.deploy_app_code ? 1 : 0

  triggers = {
    package_id = null_resource.package_app[0].id
    webapp_id  = module.webapp_portal.resource_id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "==> Deploying Customer Portal to ${local.webapp_portal_name}..."
      az webapp deploy \
        --resource-group "${azurerm_resource_group.this.name}" \
        --name "${local.webapp_portal_name}" \
        --src-path "${path.module}/.publish/CustomerSite.zip" \
        --type zip \
        --output none

      echo "==> Customer Portal deployment complete."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.package_app,
    null_resource.deploy_database,
    module.webapp_portal,
    module.key_vault,
  ]
}

# ==============================================================================
# 6. Cleanup — Remove publish artifacts after deployment
# ==============================================================================

resource "null_resource" "cleanup_publish" {
  count = var.deploy_app_code ? 1 : 0

  triggers = {
    admin_deploy_id  = null_resource.deploy_admin_app[0].id
    portal_deploy_id = null_resource.deploy_portal_app[0].id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "==> Cleaning up publish artifacts..."
      rm -rf "${path.module}/.publish"
      echo "==> Cleanup complete."
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    null_resource.deploy_admin_app,
    null_resource.deploy_portal_app,
  ]
}
