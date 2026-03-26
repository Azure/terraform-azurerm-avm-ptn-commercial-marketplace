# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Virtual Network
# ==============================================================================

resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# ==============================================================================
# Subnets
# ==============================================================================

resource "azurerm_subnet" "web" {
  address_prefixes     = [var.subnet_web_prefix]
  name                 = "web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  service_endpoints    = ["Microsoft.Sql", "Microsoft.KeyVault"]

  delegation {
    name = "webapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "sql" {
  address_prefixes     = [var.subnet_sql_prefix]
  name                 = "sql"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_subnet" "kv" {
  address_prefixes     = [var.subnet_kv_prefix]
  name                 = "kv"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# ==============================================================================
# Private DNS Zones (conditional on var.enable_private_endpoints)
# ==============================================================================

resource "azurerm_private_dns_zone" "sql" {
  count = var.enable_private_endpoints ? 1 : 0

  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "kv" {
  count = var.enable_private_endpoints ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

# ==============================================================================
# Private DNS Zone VNet Links
# ==============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  count = var.enable_private_endpoints ? 1 : 0

  name                  = local.private_sql_link
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count = var.enable_private_endpoints ? 1 : 0

  name                  = local.private_kv_link
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

# ==============================================================================
# SQL Private Endpoint
# ==============================================================================

resource "azurerm_private_endpoint" "sql" {
  count = var.enable_private_endpoints ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = local.private_sql_endpoint
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.sql.id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "sqlConnection"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
  }
  private_dns_zone_group {
    name                 = "sql-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql[0].id]
  }
}

# ==============================================================================
# Key Vault Private Endpoint
# ==============================================================================

resource "azurerm_private_endpoint" "kv" {
  count = var.enable_private_endpoints ? 1 : 0

  location            = azurerm_resource_group.this.location
  name                = local.private_kv_endpoint
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.kv.id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "kvConnection"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
  }
  private_dns_zone_group {
    name                 = "kv-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv[0].id]
  }
}
