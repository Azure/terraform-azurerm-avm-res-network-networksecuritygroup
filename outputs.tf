output "name" {
  description = "The name of the Network Security Group resource"
  value       = azurerm_network_security_group.this.name
}

output "resource_id" {
  description = "The id of the Network Security Group resource"
  value       = azurerm_network_security_group.this.id
}

output "security_rules" {
  description = "The Network Security Group Rules" # Adjusting certain attributes for idempotent plans
  value = {
    for key, rule in azurerm_network_security_rule.this : key => merge(rule, {
      destination_address_prefixes               = rule.destination_address_prefixes == null ? [] : rule.destination_address_prefixes
      destination_application_security_group_ids = rule.destination_application_security_group_ids == null ? [] : rule.destination_application_security_group_ids
      destination_port_ranges                    = rule.destination_port_ranges == null ? [] : rule.destination_port_ranges
      source_address_prefixes                    = rule.source_address_prefixes == null ? [] : rule.source_address_prefixes
      source_application_security_group_ids      = rule.source_application_security_group_ids == null ? [] : rule.source_application_security_group_ids
      source_port_ranges                         = rule.source_port_ranges == null ? [] : rule.source_port_ranges
    })
  }
}
