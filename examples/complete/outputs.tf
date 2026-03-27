output "admin_portal_url" {
  value = module.saas_accelerator.admin_portal_url
}

output "customer_portal_url" {
  value = module.saas_accelerator.customer_portal_url
}

output "key_vault_id" {
  value = module.saas_accelerator.key_vault_id
}

output "partner_center_instructions" {
  sensitive = true
  value     = module.saas_accelerator.partner_center_instructions
}

output "sql_server_fqdn" {
  sensitive = true
  value     = module.saas_accelerator.sql_server_fqdn
}

output "virtual_network_id" {
  value = module.saas_accelerator.virtual_network_id
}
