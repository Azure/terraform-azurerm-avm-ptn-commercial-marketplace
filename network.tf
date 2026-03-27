# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Virtual Network (AVM Module)
# ==============================================================================

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  location         = azurerm_resource_group.this.location
  parent_id        = azurerm_resource_group.this.id
  address_space    = toset(var.vnet_address_space)
  enable_telemetry = var.enable_telemetry
  name             = local.vnet_name
  subnets = {
    web = {
      name             = "web"
      address_prefixes = [var.subnet_web_prefix]
      service_endpoints_with_location = [
        { service = "Microsoft.Sql", locations = [azurerm_resource_group.this.location] },
        { service = "Microsoft.KeyVault", locations = [azurerm_resource_group.this.location] },
      ]
      delegations = [
        {
          name = "webapp-delegation"
          service_delegation = {
            name = "Microsoft.Web/serverFarms"
          }
        }
      ]
    }
    sql = {
      name             = "sql"
      address_prefixes = [var.subnet_sql_prefix]
    }
    kv = {
      name             = "kv"
      address_prefixes = [var.subnet_kv_prefix]
    }
  }
  tags = var.tags
}

# ==============================================================================
# Private DNS Zones (AVM Module, conditional on var.enable_private_endpoints)
# ==============================================================================

module "private_dns_sql" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"
  count   = var.enable_private_endpoints ? 1 : 0

  domain_name      = "privatelink.database.windows.net"
  parent_id        = azurerm_resource_group.this.id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
  virtual_network_links = {
    sql_link = {
      name               = local.private_sql_link
      virtual_network_id = module.virtual_network.resource_id
    }
  }
}

module "private_dns_kv" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"
  count   = var.enable_private_endpoints ? 1 : 0

  domain_name      = "privatelink.vaultcore.azure.net"
  parent_id        = azurerm_resource_group.this.id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
  virtual_network_links = {
    kv_link = {
      name               = local.private_kv_link
      virtual_network_id = module.virtual_network.resource_id
    }
  }
}
