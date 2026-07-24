terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Example demonstrating nullable security_rules with dynamic construction
locals {
  network_security_groups = {
    group_1 = {
      name                  = "${module.naming.network_security_group.name_unique}-1"
      local_rules_reference = null
    }
    group_2 = {
      name                  = "${module.naming.network_security_group.name_unique}-2"
      local_rules_reference = "group_2"
    }
  }
  network_security_group_rules = {
    group_2 = {
      rule_1 = {
        name                         = "${module.naming.network_security_rule.name_unique}-allow-https"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefixes      = ["10.0.0.0/8"]
        destination_address_prefixes = ["10.0.0.0/8"]
      }
    }
  }
}

# This is the module call demonstrating nullable security_rules
# group_1 will have no custom security rules (null)
# group_2 will have custom security rules
module "network_security_groups" {
  source = "../../"

  for_each            = local.network_security_groups
  location            = azurerm_resource_group.this.location
  name                = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  # This demonstrates the fix: using null in a conditional is now possible
  security_rules = each.value.local_rules_reference == null ? try(local.network_security_group_rules[each.key], null) : try(local.network_security_group_rules[each.value.local_rules_reference], null)
}
