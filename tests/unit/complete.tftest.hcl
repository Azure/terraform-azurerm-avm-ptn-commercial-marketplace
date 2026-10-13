# ==============================================================================
# Complete Test — Plan smoke test for the complete example.
# ==============================================================================

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}

mock_provider "azuread" {}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}

mock_provider "modtm" {}
mock_provider "null" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  fulfillment_app_id     = "00000000-0000-0000-0000-000000000001"
  fulfillment_app_secret = "test-secret-value"
  admin_app_id           = "00000000-0000-0000-0000-000000000002"
  portal_app_id          = "00000000-0000-0000-0000-000000000003"
}

run "setup" {
  command = plan

  providers = {
    azapi   = azapi
    azuread = azuread
    azurerm = azurerm
    modtm   = modtm
    null    = null
    random  = random
    time    = time
  }

  module {
    source = "./examples/complete"
  }
}
