# ==============================================================================
# Complete Test — Plan smoke test for the complete example.
# ==============================================================================

variables {
  fulfillment_app_id     = "00000000-0000-0000-0000-000000000001"
  fulfillment_app_secret = "test-secret-value"
  admin_app_id           = "00000000-0000-0000-0000-000000000002"
  portal_app_id          = "00000000-0000-0000-0000-000000000003"
}

run "setup" {
  command = plan

  module {
    source = "./examples/complete"
  }
}
