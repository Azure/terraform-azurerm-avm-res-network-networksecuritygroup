locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  security_rules                     = var.security_rules == null ? {} : var.security_rules
}
