resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.network_network_security_groups
  body = {
    properties = {
      # Placeholders only. A PUT resets every property it omits, and Azure deletes every rule it omits,
      # while the rules are separate child resources (managed by this module and often by others).
      # Both paths are always ignored below, so on update the provider re-reads the NSG and sends the
      # live values instead.
      flushConnection = false
      securityRules   = []
    }
  }
  ignore_body_changes    = distinct(concat(["properties.flushConnection", "properties.securityRules"], var.ignore_body_changes.network_network_security_groups))
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Keeps the planned body consistent with the values in state, which AzAPI cannot fit into the
    # placeholders above. The values actually sent come from the live read described above.
    ignore_changes = [body.properties.flushConnection, body.properties.securityRules]
  }
}

moved {
  from = azurerm_network_security_group.this
  to   = azapi_resource.this
}

# Role definitions are resolved here, case-insensitively as the AzureRM provider did, rather than by
# the interfaces module, whose lookup is case-sensitive. They are listed in the resource group rather
# than on the network security group, so the lookup does not wait for pending changes to the network
# security group and a role name that does not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = var.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
      notes = coalesce(var.lock.notes, local.lock_notes[var.lock.kind])
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Create the lock last and remove it first. A ReadOnly lock blocks changes to the child resources.
  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.role_assignments,
    azapi_resource.security_rules,
  ]
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are
  # compared, rather than body paths or the resolved role definition ID: Azure normalises role
  # definition IDs, and the role definition lookup is deferred to apply whenever the resource group is
  # not yet known. While the prior value is null, as it is straight after upgrading from AzureRM,
  # nothing is replaced.
  replace_triggers_external_values = {
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Upgraded assignments keep the GUID azurerm generated, while the interfaces module generates a
    # new one. Replacing the assignment would fail with ScopeLocked under a CanNotDelete lock.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      # This module has always sent "Dedicated" as null, which leaves the choice to Azure.
      logAnalyticsDestinationType = each.value.log_analytics_destination_type == "Dedicated" ? null : each.value.log_analytics_destination_type
      logs = tolist(concat(
        [for category in each.value.log_categories : { category = category, categoryGroup = null, enabled = true }],
        [for group in each.value.log_groups : { category = null, categoryGroup = group, enabled = true }],
      ))
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      storageAccountId     = each.value.storage_account_resource_id
      workspaceId          = each.value.workspace_resource_id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}
