# Tests

`avm test unit` runs the provider-mocked example-plan smoke checks in
`unit/default.tftest.hcl` and `unit/complete.tftest.hcl`. Each retains its
`setup` run and example inputs. They check configuration planning, not live
Azure behavior. There is no integration suite.
