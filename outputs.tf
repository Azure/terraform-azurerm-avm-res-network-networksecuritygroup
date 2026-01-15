output "name" {
  description = "The name of the Network Security Group resource"
  value       = azurerm_network_security_group.this.name
}

output "resource_id" {
  description = "The id of the Network Security Group resource"
  value       = azurerm_network_security_group.this.id
}

output "security_rules" {
  description = "The Network Security Group Rules"
  value       = azurerm_network_security_rule.this
}
