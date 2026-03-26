# ==============================================================================
# Default Test — Plan smoke test for the default example.
# ==============================================================================

run "setup" {
  command = plan

  module {
    source = "./examples/default"
  }
}
