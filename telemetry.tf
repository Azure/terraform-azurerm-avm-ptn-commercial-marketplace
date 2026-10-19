data "azapi_client_config" "telemetry" {
  count = var.enable_telemetry ? 1 : 0
}

locals {
  # The module is region-scoped and can emit its primary location in telemetry.
  main_location = var.location
}
