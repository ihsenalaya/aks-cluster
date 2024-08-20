# subnet et nsg pour aks
# subnet pour aks

resource "azurerm_subnet" "aks" {
  name                 = "aksSubnet"
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.16.0/20"]
  #private_endpoint_network_policies = Enabled
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

resource "azurerm_network_security_group" "aks-nsg" {
  name                = "${azurerm_virtual_network.vnet.name}-${azurerm_subnet.aks.name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
}


resource "azurerm_subnet_network_security_group_association" "aks-subnet" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks-nsg.id
}
# # Associate Route Table to AKS Subnet
# # Lorsque vous associez une table de routage à un sous-réseau à l'aide de azurerm_subnet_route_table_association, toutes les règles de routage définies dans la table de routage 
# #s'appliqueront au trafic entrant et sortant du sous-réseau spécifié.
resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.route_table.id
}


 