# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Data Sources
# ==============================================================================

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# ==============================================================================
# Computed Resource Names
# ==============================================================================

locals {
  app_service_plan    = "${var.webapp_name_prefix}-asp"
  key_vault_name      = var.key_vault_name != "" ? var.key_vault_name : "${var.webapp_name_prefix}-kv"
  private_kv_endpoint = "${var.webapp_name_prefix}-kv-pe"
  private_kv_link     = "${var.webapp_name_prefix}-kv-link"
  # Private endpoint / DNS naming
  private_sql_endpoint = "${var.webapp_name_prefix}-db-pe"
  private_sql_link     = "${var.webapp_name_prefix}-db-link"
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : var.webapp_name_prefix
  sql_database_name    = var.sql_database_name != "" ? var.sql_database_name : "${var.webapp_name_prefix}AMPSaaSDB"
  sql_server_name      = var.sql_server_name != "" ? var.sql_server_name : "${var.webapp_name_prefix}-sql"
  tenant_id            = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  vnet_name            = "${var.webapp_name_prefix}-vnet"
  webapp_admin_name    = "${var.webapp_name_prefix}-admin"
  webapp_portal_name   = "${var.webapp_name_prefix}-portal"
}

# ==============================================================================
# Connection Strings
# ==============================================================================

locals {
  # Private connection string for Managed Identity (used by web apps via Key Vault)
  sql_connection_string = "Server=tcp:${local.sql_server_name}.privatelink.database.windows.net;Database=${local.sql_database_name};TrustServerCertificate=True;Authentication=Active Directory Managed Identity;"
  # Public connection string for deployer during EF Core migration
  sql_connection_string_public = "Server=tcp:${local.sql_server_name}.database.windows.net;Database=${local.sql_database_name};Authentication=Active Directory Default;"
  # Source directory for .NET application code
  src_dir = var.src_dir != "" ? var.src_dir : "${path.module}/../src"
}

# ==============================================================================
# Azure AD — Resolved App Registration IDs (created or user-provided)
# ==============================================================================

locals {
  admin_app_id     = var.ad_application_id_admin != "" ? var.ad_application_id_admin : azuread_application.admin_portal[0].client_id
  create_admin_app = var.ad_application_id_admin == ""
  # Boolean flags for conditional AAD app creation
  create_fulfillment_app = var.ad_application_id == ""
  create_portal_app      = var.ad_mt_application_id_portal == ""
  # Resolved App Registration IDs — use user-provided values or created resources
  fulfillment_app_id     = var.ad_application_id != "" ? var.ad_application_id : azuread_application.fulfillment[0].client_id
  fulfillment_app_secret = var.ad_application_secret != null && var.ad_application_secret != "" ? var.ad_application_secret : azuread_application_password.fulfillment[0].value
  # Microsoft Graph Application ID (well-known)
  microsoft_graph_app_id = "00000003-0000-0000-c000-000000000000"
  portal_app_id          = var.ad_mt_application_id_portal != "" ? var.ad_mt_application_id_portal : azuread_application.landing_page[0].client_id
  # User.Read delegated permission (well-known)
  user_read_scope_id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
}
