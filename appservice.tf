# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# App Service Plan
# ==============================================================================

resource "azurerm_service_plan" "this" {
  location            = azurerm_resource_group.this.location
  name                = local.app_service_plan
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = var.app_service_sku
  tags                = var.tags
}

# ==============================================================================
# Admin Portal Web App
# ==============================================================================

resource "azurerm_linux_web_app" "admin" {
  location            = azurerm_resource_group.this.location
  name                = local.webapp_admin_name
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  # App Settings — Marketplace SaaS API configuration
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
  tags                      = var.tags
  virtual_network_subnet_id = azurerm_subnet.web.id

  site_config {
    always_on = true

    application_stack {
      dotnet_version = "8.0"
    }
  }
  # Connection string referencing Key Vault
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${local.key_vault_name};SecretName=DefaultConnection)"
  }
  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_key_vault.this]
}

# ==============================================================================
# Customer Portal Web App
# ==============================================================================

resource "azurerm_linux_web_app" "portal" {
  location            = azurerm_resource_group.this.location
  name                = local.webapp_portal_name
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  # App Settings — Marketplace SaaS API configuration
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
  tags                      = var.tags
  virtual_network_subnet_id = azurerm_subnet.web.id

  site_config {
    always_on = true

    application_stack {
      dotnet_version = "8.0"
    }
  }
  # Connection string referencing Key Vault
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${local.key_vault_name};SecretName=DefaultConnection)"
  }
  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_key_vault.this]
}
