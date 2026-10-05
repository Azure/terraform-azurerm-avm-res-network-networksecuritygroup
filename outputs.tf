output "name" {
  description = "The name of the Network Security Group resource"
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The id of the Network Security Group resource"
  value       = azapi_resource.this.id
}

output "security_rules" {
  description = <<DESCRIPTION
The security rules managed by this module, keyed like `var.security_rules`. Each value keeps the attribute names of the
`azurerm_network_security_rule` resource returned by earlier versions of this module. Unset list attributes are returned
as empty lists.
DESCRIPTION
  value = {
    for key, rule in local.security_rules : key => {
      access                                     = rule.access
      description                                = rule.description
      destination_address_prefix                 = rule.destination_address_prefix
      destination_address_prefixes               = rule.destination_address_prefixes == null ? [] : rule.destination_address_prefixes
      destination_application_security_group_ids = rule.destination_application_security_group_ids == null ? [] : rule.destination_application_security_group_ids
      destination_port_range                     = rule.destination_port_range
      destination_port_ranges                    = rule.destination_port_ranges == null ? [] : rule.destination_port_ranges
      direction                                  = rule.direction
      id                                         = azapi_resource.security_rules[key].id
      name                                       = azapi_resource.security_rules[key].name
      network_security_group_name                = azapi_resource.this.name
      priority                                   = rule.priority
      protocol                                   = rule.protocol
      resource_group_name                        = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).resource_group_name
      source_address_prefix                      = rule.source_address_prefix
      source_address_prefixes                    = rule.source_address_prefixes == null ? [] : rule.source_address_prefixes
      source_application_security_group_ids      = rule.source_application_security_group_ids == null ? [] : rule.source_application_security_group_ids
      source_port_range                          = rule.source_port_range
      source_port_ranges                         = rule.source_port_ranges == null ? [] : rule.source_port_ranges
    }
  }
}
