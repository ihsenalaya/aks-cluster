locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "agw" {
  name                = var.appgw_name
  resource_group_name = azurerm_resource_group.spoke-rg.name
  location            = var.location
  depends_on = [ azurerm_network_security_group.appgw-nsg ]

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {      #ce bloc configure où et comment une passerelle obtient une adresse IP dans Azure
    name      = "app-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id   # Indique le sous-réseau auquel la passerelle sera associée. La passerelle obtiendra une adresse IP de ce sous-réseau.
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  # frontend_port {
  #   name     = "https-443"
  #   port     = 443
  #   protocol = "Https"
  # }

  frontend_ip_configuration {          # adress ip du frontend generalement c'est ip publique
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }
   /*
   # Le bloc backend_http_settings configure comment l'Application Gateway interagit avec les serveurs backend,
    y compris la gestion des sessions, les chemins d'URL, les ports et les protocoles utilisés pour
     les communications HTTP. Cela permet d'ajuster le comportement de la passerelle pour répondre aux 
     besoins spécifiques de l'application ou du service.
     */
  backend_http_settings {      
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1 //priority arguement required as of 3.6.0 release. 1 is the highest priority and 20000 is the lowest priority.
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection" # "Prevention" or "Detection"
    rule_set_type    = "OWASP"     # "OWASP" or "Microsoft_BotManagerRuleSet"
    rule_set_version = "3.2"
  }
}

output "gateway_name" {
  value = azurerm_application_gateway.agw.name
}

output "gateway_id" {
  value = azurerm_application_gateway.agw.id
}