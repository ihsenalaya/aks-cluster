# creation de key vault
resource "azurerm_key_vault" "key-vault" {
  name                        = "kv${random_integer.deployment.result}-${var.prefix}"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  enabled_for_disk_encryption = true   #specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 60
  purge_protection_enabled    = false   # empêche la suppression définitive (purge) des secrets, clés, ou certificats dans le Key Vault
  public_network_access_enabled = false
  sku_name = "standard"

  # access_policy {
  #   tenant_id = data.azurerm_client_config.current.tenant_id
  #   object_id = data.azurerm_client_config.current.object_id

  #   key_permissions = [  #List of secret permissions
  #     "Get",
  #   ]

  #   secret_permissions = [
  #     "Get",
  #   ]

  #   storage_permissions = [ # List of storage permissions
  #     "Get",
  #   ]
  # }
  network_acls {
    bypass         = "AzureServices"   # Ce paramètre spécifie quelles sources de trafic peuvent contourner (bypasser) les règles de réseau définies.
    # les services Azure approuvés (comme Azure Backup, Azure DevOps, etc.) sont autorisés à contourner les restrictions de réseau. Même si l'accès au Key Vault est restreint par les règles réseau, ces services spécifiques auront toujours accès.
    default_action = "Deny" #toutes les tentatives d'accès au Key Vault seront refusées, sauf si elles proviennent d'une source explicitement autorisée ou si elles sont contournées par le paramètre bypass
  }
}

# creation de private endpoint pour azure keyvault

resource "azurerm_private_endpoint" "kv-endpoint" {
  name                = "kv${random_integer.deployment.result}-${var.prefix}-endpoint"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  subnet_id           = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id  

  private_service_connection {
    name                           = "kv${random_integer.deployment.result}-${var.prefix}-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.key-vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-endpoint-zone"
    private_dns_zone_ids = [data.terraform_remote_state.existing-lz.outputs.kv_private_zone_id]
  }
}

output "kv_id" {
    value = azurerm_key_vault.key-vault.id
}

output "key_vault_url" {
  value       = azurerm_key_vault.key-vault.vault_uri
}