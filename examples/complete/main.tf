# Complete Example — All Options Configured
#
# Demonstrates using pre-existing AAD app registrations,
# RBAC-based Key Vault access, enabled private endpoints,
# custom naming, and infrastructure-only mode.

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
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}







module "saas_accelerator" {
  source = "../../"

  location = "westus2"
  # Admin users
  publisher_admin_users = "admin@contoso.com,ops@contoso.com"
  # Custom naming
  webapp_name_prefix = "contoso-saas"
  # Pre-existing AAD app registrations
  ad_application_id           = var.fulfillment_app_id
  ad_application_id_admin     = var.admin_app_id
  ad_application_secret       = var.fulfillment_app_secret
  ad_mt_application_id_portal = var.portal_app_id
  # App Service
  app_service_sku = "P1v3"
  # Infrastructure only — skip .NET build & deploy
  deploy_app_code = false
  # Network configuration
  enable_private_endpoints = true
  enable_telemetry         = var.enable_telemetry
  # Admin portal multi-tenant
  is_admin_portal_multi_tenant = false
  # Key Vault configuration
  key_vault_enable_rbac                = true
  key_vault_name                       = "contoso-saas-kv"
  key_vault_network_default_action     = "Allow"
  key_vault_purge_protection           = true
  key_vault_soft_delete_retention_days = 90
  resource_group_name                  = "rg-contoso-saas-prod"
  sql_database_name                    = "contoso-saas-db"
  sql_server_name                      = "contoso-saas-sqlsvr"
  subnet_kv_prefix                     = "10.1.3.0/24"
  subnet_sql_prefix                    = "10.1.2.0/24"
  subnet_web_prefix                    = "10.1.1.0/24"
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
    CostCenter  = "12345"
    Example     = "complete"
  }
  vnet_address_space = ["10.1.0.0/16"]
}






