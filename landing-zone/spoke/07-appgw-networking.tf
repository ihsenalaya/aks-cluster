# subnet et nsg pour aapgw
# subnet pour appgw

resource "azurerm_subnet" "appgw" {
  name                 = "appgwSubnet"
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
  #private_endpoint_network_policies = Enabled
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

resource "azurerm_network_security_group" "appgw-nsg" {
  name                = "${azurerm_virtual_network.vnet.name}-${azurerm_subnet.appgw.name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
}
locals {
  app_inbound_ports_map = {
    "AllowControlPlane" = {
      priority   = "110"
      destination_port_range = "65200-65535"
    },
    "Allow443InBound" = {
      priority   = "100"
      destination_port_range = "443"
    }
    "AllowHealthProbes" = {
      priority   = "120"
      destination_port_range = "*"
    }
  }
}

resource "azurerm_network_security_rule" "app_nsg_rule_inbound" {
  for_each = local.app_inbound_ports_map
  name                        = "Rule-Port-${each.key}"
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke-rg.name
  network_security_group_name = azurerm_network_security_group.appgw-nsg.name
}

resource "azurerm_network_security_rule" "DenyAllInBound" {
  resource_group_name         = azurerm_resource_group.spoke-rg.name
  network_security_group_name = azurerm_network_security_group.appgw-nsg.name
  name                        = "DenyAllInBound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"

}


resource "azurerm_subnet_network_security_group_association" "appgw-subnet" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw-nsg.id
}

# locals {
#   appgws = {
#     "appgw_blue" = {
#       name_prefix   = "blue"
#       appgw_turn_on = true
#     },
#     "appgw_green" = {
#       name_prefix   = "green"
#       appgw_turn_on = false
#     }
#   }
# }
resource "azurerm_public_ip" "appgw" {
  #  for_each            = { for appgws in local.appgws : appgws.name_prefix => appgws if appgws.appgw_turn_on == true } 
  # Pour tout appgws dans local.appgws, si appgw_turn_on est vrai, alors inclure l'objet dans une carte avec name_prefix comme clé. 
  name                = "appgw-pip-blue"
  resource_group_name = azurerm_resource_group.spoke-rg.name
  location            = azurerm_resource_group.spoke-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}



# # # Associate Route Table to AKS Subnet
# # # Lorsque vous associez une table de routage à un sous-réseau à l'aide de azurerm_subnet_route_table_association, toutes les règles de routage définies dans la table de routage 
# # #s'appliqueront au trafic entrant et sortant du sous-réseau spécifié.
# resource "azurerm_subnet_route_table_association" "rt_association" {
#   subnet_id      = azurerm_subnet.aks.id
#   route_table_id = azurerm_route_table.route_table.id
# }


 