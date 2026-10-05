terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
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
  version = "0.12.0"

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
  source  = "Azure/naming/azurerm"
  version = "0.4.4"
}

# This is required for resource modules
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location         = module.regions.regions[random_integer.region_index.result].name
  name             = module.naming.resource_group.name_unique
  enable_telemetry = var.enable_telemetry
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "log_analytics_workspace" {
  location  = module.resource_group.location
  name      = module.naming.log_analytics_workspace.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
}

resource "azapi_resource" "application_security_group" {
  location  = module.resource_group.location
  name      = module.naming.application_security_group.name_unique
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.Network/applicationSecurityGroups@2024-10-01"
  body = {
    properties = {}
  }
}

# This is the module call
module "nsg" {
  source = "../../"

  location  = module.resource_group.location
  name      = module.naming.network_security_group.name_unique
  parent_id = module.resource_group.resource_id
  diagnostic_settings = {
    log_analytics = {
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  enable_telemetry = var.enable_telemetry
  lock = {
    kind = "CanNotDelete"
  }
  role_assignments = {
    reader = {
      role_definition_id_or_name = "Reader"
      principal_id               = data.azapi_client_config.current.object_id
    }
  }
  security_rules = {
    https_to_web_tier = {
      name                                       = "allow-https-to-web-tier"
      access                                     = "Allow"
      direction                                  = "Inbound"
      priority                                   = 100
      protocol                                   = "Tcp"
      source_address_prefixes                    = ["10.0.1.0/24", "10.0.2.0/24"]
      source_port_range                          = "*"
      destination_application_security_group_ids = [azapi_resource.application_security_group.id]
      destination_port_range                     = "443"
    }
    deny_internet_outbound = {
      name                       = "deny-internet-outbound"
      access                     = "Deny"
      direction                  = "Outbound"
      priority                   = 4000
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "Internet"
      destination_port_range     = "*"
    }
  }
  tags = {
    scenario = "with-interfaces"
  }
}
