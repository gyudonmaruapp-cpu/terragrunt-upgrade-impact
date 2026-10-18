include "root" {
  path = find_in_parent_folders("root.hcl")
}
dependency "vpc" {
  config_path = "../vpc"
  skip_outputs = true
  mock_outputs = { id = "x" }
}
dependency "vpc" {
  config_path = "../vpc2"
}
inputs = { x = dependency.vpc.inputs.cidr }
