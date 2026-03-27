# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0, < 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12, < 1.0"
    }
  }
}
