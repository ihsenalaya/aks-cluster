#resource-groupe pour le hub
resource "azurerm_resource_group" "rg" {
  name     = "${var.hub_prefix}-HUB"
  location = var.location
}

# outputs extrait de creation de rg

output "hub_rg_location" {
 value =  azurerm_resource_group.rg.location
}

output "hub_rg_name" {
  value = azurerm_resource_group.rg.name
}