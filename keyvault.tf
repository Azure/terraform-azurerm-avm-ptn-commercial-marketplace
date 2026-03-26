# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Azure Key Vault (AVM Module)
# ==============================================================================

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                          = local.key_vault_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  tenant_id                     = local.tenant_id
  tags                          = var.tags
  enable_telemetry              = var.enable_telemetry
  sku_name                      = "standard"
  purge_protection_enabled      = var.key_vault_purge_protection
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  public_network_access_enabled = var.key_vault_network_default_action == "Allow"

  legacy_access_policies_enabled = !var.key_vault_enable_rbac

  network_acls = {
    bypass                     = "AzureServices"
    default_action             = var.key_vault_network_default_action
    ip_rules                   = var.allowed_client_ip != "" ? [var.allowed_client_ip] : []
    virtual_network_subnet_ids = [module.virtual_network.subnets["web"].resource_id]
  }

  legacy_access_policies = var.key_vault_enable_rbac ? {} : {
    deployer = {
      object_id          = data.azurerm_client_config.current.object_id
      key_permissions    = ["Get", "List"]
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
    }
  }

  secrets = {
    ad_application_secret = {
      name = "ADApplicationSecret"
    }
    default_connection = {
      name = "DefaultConnection"
    }
  }

  secrets_value = {
    ad_application_secret = local.fulfillment_app_secret
    default_connection    = local.sql_connection_string
  }

  private_endpoints = var.enable_private_endpoints ? {
    kv_pe = {
      name                          = local.private_kv_endpoint
      subnet_resource_id            = module.virtual_network.subnets["kv"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_kv[0].resource_id]
      tags                          = var.tags
    }
  } : {}

  depends_on = [module.virtual_network]
}

# ==============================================================================
# Key Vault Access Policies — Web App Managed Identities
# (Added after web apps are created, since principal IDs are not known at plan time)
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
