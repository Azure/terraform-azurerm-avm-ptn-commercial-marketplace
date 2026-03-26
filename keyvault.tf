# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Azure Key Vault
# ==============================================================================

resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = local.tenant_id
  purge_protection_enabled   = var.key_vault_purge_protection
  rbac_authorization_enabled = var.key_vault_enable_rbac
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  tags                       = var.tags

  # Network ACLs — default deny in production, configurable for dev/test
  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.key_vault_network_default_action
    ip_rules                   = var.allowed_client_ip != "" ? [var.allowed_client_ip] : []
    virtual_network_subnet_ids = [azurerm_subnet.web.id]
  }
}

# ==============================================================================
# Key Vault Access Policy — Deployer (to set secrets during apply)
# ==============================================================================

resource "azurerm_key_vault_access_policy" "deployer" {
  count = var.key_vault_enable_rbac ? 0 : 1

  key_vault_id       = azurerm_key_vault.this.id
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

  key_vault_id       = azurerm_key_vault.this.id
  object_id          = azurerm_linux_web_app.admin.identity[0].principal_id
  tenant_id          = local.tenant_id
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "portal_webapp" {
  count = var.key_vault_enable_rbac ? 0 : 1

  key_vault_id       = azurerm_key_vault.this.id
  object_id          = azurerm_linux_web_app.portal.identity[0].principal_id
  tenant_id          = local.tenant_id
  key_permissions    = ["Get", "List"]
  secret_permissions = ["Get", "List"]
}

# ==============================================================================
# Key Vault Secrets
# ==============================================================================

resource "azurerm_key_vault_secret" "ad_application_secret" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "ADApplicationSecret"
  value        = local.fulfillment_app_secret

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

resource "azurerm_key_vault_secret" "default_connection" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "DefaultConnection"
  value        = local.sql_connection_string

  depends_on = [azurerm_key_vault_access_policy.deployer]
}
