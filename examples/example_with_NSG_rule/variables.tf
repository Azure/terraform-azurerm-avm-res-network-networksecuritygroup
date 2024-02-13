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
  type = map(object(
    {
      # nsg_rule_name                       = string # (Required) Name of NSG rule.
      nsg_rule_priority                   = number # (Required) NSG rule priority.
      nsg_rule_direction                  = string # (Required) NSG rule direction. Possible values are `Inbound` and `Outbound`.
      nsg_rule_access                     = string # (Required) NSG rule access. Possible values are `Allow` and `Deny`.
      nsg_rule_protocol                   = string # (Required) NSG rule protocol. Possible values are `Tcp`, `Udp`, `Icmp`, `Esp`, `Asterisk`.
      nsg_rule_source_port_range          = string # (Required) NSG rule source port range.
      nsg_rule_destination_port_range     = string # (Required) NSG rule destination port range.
      nsg_rule_source_address_prefix      = string # (Required) NSG rule source address prefix.
      nsg_rule_destination_address_prefix = string # (Required) NSG rule destination address prefix.
    }
  ))
  default = {
    "rule01" = {
      nsg_rule_access                     = "Allow"
      nsg_rule_destination_address_prefix = "*"
      nsg_rule_destination_port_range     = "*"
      nsg_rule_direction                  = "Inbound"
      nsg_rule_priority                   = 100
      nsg_rule_protocol                   = "Tcp"
      nsg_rule_source_address_prefix      = "*"
      nsg_rule_source_port_range          = "*"

    }
  }
  description = "NSG rules to create"
}

