# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Current Signed-In User (for SQL AD Admin)
# ==============================================================================

data "azuread_user" "current" {
  object_id = data.azuread_client_config.current.object_id
}

# ==============================================================================
# Azure SQL Server — Entra-only Authentication
# ==============================================================================

resource "azurerm_mssql_server" "this" {
  location            = azurerm_resource_group.this.location
  name                = local.sql_server_name
  resource_group_name = azurerm_resource_group.this.name
  version             = "12.0"
  minimum_tls_version = "1.2"
  tags                = var.tags

  azuread_administrator {
    login_username              = data.azuread_user.current.display_name
    object_id                   = data.azuread_user.current.object_id
    azuread_authentication_only = true
  }
}

# ==============================================================================
# SQL Server Firewall Rules
# ==============================================================================

# Allow Azure services to reach the SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  end_ip_address   = "0.0.0.0"
  name             = "AllowAzureIP"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
}

# ==============================================================================
# SQL Server Virtual Network Rule (web subnet)
# ==============================================================================

resource "azurerm_mssql_virtual_network_rule" "web" {
  name      = "${var.webapp_name_prefix}-vnet"
  server_id = azurerm_mssql_server.this.id
  subnet_id = azurerm_subnet.web.id
}

# ==============================================================================
# Azure SQL Database
# ==============================================================================

resource "azurerm_mssql_database" "this" {
  name      = local.sql_database_name
  server_id = azurerm_mssql_server.this.id
  # Required by provider schema for non-serverless tiers; Azure can report 0 back on read.
  auto_pause_delay_in_minutes = -1
  sku_name                    = var.sql_database_sku
  tags                        = var.tags
  zone_redundant              = false

  lifecycle {
    ignore_changes  = [auto_pause_delay_in_minutes]
    prevent_destroy = false
  }
}
