# TODO: insert outputs here.
output "nsg_resource" {
  value       = azurerm_network_security_group.this
  description = "The Azure Network Security Group resource"
}