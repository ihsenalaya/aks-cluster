#spoke to hub peering
resource "azurerm_virtual_network_peering" "direction1" {
  name                      = "${azurerm_virtual_network.vnet.name}-to-${data.terraform_remote_state.existing-hub.outputs.hub_vnet_name}"
  resource_group_name       = azurerm_resource_group.spoke-rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

}

# hub to spoke peering

resource "azurerm_virtual_network_peering" "direction2" {
  name                      = "${data.terraform_remote_state.existing-hub.outputs.hub_vnet_name}-to-${azurerm_virtual_network.vnet.name}"
  resource_group_name       = data.terraform_remote_state.existing-hub.outputs.hub_rg_name   # ressource groupe du vnet local
  virtual_network_name      = data.terraform_remote_state.existing-hub.outputs.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
