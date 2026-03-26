# Default Example — Minimal Configuration
#
# Deploys the SaaS Accelerator with minimal required configuration
# and developer-friendly overrides (S1, deploy_app_code=false,
# and Key Vault network default action set to Allow).
# AAD app registrations are created automatically.

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0, < 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}


# Unique prefix to avoid naming collisions
resource "random_pet" "prefix" {
  length    = 2
  separator = ""
}

module "saas_accelerator" {
  source = "../../"

  location                         = "centralus"
  publisher_admin_users            = "admin@contoso.com"
  webapp_name_prefix               = random_pet.prefix.id
  app_service_sku                  = "S1"
  deploy_app_code                  = false
  enable_telemetry                 = var.enable_telemetry
  key_vault_network_default_action = "Allow"
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Example     = "default"
  }
}



