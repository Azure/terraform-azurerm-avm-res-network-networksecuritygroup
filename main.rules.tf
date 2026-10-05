resource "azapi_resource" "security_rules" {
  for_each = local.security_rules

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = var.resource_types.network_network_security_groups_security_rules
  body = {
    properties = {
      access                               = each.value.access
      description                          = each.value.description
      destinationAddressPrefix             = each.value.destination_address_prefix
      destinationAddressPrefixes           = each.value.destination_address_prefixes == null ? [] : each.value.destination_address_prefixes
      destinationApplicationSecurityGroups = each.value.destination_application_security_group_ids == null ? null : tolist([for id in each.value.destination_application_security_group_ids : { id = id }])
      destinationPortRange                 = each.value.destination_port_range
      destinationPortRanges                = each.value.destination_port_ranges == null ? [] : each.value.destination_port_ranges
      direction                            = each.value.direction
      priority                             = each.value.priority
      protocol                             = each.value.protocol
      sourceAddressPrefix                  = each.value.source_address_prefix
      sourceAddressPrefixes                = each.value.source_address_prefixes == null ? [] : each.value.source_address_prefixes
      sourceApplicationSecurityGroups      = each.value.source_application_security_group_ids == null ? null : tolist([for id in each.value.source_application_security_group_ids : { id = id }])
      sourcePortRange                      = each.value.source_port_range
      sourcePortRanges                     = each.value.source_port_ranges == null ? [] : each.value.source_port_ranges
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.network_network_security_groups_security_rules) > 0 ? var.ignore_body_changes.network_network_security_groups_security_rules : null
  # Azure rejects concurrent changes to the rules of one network security group, so serialise them
  # the way the azurerm provider did.
  locks                  = [azapi_resource.this.id]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : var.timeouts != null ? [var.timeouts] : []

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_network_security_rule.this
  to   = azapi_resource.security_rules
}
