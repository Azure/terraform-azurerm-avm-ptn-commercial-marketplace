# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Resource Group
# ==============================================================================

# ==============================================================================
# App Service
# ==============================================================================

# ==============================================================================
# App Registration
# ==============================================================================

# ==============================================================================
# SQL Server
# ==============================================================================

# ==============================================================================
# Key Vault
# ==============================================================================

# ==============================================================================
# Network
# ==============================================================================

# ==============================================================================
# Partner Center Configuration (printed summary)
# ==============================================================================

output "admin_portal_app_id" {
  description = "Admin Portal SSO App Registration Client ID."
  value       = local.admin_app_id
}

output "admin_portal_identity_principal_id" {
  description = "Managed Identity Principal ID of the Admin Portal Web App."
  value       = module.webapp_admin.system_assigned_mi_principal_id
}

output "admin_portal_name" {
  description = "Name of the Admin Portal Web App."
  value       = module.webapp_admin.name
}

output "admin_portal_url" {
  description = "URL of the Publisher Admin Portal."
  value       = "https://${module.webapp_admin.name}.azurewebsites.net"
}

output "customer_portal_identity_principal_id" {
  description = "Managed Identity Principal ID of the Customer Portal Web App."
  value       = module.webapp_portal.system_assigned_mi_principal_id
}

output "customer_portal_name" {
  description = "Name of the Customer Portal Web App."
  value       = module.webapp_portal.name
}

output "customer_portal_url" {
  description = "URL of the Customer Portal (landing page)."
  value       = "https://${module.webapp_portal.name}.azurewebsites.net"
}

output "fulfillment_app_id" {
  description = "Fulfillment API App Registration Client ID (for Partner Center Technical Configuration)."
  value       = local.fulfillment_app_id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = module.key_vault.resource_id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = module.key_vault.uri
}

output "landing_page_app_id" {
  description = "Landing Page SSO App Registration Client ID."
  value       = local.portal_app_id
}

output "partner_center_instructions" {
  description = "Summary of values to configure in Partner Center SaaS Technical Configuration."
  value       = <<-EOT
    ================================================================================
    Partner Center SaaS Technical Configuration
    ================================================================================
    Landing Page URL:     https://${module.webapp_portal.name}.azurewebsites.net/
    Connection Webhook:   https://${module.webapp_portal.name}.azurewebsites.net/api/AzureWebhook
    Tenant ID:            ${local.tenant_id}
    AAD Application ID:   ${local.fulfillment_app_id}
    ================================================================================
  EOT
}

output "resource_group_id" {
  description = "Resource ID of the deployed resource group."
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Name of the deployed resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_id" {
  description = "The resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "sql_database_id" {
  description = "Resource ID of the SQL Database."
  value       = module.sql_server.resource_databases["saas_db"].resource_id
}

output "sql_database_name" {
  description = "Name of the SQL Database."
  value       = local.sql_database_name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server."
  value       = module.sql_server.resource.fully_qualified_domain_name
}

output "sql_server_id" {
  description = "Resource ID of the SQL Server."
  value       = module.sql_server.resource_id
}

output "tenant_id" {
  description = "Azure AD Tenant ID used for the deployment."
  value       = local.tenant_id
}

output "virtual_network_id" {
  description = "Resource ID of the Virtual Network."
  value       = module.virtual_network.resource_id
}

output "virtual_network_name" {
  description = "Name of the Virtual Network."
  value       = module.virtual_network.name
}

output "webhook_url" {
  description = "Webhook URL to configure in Partner Center SaaS Technical Configuration."
  value       = "https://${module.webapp_portal.name}.azurewebsites.net/api/AzureWebhook"
}
