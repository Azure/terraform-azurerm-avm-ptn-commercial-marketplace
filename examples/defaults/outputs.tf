output "admin_portal_url" {
  value = module.saas_accelerator.admin_portal_url
}

output "customer_portal_url" {
  value = module.saas_accelerator.customer_portal_url
}

output "partner_center_instructions" {
  sensitive = true
  value     = module.saas_accelerator.partner_center_instructions
}
