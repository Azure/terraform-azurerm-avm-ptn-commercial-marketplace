# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# App Service Plan (AVM Module)
# ==============================================================================

module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "2.0.2"

  name             = local.app_service_plan
  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
  os_type          = "Linux"
  sku_name         = var.app_service_sku
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
  worker_count     = 1
  zone_balancing_enabled = false
}

# ==============================================================================
# Admin Portal Web App (AVM Module)
# ==============================================================================

module "webapp_admin" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.21.8"

  name                       = local.webapp_admin_name
  location                   = azurerm_resource_group.this.location
  parent_id                  = azurerm_resource_group.this.id
  service_plan_resource_id   = module.app_service_plan.resource_id
  kind                       = "webapp"
  os_type                    = "Linux"
  tags                       = var.tags
  enable_telemetry           = var.enable_telemetry
  virtual_network_subnet_id  = module.virtual_network.subnets["web"].resource_id
  public_network_access_enabled = true

  managed_identities = {
    system_assigned = true
  }

  site_config = {
    always_on = true
    application_stack = {
      dotnet = {
        dotnet_version = "8.0"
      }
    }
  }

  connection_strings = {
    default = {
      name  = "DefaultConnection"
      type  = "SQLAzure"
      value = "@Microsoft.KeyVault(VaultName=${local.key_vault_name};SecretName=DefaultConnection)"
    }
  }

  app_settings = {
    "KnownUsers"                                     = var.publisher_admin_users
    "SaaSApiConfiguration__AdAuthenticationEndPoint" = "https://login.microsoftonline.com"
    "SaaSApiConfiguration__ClientId"                 = local.fulfillment_app_id
    "SaaSApiConfiguration__ClientSecret"             = "@Microsoft.KeyVault(VaultName=${local.key_vault_name};SecretName=ADApplicationSecret)"
    "SaaSApiConfiguration__FulFillmentAPIBaseURL"    = "https://marketplaceapi.microsoft.com/api"
    "SaaSApiConfiguration__FulFillmentAPIVersion"    = "2018-08-31"
    "SaaSApiConfiguration__GrantType"                = "client_credentials"
    "SaaSApiConfiguration__MTClientId"               = local.admin_app_id
    "SaaSApiConfiguration__IsAdminPortalMultiTenant" = tostring(var.is_admin_portal_multi_tenant)
    "SaaSApiConfiguration__Resource"                 = "20e940b3-4c77-4b0b-9a53-9e16a1b010a7"
    "SaaSApiConfiguration__TenantId"                 = local.tenant_id
    "SaaSApiConfiguration__SignedOutRedirectUri"     = "https://${local.webapp_admin_name}.azurewebsites.net/Home/Index/"
  }

  depends_on = [module.key_vault]
}

# ==============================================================================
# Customer Portal Web App (AVM Module)
# ==============================================================================

module "webapp_portal" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.21.8"

  name                       = local.webapp_portal_name
  location                   = azurerm_resource_group.this.location
  parent_id                  = azurerm_resource_group.this.id
  service_plan_resource_id   = module.app_service_plan.resource_id
  kind                       = "webapp"
  os_type                    = "Linux"
  tags                       = var.tags
  enable_telemetry           = var.enable_telemetry
  virtual_network_subnet_id  = module.virtual_network.subnets["web"].resource_id
  public_network_access_enabled = true

  managed_identities = {
    system_assigned = true
  }

  site_config = {
    always_on = true
    application_stack = {
      dotnet = {
        dotnet_version = "8.0"
      }
    }
  }

  connection_strings = {
    default = {
      name  = "DefaultConnection"
      type  = "SQLAzure"
      value = "@Microsoft.KeyVault(VaultName=${local.key_vault_name};SecretName=DefaultConnection)"
    }
  }

  app_settings = {
    "SaaSApiConfiguration__AdAuthenticationEndPoint" = "https://login.microsoftonline.com"
    "SaaSApiConfiguration__ClientId"                 = local.fulfillment_app_id
    "SaaSApiConfiguration__ClientSecret"             = "@Microsoft.KeyVault(VaultName=${local.key_vault_name};SecretName=ADApplicationSecret)"
    "SaaSApiConfiguration__FulFillmentAPIBaseURL"    = "https://marketplaceapi.microsoft.com/api"
    "SaaSApiConfiguration__FulFillmentAPIVersion"    = "2018-08-31"
    "SaaSApiConfiguration__GrantType"                = "client_credentials"
    "SaaSApiConfiguration__MTClientId"               = local.portal_app_id
    "SaaSApiConfiguration__Resource"                 = "20e940b3-4c77-4b0b-9a53-9e16a1b010a7"
    "SaaSApiConfiguration__TenantId"                 = local.tenant_id
    "SaaSApiConfiguration__SignedOutRedirectUri"     = "https://${local.webapp_portal_name}.azurewebsites.net/Home/Index/"
  }

  depends_on = [module.key_vault]
}
