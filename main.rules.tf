resource "azurerm_network_security_rule" "this" {
  for_each = var.nsgrules

  name                        = each.key
  priority                    = each.value.nsg_rule_priority
  direction                   = each.value.nsg_rule_direction
  access                      = each.value.nsg_rule_access
  protocol                    = each.value.nsg_rule_protocol
  source_port_range           = each.value.nsg_rule_source_port_range
  destination_port_range      = each.value.nsg_rule_destination_port_range
  source_address_prefix       = each.value.nsg_rule_source_address_prefix
  destination_address_prefix  = each.value.nsg_rule_destination_address_prefix
  source_port_ranges           = each.value.nsg_rule_source_port_ranges
  destination_port_ranges      = each.value.nsg_rule_destination_port_ranges
  source_address_prefixes       = each.value.nsg_rule_source_address_prefixes
  destination_address_prefixes  = each.value.nsg_rule_destination_address_prefixes
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name

  # Do not remove this `depends_on` block. It is required to ensure the NSG is created before the rule.
  depends_on = [azurerm_network_security_group.this]
}
