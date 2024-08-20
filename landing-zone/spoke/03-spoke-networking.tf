# creation de ressource groupe pour le spoke

resource "azurerm_resource_group" "spoke-rg" {
  name     = "${var.spoke_prefix}-spoke"
  location = data.terraform_remote_state.existing-hub.outputs.hub_rg_location
}

# outputs extrait de creation de rg

output "lz_rg_location" {
 value =  azurerm_resource_group.spoke-rg.location
}

output "lz_rg_name" {
  value = azurerm_resource_group.spoke-rg.name
}

# vnet pour le hub
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.spoke_prefix}"
  location            = azurerm_resource_group.spoke-rg.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = null # list des address ip des serveurs dns
  tags = var.tags
}

output "lz_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
# creartion de table de routage
# Cette table de routage est prête à être utilisée, mais elle n'a pas encore d'effet 
# tant qu'elle n'est pas associée à un sous-réseau.
resource "azurerm_route_table" "route_table" {
  name                          = "${var.spoke_prefix}-rt"
  location                      = azurerm_resource_group.spoke-rg.location
  resource_group_name           = azurerm_resource_group.spoke-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route_to_firewall"
    address_prefix = "0.0.0.0/0"  #0.0.0.0/0 est un préfixe d'adresse spécial qui correspond à tous les adresses IP possibles. Il est souvent utilisé pour définir une route par défaut.
    next_hop_type  = "VirtualAppliance"
    # adress ip du firewall qui reside dans le hub
    next_hop_in_ip_address = data.terraform_remote_state.existing-hub.outputs.fw_ip_address.0.private_ip_address
  }

  tags = var.tags
}

output "lz_rt_id" {
  value = azurerm_route_table.route_table.id 
}


/*Avec Règle Plus Spécifique : Si vous ajoutez une autre règle dans la table de routage pour 10.2.0.0/16
 pointant directement vers un autre sous-réseau ou un routeur, alors le trafic destiné à 10.2.0.0/16 
 ne passera pas par le pare-feu mais suivra cette route plus spécifique.
 Le reste du trafic continuera à suivre la route 0.0.0.0/0.
 */