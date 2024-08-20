
#creation de keyvault policy  pour que l'utilisateur current peut grer les secrets ...
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.key-vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = [
    "Get","List", "Set", "Delete"
  ]
}
# # creation de secret pour la database
# resource "azurerm_key_vault_secret" "mongodb" {
#   name         = "MongoDB"
#   value        = var.mongodb_secret
#   key_vault_id = azurerm_key_vault.key-vault.id
#   depends_on = [
#     azurerm_key_vault_access_policy.current
#   ]
# }