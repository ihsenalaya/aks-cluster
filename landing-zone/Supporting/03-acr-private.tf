
# resource "random_integer" "deployment" {
#   min = 10000
#   max = 99999
# }
# 1-creation de acr
 resource "azurerm_container_registry" "acr" {
  name                = "acr${random_integer.deployment.result}"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  sku                 = "Premium"
  admin_enabled       = false
  public_network_access_enabled = false
  anonymous_pull_enabled = false


  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}

# 2-creation de private endpoint pour acr

resource "azurerm_private_endpoint" "acr-endpoint" {
  name                = "acr${random_integer.deployment.result}-to-aks"
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  subnet_id           = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id # subnet de aks

  private_service_connection {
    name                           = "acr${random_integer.deployment.result}-privateserviceconnection"
    private_connection_resource_id = azurerm_container_registry.acr.id     # id de acr (service connection)  L'ID de la ressource Azure à laquelle le Private Endpoint se connectera
    is_manual_connection           = false
     subresource_names              = ["registry"]
  }
  private_dns_zone_group {       # Une liste contenant l'ID de la zone DNS privée associée.
    name                 = "acr-endpoint-zone"
    private_dns_zone_ids = [data.terraform_remote_state.existing-lz.outputs.acr_private_zone_id]
  }
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "custom_dns_configs" {
    value = azurerm_private_endpoint.acr-endpoint.custom_dns_configs
}