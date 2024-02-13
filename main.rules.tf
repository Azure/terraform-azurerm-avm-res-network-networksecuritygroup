resource "azurerm_network_security_rule" "this" {
  for_each = var.nsgrules

  name                        = each.value.nsg_rule_name
  priority                    = each.value.nsg_rule_priority
  direction                   = each.value.nsg_rule_direction
  access                      = each.value.nsg_rule_access
  protocol                    = each.value.nsg_rule_protocol
  source_port_range           = each.value.nsg_rule_source_port_range
  destination_port_range      = each.value.nsg_rule_destination_port_range
  source_address_prefix       = each.value.nsg_rule_source_address_prefix
  destination_address_prefix  = each.value.nsg_rule_destination_address_prefix
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name

  # Do not remove this `depends_on` block. It is required to ensure the NSG is created before the rule.
  depends_on = [azurerm_network_security_group.this]
}
