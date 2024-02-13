variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "rg_location" {
  type        = string
  default     = "eastus"
  description = <<DESCRIPTION
This variable defines the Azure region where the resource group will be created.
The default value is "eastus".
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "eastus"
  description = <<DESCRIPTION
This variable defines the Azure region where the resource will be created.
The default value is "eastus".
DESCRIPTION
}

variable "rules" {
  rule1 = {
    nsg_rule_priority                   = 100
    nsg_rule_direction                  = "Outbound"
    nsg_rule_access                     = "Allow"
    nsg_rule_protocol                   = "Tcp"
    nsg_rule_source_port_range          = "*"
    nsg_rule_destination_port_range     = "*"
    nsg_rule_source_address_prefix      = "*"
    nsg_rule_destination_address_prefix = "*"
  }
  description = <<DESCRIPTION
Variable to define the NSG rules to be created.
DESCRIPTION
}

