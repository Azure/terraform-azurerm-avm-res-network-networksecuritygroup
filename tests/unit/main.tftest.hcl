mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkSecurityGroups/nsg-test"
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      object_id       = "11111111-1111-1111-1111-111111111111"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          }
        ]
      }
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  location  = "westus2"
  name      = "nsg-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/networkSecurityGroups@2024-10-01"
    error_message = "The network security group should use the default resource type."
  }
  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.location == var.location
    error_message = "The network security group should be deployed to parent_id and location."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.securityRules) == 0
    error_message = "The network security group body should carry only the empty securityRules placeholder."
  }
  assert {
    condition     = length(azapi_resource.security_rules) + length(azapi_resource.lock) + length(azapi_resource.role_assignments) + length(azapi_resource.diagnostic_settings) + length(time_sleep.lock_removal) == 0
    error_message = "No child or interface resources should be created by default."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == azapi_resource.this.name
    error_message = "resource_id and name outputs should come from the network security group."
  }
}

run "null_security_rules" {
  command = apply

  variables {
    security_rules = null
  }

  assert {
    condition     = length(azapi_resource.security_rules) == 0 && length(output.security_rules) == 0
    error_message = "A null security_rules input should create no rules."
  }
}

run "security_rules_map_to_the_arm_body" {
  command = apply

  override_resource {
    target = azapi_resource.security_rules
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkSecurityGroups/nsg-test/securityRules/mocked"
    }
  }

  variables {
    security_rules = {
      web = {
        name                                       = "allow-https"
        access                                     = "Allow"
        direction                                  = "Inbound"
        priority                                   = 100
        protocol                                   = "Tcp"
        source_address_prefixes                    = ["10.0.2.0/24", "10.0.1.0/24"]
        source_port_range                          = "*"
        destination_application_security_group_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationSecurityGroups/asg-web"]
        destination_port_ranges                    = ["443", "8443"]
        timeouts = {
          create = "45m"
        }
      }
      deny = {
        name                       = "deny-internet"
        access                     = "Deny"
        description                = "Deny outbound internet"
        direction                  = "Outbound"
        priority                   = 4000
        protocol                   = "*"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "Internet"
        destination_port_range     = "*"
      }
    }
    timeouts = {
      create = "10m"
    }
  }

  assert {
    condition     = azapi_resource.security_rules["web"].type == "Microsoft.Network/networkSecurityGroups/securityRules@2024-10-01" && azapi_resource.security_rules["web"].parent_id == azapi_resource.this.id
    error_message = "Rules should be child resources of the network security group."
  }
  assert {
    condition     = azapi_resource.security_rules["web"].name == "allow-https" && azapi_resource.security_rules["web"].body.properties.priority == 100
    error_message = "Rule name and priority should be mapped."
  }
  assert {
    condition     = toset(azapi_resource.security_rules["web"].body.properties.sourceAddressPrefixes) == toset(["10.0.1.0/24", "10.0.2.0/24"]) && azapi_resource.security_rules["web"].body.properties.sourceAddressPrefix == null
    error_message = "Plural address prefixes should be mapped and the singular form left null."
  }
  assert {
    condition     = [for asg in azapi_resource.security_rules["web"].body.properties.destinationApplicationSecurityGroups : asg.id] == ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationSecurityGroups/asg-web"]
    error_message = "Application security group IDs should be mapped to objects with an id."
  }
  assert {
    condition     = azapi_resource.security_rules["deny"].body.properties.destinationApplicationSecurityGroups == null && azapi_resource.security_rules["deny"].body.properties.description == "Deny outbound internet"
    error_message = "Unset application security groups should stay null and the description should be mapped."
  }
  assert {
    condition     = length(azapi_resource.security_rules["deny"].body.properties.sourceAddressPrefixes) == 0 && length(azapi_resource.security_rules["deny"].body.properties.destinationPortRanges) == 0 && azapi_resource.security_rules["web"].body.properties.description == null
    error_message = "Unset plural attributes should be sent as empty lists, which is what Azure returns, and unset values as null."
  }
  assert {
    condition     = azapi_resource.security_rules["web"].timeouts.create == "45m" && azapi_resource.security_rules["deny"].timeouts.create == "10m"
    error_message = "A rule's own timeouts should take precedence over var.timeouts."
  }
  assert {
    condition     = output.security_rules["web"].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkSecurityGroups/nsg-test/securityRules/mocked" && output.security_rules["web"].resource_group_name == "rg-test" && output.security_rules["web"].network_security_group_name == azapi_resource.this.name
    error_message = "The security_rules output should expose the rule's own ID and the azurerm-style parent names."
  }
  assert {
    condition     = length(output.security_rules["deny"].source_port_ranges) == 0 && length(output.security_rules["web"].destination_port_ranges) == 2
    error_message = "The security_rules output should return unset list attributes as empty lists."
  }
}

run "lock_keeps_the_legacy_notes" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete" && azapi_resource.lock[0].parent_id == azapi_resource.this.id
    error_message = "The lock should get the default name and target the network security group."
  }
  assert {
    condition     = azapi_resource.lock[0].body.properties.level == "CanNotDelete" && azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources."
    error_message = "The lock should keep the notes earlier versions wrote, so upgrades do not change it."
  }
  assert {
    condition     = time_sleep.lock_removal[0].destroy_duration == "30s"
    error_message = "Removing the lock should pause before the resources under it are deleted, as the AzureRM provider did."
  }
}

run "lock_with_custom_notes" {
  command = apply

  variables {
    lock = {
      kind  = "ReadOnly"
      name  = "lock-custom"
      notes = "Managed by the platform team."
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-custom" && azapi_resource.lock[0].body.properties.notes == "Managed by the platform team."
    error_message = "Custom lock name and notes should be used."
  }
}

run "role_assignment_by_role_name" {
  command = apply

  variables {
    role_assignments = {
      reader = {
        role_definition_id_or_name       = "reader"
        principal_id                     = "22222222-2222-2222-2222-222222222222"
        skip_service_principal_aad_check = true
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["reader"].type == "Microsoft.Authorization/roleAssignments@2022-04-01" && azapi_resource.role_assignments["reader"].parent_id == azapi_resource.this.id
    error_message = "The role assignment should be scoped to the network security group."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.principalId == "22222222-2222-2222-2222-222222222222" && azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    error_message = "The role name should be resolved to its role definition ID, ignoring case."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.principalType == "ServicePrincipal"
    error_message = "skip_service_principal_aad_check should send the ServicePrincipal principal type, as the AzureRM provider did."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].replace_triggers_external_values.role_definition_id_or_name == "reader" && azapi_resource.role_assignments["reader"].replace_triggers_external_values.principal_id == "22222222-2222-2222-2222-222222222222"
    error_message = "Changing a role assignment input should replace the assignment, as it did with azurerm."
  }
  assert {
    condition     = data.azapi_resource_list.role_definitions[0].parent_id == var.parent_id
    error_message = "Role definitions should be listed in the resource group, so the lookup does not wait for changes to the network security group."
  }
}

run "role_assignment_by_tenant_level_id" {
  command = apply

  variables {
    role_assignments = {
      network_contributor = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
        principal_id               = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["network_contributor"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
    error_message = "A tenant-level role definition ID should be qualified with the subscription, the form Azure returns."
  }
  assert {
    condition     = azapi_resource.role_assignments["network_contributor"].body.properties.principalType == null
    error_message = "The principal type should be left to Azure when it is not set."
  }
}

run "role_assignment_with_unknown_role_name" {
  command = plan

  # The network security group ID stays unknown during this plan. Because role definitions are listed
  # in the resource group, the lookup still runs and the precondition fails during plan.
  variables {
    role_assignments = {
      unknown = {
        role_definition_id_or_name = "Not A Real Role"
        principal_id               = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  expect_failures = [azapi_resource.role_assignments]
}

run "diagnostic_settings_mapping" {
  command = apply

  variables {
    diagnostic_settings = {
      law = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      }
      event_hub = {
        name                                     = "diag-custom"
        event_hub_authorization_rule_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/ehns-test/authorizationRules/RootManageSharedAccessKey"
        log_analytics_destination_type           = "AzureDiagnostics"
        log_categories                           = ["NetworkSecurityGroupEvent"]
        log_groups                               = []
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].name == "diag-nsg-test" && azapi_resource.diagnostic_settings["law"].parent_id == azapi_resource.this.id
    error_message = "Diagnostic settings should default their name and target the network security group."
  }
  assert {
    condition     = azapi_resource.diagnostic_settings["law"].body.properties.logAnalyticsDestinationType == null && azapi_resource.diagnostic_settings["event_hub"].body.properties.logAnalyticsDestinationType == "AzureDiagnostics"
    error_message = "Dedicated should be sent as null, as it always was, and AzureDiagnostics passed through."
  }
  assert {
    condition     = azapi_resource.diagnostic_settings["law"].body.properties.logs[0].categoryGroup == "allLogs" && azapi_resource.diagnostic_settings["event_hub"].body.properties.logs[0].category == "NetworkSecurityGroupEvent"
    error_message = "Log categories and category groups should be mapped."
  }
  assert {
    condition     = !can(azapi_resource.diagnostic_settings["law"].body.properties.metrics)
    error_message = "Network security groups emit no metrics, so none should be sent."
  }
}

run "resource_types_override" {
  command = apply

  variables {
    resource_types = {
      network_network_security_groups = "Microsoft.Network/networkSecurityGroups@2023-11-01"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/networkSecurityGroups@2023-11-01"
    error_message = "resource_types should override the network security group API version."
  }
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
}

run "invalid_application_security_group_id" {
  command = plan

  variables {
    security_rules = {
      web = {
        name                                       = "allow-https"
        access                                     = "Allow"
        direction                                  = "Inbound"
        priority                                   = 100
        protocol                                   = "Tcp"
        source_address_prefix                      = "*"
        source_port_range                          = "*"
        destination_application_security_group_ids = ["asg-web"]
        destination_port_range                     = "443"
      }
    }
  }

  expect_failures = [var.security_rules]
}

run "invalid_workspace_id" {
  command = plan

  variables {
    diagnostic_settings = {
      law = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      }
    }
  }

  expect_failures = [var.diagnostic_settings]
}
