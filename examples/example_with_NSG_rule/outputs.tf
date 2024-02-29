output "Created_NSG" {
  value       = module.nsg.nsg_resource
  description = "The Azure Network Security Group resource"
}