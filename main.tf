# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Resource Group
# ==============================================================================

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = local.resource_group_name
  tags     = var.tags
}
