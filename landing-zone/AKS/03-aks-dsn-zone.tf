# Deploy DNS Private Zone for AKS
resource "azurerm_private_dns_zone" "aks-dns" {
  name                = var.private_dns_zone_name
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_aks" {
  name                  = "hub-to-aks"
  resource_group_name   = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.aks-dns.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
}

output "aks_private_zone_id" {
  value = azurerm_private_dns_zone.aks-dns.id
}
output "aks_private_zone_name" {
  value = azurerm_private_dns_zone.aks-dns.name
}

resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  route_table_id = data.terraform_remote_state.existing-lz.outputs.lz_rt_id
  depends_on = [ azurerm_kubernetes_cluster.akscluster ]
}
