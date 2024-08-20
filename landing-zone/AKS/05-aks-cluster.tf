#create workspace log analytics
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "aks-la-01"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}



# creation de cluster aks

resource "azurerm_kubernetes_cluster" "akscluster" {
  name                = "aks-${var.prefix}-cluster"
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  # a user assigned identity or a service principal must be used when using a custom private dns zone
  private_dns_zone_id = azurerm_private_dns_zone.aks-dns.id  # required dans privet cluster si non y aura jamais de connection vers le cluster
  dns_prefix          = "aks-${var.prefix}-cluster"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  private_cluster_enabled             = true
  azure_policy_enabled                = true
  private_cluster_public_fqdn_enabled = false
  role_based_access_control_enabled = true
  depends_on = [
    azurerm_role_assignment.aks-to-vnet,
    azurerm_role_assignment.aks-to-dnszone,
    azurerm_user_assigned_identity.mi-aks-cp
  ]
  
  azure_active_directory_role_based_access_control {
    managed = true
    //  admin_group_object_ids = talk to Ayo about this one, this arg could reduce code other places possibly 
    azure_rbac_enabled = true
  }
  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
  
  default_node_pool {
    name       = "defaultpool"
    node_count = 1
    vm_size    = "Standard_D2_v2" 
    vnet_subnet_id       = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi-aks-cp.id]
  }

 oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }
network_profile {
    network_plugin     = "azure"
    # outbound_type      = "userDefinedRouting"  pur kubnet
    dns_service_ip     = "192.168.100.10"
    service_cidr       = "192.168.100.0/24"
    docker_bridge_cidr = "172.16.1.1/30"
  }

ingress_application_gateway {
    gateway_id = data.terraform_remote_state.existing-lz.outputs.gateway_id
  }
  tags = {
    Environment = "Production"
  }
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.akscluster.id
}

output "node_pool_rg" {
  value = azurerm_kubernetes_cluster.akscluster.node_resource_group
}

# Managed Identities created for Addons

output "kubelet_id" {
  value = azurerm_kubernetes_cluster.akscluster.kubelet_identity.0.object_id
}

output "agic_id" {
  value = azurerm_kubernetes_cluster.akscluster.ingress_application_gateway.0.ingress_application_gateway_identity.0.object_id
}
