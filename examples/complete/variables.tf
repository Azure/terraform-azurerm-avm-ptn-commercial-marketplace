variable "admin_app_id" {
  type        = string
  description = "Pre-existing Admin Portal SSO App Registration Client ID."
}

variable "fulfillment_app_id" {
  type        = string
  description = "Pre-existing Fulfillment API App Registration Client ID."
}

variable "fulfillment_app_secret" {
  type        = string
  description = "Pre-existing Fulfillment API App Registration Client Secret."
  sensitive   = true
}

variable "portal_app_id" {
  type        = string
  description = "Pre-existing Landing Page SSO App Registration Client ID."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "Azure Subscription ID override. If null, azurerm uses the active Azure CLI subscription."
}
