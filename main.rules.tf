resource "azurerm_network_security_rule" "this" {
  for_each = var.security_rules

  access                                     = each.value.access
  direction                                  = each.value.direction
  name                                       = each.value.name
  network_security_group_name                = azurerm_network_security_group.this.name
  priority                                   = each.value.priority
  protocol                                   = each.value.protocol
  resource_group_name                        = azurerm_network_security_group.this.resource_group_name
  description                                = each.value.description
  destination_address_prefix                 = each.value.destination_address_prefix
  destination_address_prefixes               = each.value.destination_address_prefixes
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  destination_port_range                     = each.value.destination_port_range
  destination_port_ranges                    = each.value.destination_port_ranges
  source_address_prefix                      = each.value.source_address_prefix
  source_address_prefixes                    = each.value.source_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  source_port_range                          = each.value.source_port_range
  source_port_ranges                         = each.value.source_port_ranges

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Do not remove this `depends_on` block. It is required to ensure the NSG is created before the rule.
  depends_on = [azurerm_network_security_group.this]
}
