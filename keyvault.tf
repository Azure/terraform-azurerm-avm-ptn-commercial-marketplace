# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Azure Key Vault (AVM Module)
# ==============================================================================

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  location                       = azurerm_resource_group.this.location
  name                           = local.key_vault_name
  resource_group_name            = azurerm_resource_group.this.name
  tenant_id                      = local.tenant_id
  enable_telemetry               = var.enable_telemetry
  legacy_access_policies_enabled = !var.key_vault_enable_rbac
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = var.key_vault_network_default_action
    ip_rules                   = var.allowed_client_ip != "" ? [var.allowed_client_ip] : []
    virtual_network_subnet_ids = [module.virtual_network.subnets["web"].resource_id]
  }
  private_endpoints = var.enable_private_endpoints ? {
    kv_pe = {
      name                          = local.private_kv_endpoint
      subnet_resource_id            = module.virtual_network.subnets["kv"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_kv[0].resource_id]
      tags                          = var.tags
    }
  } : {}
  public_network_access_enabled = var.key_vault_network_default_action == "Allow"
  purge_protection_enabled      = var.key_vault_purge_protection
  sku_name                      = "standard"
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  tags                          = var.tags

  depends_on = [module.virtual_network]
}

# ==============================================================================
# Key Vault RBAC Role Assignments (when RBAC is enabled)
# ==============================================================================

resource "azurerm_role_assignment" "kv_deployer_secrets_officer" {
  count = var.key_vault_enable_rbac ? 1 : 0

  principal_id         = data.azurerm_client_config.current.object_id
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets Officer"
}

resource "azurerm_role_assignment" "kv_admin_webapp_secrets_user" {
  count = var.key_vault_enable_rbac ? 1 : 0

  principal_id         = module.webapp_admin.system_assigned_mi_principal_id
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "kv_portal_webapp_secrets_user" {
  count = var.key_vault_enable_rbac ? 1 : 0

  principal_id         = module.webapp_portal.system_assigned_mi_principal_id
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
}

# ==============================================================================
# Key Vault Access Policy — Deployer (legacy mode only)
# ==============================================================================

resource "azurerm_key_vault_access_policy" "deployer" {
  count = var.key_vault_enable_rbac ? 0 : 1

  key_vault_id       = module.key_vault.resource_id
  object_id          = data.azurerm_client_config.current.object_id
  tenant_id          = local.tenant_id
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# ==============================================================================
# Key Vault Access Policies — Web App Managed Identities
# ==============================================================================

resource "azurerm_key_vault_access_policy" "admin_webapp" {
  count = var.key_vault_enable_rbac ? 0 : 1

  key_vault_id       = module.key_vault.resource_id
  object_id          = module.webapp_admin.system_assigned_mi_principal_id
  tenant_id          = local.tenant_id
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "portal_webapp" {
  count = var.key_vault_enable_rbac ? 0 : 1

  key_vault_id       = module.key_vault.resource_id
  object_id          = module.webapp_portal.system_assigned_mi_principal_id
  tenant_id          = local.tenant_id
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "List"]
}

# ==============================================================================
# Key Vault Secrets
# ==============================================================================

resource "azurerm_key_vault_secret" "ad_application_secret" {
  key_vault_id = module.key_vault.resource_id
  name         = "ADApplicationSecret"
  tags         = var.tags
  value        = local.fulfillment_app_secret

  depends_on = [azurerm_key_vault_access_policy.deployer, azurerm_role_assignment.kv_deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "default_connection" {
  key_vault_id = module.key_vault.resource_id
  name         = "DefaultConnection"
  tags         = var.tags
  value        = local.sql_connection_string

  depends_on = [azurerm_key_vault_access_policy.deployer, azurerm_role_assignment.kv_deployer_secrets_officer]
}
