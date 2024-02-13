<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = var.rg_location
}

# This is the module call
module "nsg" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.this.name
  name                = module.naming.network_security_group.name_unique
  location            = var.location
  nsgrules            = var.rules
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_rules"></a> [rules](#input\_rules)

Description: n/a

Type:

```hcl
map(object({
    nsg_rule_name                       = "test123"
    nsg_rule_priority                   = 100
    nsg_rule_direction                  = "Outbound"
    nsg_rule_access                     = "Allow"
    nsg_rule_protocol                   = "Tcp"
    nsg_rule_source_port_range          = "*"
    nsg_rule_destination_port_range     = "*"
    nsg_rule_source_address_prefix      = "*"
    nsg_rule_destination_address_prefix = "*"
  }))
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_location"></a> [location](#input\_location)

Description: This variable defines the Azure region where the resource will be created.  
The default value is "eastus".

Type: `string`

Default: `"eastus"`

### <a name="input_rg_location"></a> [rg\_location](#input\_rg\_location)

Description: This variable defines the Azure region where the resource group will be created.  
The default value is "eastus".

Type: `string`

Default: `"eastus"`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.0

### <a name="module_nsg"></a> [nsg](#module\_nsg)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->