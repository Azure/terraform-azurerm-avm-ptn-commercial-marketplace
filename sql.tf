# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Current Signed-In User (for SQL AD Admin)
# ==============================================================================

data "azuread_user" "current" {
  object_id = data.azuread_client_config.current.object_id
}

# ==============================================================================
# Azure SQL Server + Database (AVM Module)
# ==============================================================================

module "sql_server" {
  source  = "Azure/avm-res-sql-server/azurerm"
  version = "0.1.9"

  name                = local.sql_server_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  server_version      = "12.0"
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry
  public_network_access_enabled = var.deploy_app_code

  azuread_administrator = {
    login_username              = data.azuread_user.current.display_name
    object_id                   = data.azuread_user.current.object_id
    azuread_authentication_only = true
  }

  firewall_rules = var.deploy_app_code ? {
    allow_azure = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  } : {}

  databases = {
    saas_db = {
      name           = local.sql_database_name
      sku_name       = var.sql_database_sku
      zone_redundant = false
    }
  }

  private_endpoints = var.enable_private_endpoints ? {
    sql_pe = {
      name                          = local.private_sql_endpoint
      subnet_resource_id            = module.virtual_network.subnets["sql"].resource_id
      subresource_name              = "sqlServer"
      private_dns_zone_resource_ids = [module.private_dns_sql[0].resource_id]
      tags                          = var.tags
    }
  } : {}
}
