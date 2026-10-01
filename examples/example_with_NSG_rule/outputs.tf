output "network_security_group_id" {
  description = "The Azure Network Security Group resource ID"
  value       = module.nsg.resource_id
}

output "network_security_group_rules" {
  description = "The Azure Network Security Group resource rules"
  value       = module.nsg.security_rules
}
