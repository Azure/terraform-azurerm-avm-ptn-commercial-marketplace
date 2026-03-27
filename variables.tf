# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Required Variables
# ==============================================================================

# ==============================================================================
# Optional Variables — Azure AD / API Configuration
# ==============================================================================

# ==============================================================================
# Optional Variables — Resource Naming Overrides
# ==============================================================================

# ==============================================================================
# Optional Variables — Networking
# ==============================================================================

# ==============================================================================
# Optional Variables — SKUs
# ==============================================================================

# ==============================================================================
# Optional Variables — Key Vault Configuration
# ==============================================================================

# ==============================================================================
# Optional Variables — Application Deployment
# ==============================================================================

# ==============================================================================
# Optional Variables — Tags
# ==============================================================================

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed (e.g., `swedencentral`, `eastus2`)."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]+[a-z0-9]*$", var.location))
    error_message = "Location must be a valid Azure region name in lowercase without spaces (e.g., 'eastus2', 'swedencentral')."
  }
}

variable "publisher_admin_users" {
  type        = string
  description = "Comma-separated list of email addresses granted access to the Publisher Admin Portal (e.g., `user1@contoso.com,user2@contoso.com`)."

  validation {
    condition     = length(var.publisher_admin_users) > 0
    error_message = "At least one publisher admin user email must be provided."
  }
}

variable "webapp_name_prefix" {
  type        = string
  description = "Prefix used for naming all Azure resources. Must be 3-21 characters, start with a letter, and contain only alphanumeric characters and hyphens."

  validation {
    condition     = length(var.webapp_name_prefix) >= 3 && length(var.webapp_name_prefix) <= 21
    error_message = "Web app name prefix must be between 3 and 21 characters."
  }
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]+$", var.webapp_name_prefix))
    error_message = "Web app name prefix must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "ad_application_id" {
  type        = string
  default     = ""
  description = "Existing Fulfillment API App Registration Client ID. If empty, a new App Registration will be created."
}

variable "ad_application_id_admin" {
  type        = string
  default     = ""
  description = "Existing Admin Portal SSO App Registration Client ID. If empty, a new App Registration will be created."
}

variable "ad_application_secret" {
  type        = string
  default     = null
  description = "Client secret for a pre-existing Fulfillment API App Registration. Leave as `null` when this module creates the app registration."
  sensitive   = true

  validation {
    condition     = var.ad_application_id == "" || trimspace(coalesce(var.ad_application_secret, "")) != ""
    error_message = "When `ad_application_id` is provided, `ad_application_secret` must also be provided."
  }
}

variable "ad_mt_application_id_portal" {
  type        = string
  default     = ""
  description = "Existing Landing Page SSO App Registration Client ID. If empty, a new App Registration will be created."
}

variable "allowed_client_ip" {
  type        = string
  default     = ""
  description = "Client public IPv4 address to allow on SQL Server during migration and on Key Vault network ACLs. If empty, the deploy step auto-detects via `api.ipify.org`."

  validation {
    condition     = var.allowed_client_ip == "" || can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\.|$)){4}$", var.allowed_client_ip))
    error_message = "allowed_client_ip must be a valid IPv4 address (e.g., 203.0.113.10) or empty for auto-detection."
  }
}

variable "app_service_sku" {
  type        = string
  default     = "B1"
  description = "SKU for the App Service Plan. Allowed values: `B1`, `B2`, `B3`, `S1`, `S2`, `S3`, `P0v3`, `P1v2`, `P2v2`, `P3v2`, `P1v3`, `P2v3`, `P3v3`, `P0v4`, `P1v4`, `P2v4`, `P3v4`, `P4v4`, `P5v4`."

  validation {
    condition     = contains(["B1", "B2", "B3", "S1", "S2", "S3", "P0v3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3", "P0v4", "P1v4", "P2v4", "P3v4", "P4v4", "P5v4"], var.app_service_sku)
    error_message = "App Service SKU must be one of: B1, B2, B3, S1, S2, S3, P0v3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3, P0v4, P1v4, P2v4, P3v4, P4v4, P5v4."
  }
}

variable "app_service_worker_count" {
  type        = number
  default     = 1
  description = "Number of workers for the App Service Plan. For production workloads, use 3 or more."
}

variable "app_service_zone_balancing" {
  type        = bool
  default     = false
  description = "Enable zone balancing for the App Service Plan. Requires a Premium or Isolated SKU and `app_service_worker_count >= 3`."
}

variable "deploy_app_code" {
  type        = bool
  default     = true
  description = "If `true`, build and deploy the .NET application code as part of `terraform apply`. Set to `false` for infrastructure-only provisioning."
}

variable "enable_private_endpoints" {
  type        = bool
  default     = true
  description = "If `true`, creates private endpoints and private DNS zones for SQL Server and Key Vault. Defaults to `true`."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "is_admin_portal_multi_tenant" {
  type        = bool
  default     = false
  description = "If `true`, the Admin Portal App Registration is configured as multi-tenant. Defaults to single-tenant."
}

variable "key_vault_enable_rbac" {
  type        = bool
  default     = false
  description = "If `true`, enable RBAC authorization on Key Vault (recommended). If `false`, use legacy access policies."
}

variable "key_vault_name" {
  type        = string
  default     = ""
  description = "Name of the Key Vault. Must be globally unique (3-24 chars). Defaults to `<webapp_name_prefix>-kv`."

  validation {
    condition     = var.key_vault_name == "" || (can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name)) && length(var.key_vault_name) <= 24)
    error_message = "Key Vault name must be 3-24 characters, start with a letter, end with a letter or digit, and contain only alphanumeric characters and hyphens."
  }
}

variable "key_vault_network_default_action" {
  type        = string
  default     = "Deny"
  description = "Default action for Key Vault network ACLs. Set to `Allow` during development if your outbound IP cannot be determined. Use `Deny` in production."

  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_default_action)
    error_message = "key_vault_network_default_action must be either 'Allow' or 'Deny'."
  }
}

variable "key_vault_purge_protection" {
  type        = bool
  default     = false
  description = "If `true`, enables purge protection on Key Vault. Recommended for production. Note: once enabled, this cannot be disabled."
}

variable "key_vault_soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "Number of days to retain soft-deleted items in Key Vault. Must be between 7 and 90."

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "Name of the resource group. Defaults to the value of `webapp_name_prefix`."
}

variable "sql_admin_login_username" {
  type        = string
  default     = null
  description = "Display name for the SQL Server Entra ID administrator. If null, defaults to the caller's object ID. Set this when deploying with a service principal."
}

variable "sql_database_name" {
  type        = string
  default     = ""
  description = "Name of the SQL Database. Defaults to `<webapp_name_prefix>AMPSaaSDB`."
}

variable "sql_database_sku" {
  type        = string
  default     = "S0"
  description = "SKU name for the Azure SQL Database (e.g., `S0`, `S1`, `S2`, `GP_Gen5_2`)."

  validation {
    condition     = can(regex("^(Basic|S[0-9]|P[0-9]+|GP_Gen[0-9]+_[0-9]+|BC_Gen[0-9]+_[0-9]+|HS_Gen[0-9]+_[0-9]+)$", var.sql_database_sku))
    error_message = "SQL Database SKU must be a valid DTU (Basic, S0-S12, P1-P15) or vCore (GP_Gen5_2, BC_Gen5_4, etc.) SKU name."
  }
}

variable "sql_public_network_access" {
  type        = bool
  default     = true
  description = "If `true`, allow public network access to the SQL Server. Required when using firewall rules or `deploy_app_code = true`. Set to `false` when using only private endpoints."

  validation {
    condition     = var.sql_public_network_access || !var.deploy_app_code
    error_message = "`sql_public_network_access` must be `true` when `deploy_app_code` is `true`, because the deployment step requires public SQL access for migrations."
  }
}

variable "sql_server_name" {
  type        = string
  default     = ""
  description = "Name of the SQL Server (without `.database.windows.net`). Defaults to `<webapp_name_prefix>-sql`."
}

variable "src_dir" {
  type        = string
  default     = ""
  description = "Absolute or relative path to the `src/` directory containing the .NET projects. Defaults to `../src` relative to this module."
}

variable "subnet_kv_prefix" {
  type        = string
  default     = "10.0.3.0/24"
  description = "CIDR address prefix for the Key Vault private endpoint subnet."
}

variable "subnet_sql_prefix" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR address prefix for the SQL private endpoint subnet."
}

variable "subnet_web_prefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR address prefix for the web subnet (delegated to Microsoft.Web/serverFarms)."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = <<-DESCRIPTION
    Map of tags to apply to all resources created by this module.

    Example:
    ```hcl
    tags = {
      Project     = "SaaS-Accelerator"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
    ```
  DESCRIPTION
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Azure AD Tenant ID. Defaults to the authenticated provider's tenant if not specified."
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/20"]
  description = "Address space for the virtual network as a list of CIDR blocks."

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one CIDR block must be specified for the VNet address space."
  }
}
