output "id" {
  description = "The id of the Network Security Group resource"
  value       = azurerm_network_security_group.this.id
}

output "name" {
  description = "The name of the Network Security Group resource"
  value       = azurerm_network_security_group.this.name
}

output "resource" {
  description = "The Network Security Group resource"
  value       = azurerm_network_security_group.this
}
