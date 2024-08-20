resource "azurerm_public_ip" "firewall" {
  name                = "${azurerm_virtual_network.vnet.name}-firewall-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "hub-firewall" {
  name                = "${azurerm_virtual_network.vnet.name}-firewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_policy" "aks" {
  name                = "AKSpolicy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

output "fw_policy_id" {
  value = azurerm_firewall_policy.aks.id
}

output "fw_ip_address" {
  value = azurerm_firewall.hub-firewall.ip_configuration
}
resource "azurerm_firewall_policy_rule_collection_group" "AKS" {
  name               = "AKS-rcg"
  firewall_policy_id = azurerm_firewall_policy.aks.id
  priority           = 200
  application_rule_collection {
    name     = "aks-app-rule"
    priority = 205
    action   = "Allow"
    rule {
      name = "app_rule_collection1_rule1"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.1.0.0/16"]
      destination_fqdn_tags =  ["AzureKubnernetesService"]
    }
  }

  network_rule_collection {
    name     = "aks_network_rules"
    priority = 201
    action   = "Allow"
    rule {
      name                  = "https"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["443"]
    }
    rule {
      name                  = "dns"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }
    rule {
      name                  = "time"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
    rule {
      name                  = "tunnel_udp"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["1194"]
    }
    rule {
      name                  = "tunnel_tcp"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["9000"]
    }
  }

}