# terraform-azurerm-avm-res-network-networksecuritygroup


NOTE: This module follows the semantic versioning and versions prior to 1.0.0 should be consider pre-release versions.
This is the Network Security Group resource module for the Azure Verified Modules library. This module deploys a Azure Network Security Group and give availability to manage rules. It uses the AzAPI provider and sets a number of initial defaults to minimize the overall inputs for simple configurations.

Security rules are managed as separate child resources, so rules that other configurations or Azure services add to the network security group are left in place. Azure removes every rule that an update to the network security group omits, so whenever the module updates the network security group itself (for example its tags), it re-reads the rules and sends them unchanged.

Terraform 1.11 or later is required, because the module uses the write-only `ignore_body_changes` argument of AzAPI to protect the security rules.

## Upgrading from a version that used the AzureRM provider

Versions up to 0.5.x managed the network security group with the AzureRM provider. This version uses AzAPI and includes `moved` blocks, so the network security group, its security rules, lock, role assignments and diagnostic settings move to their AzAPI addresses without being recreated.

1. Replace `resource_group_name` with `parent_id`, the resource ID of the resource group:

   ```hcl
   parent_id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>"
   ```

1. Run `terraform init -upgrade`, then `terraform plan`.
1. Expect in-place updates while AzAPI takes over the existing resources, and new `random_uuid` resources when role assignments are configured. Nothing should be destroyed or replaced; do not apply a plan that destroys or replaces any of these resources.
1. Apply the plan. A second plan reports no changes.

Two cases need extra steps:

- **`ReadOnly` lock.** The upgrade updates the network security group and its rules in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration with `lock = null` using the old version, then upgrade and restore the lock.
- **Cross-tenant role assignments** (those that set `delegated_managed_identity_resource_id`, for example with Azure Lighthouse). The AzureRM provider stored their ID with a `|<tenant-id>` suffix that the `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module:

  ```pwsh
  terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
  ```

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.role_assignments["<key>"]
    id = "<role assignment resource ID, without the |<tenant-id> suffix>"
  }
  ```

The `security_rules` output keeps the attribute names it returned before, but it is now built from the module inputs and the resource IDs, so it no longer includes the `timeouts` attribute.
