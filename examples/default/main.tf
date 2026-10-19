terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    modtm = {
      source  = "registry.terraform.io/azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.0"
  providers = {
    azapi = azapi
  }

  location         = var.location
  enable_telemetry = var.enable_telemetry
  is_recommended   = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

# This is required for resource modules
module "resource_group" {
  source    = "Azure/avm-res-resources-resourcegroup/azurerm"
  version   = "0.4.0"
  providers = { modtm = modtm }

  location         = module.regions.regions[random_integer.region_index.result].name
  name             = module.naming.resource_group.name_unique
  enable_telemetry = var.enable_telemetry
}

# This is the module call
module "nsg" {
  source = "../../"
  providers = {
    azapi = azapi
  }

  location         = module.resource_group.location
  name             = module.naming.network_security_group.name_unique
  parent_id        = module.resource_group.resource_id
  enable_telemetry = var.enable_telemetry
}
