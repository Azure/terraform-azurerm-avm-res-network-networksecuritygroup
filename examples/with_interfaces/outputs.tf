output "network_security_group_id" {
  description = "The resource ID of the network security group."
  value       = module.nsg.resource_id
}

output "network_security_group_rules" {
  description = "The security rules managed by the module."
  value       = module.nsg.security_rules
}
