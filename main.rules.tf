resource "azurerm_network_security_rule" "this" {
  for_each = var.nsgrules

  name                        = "test123"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name

  # Do not remove this `depends_on` block. It is required to ensure the NSG is created before the rule.
  depends_on = [azurerm_network_security_group.this]
}
