# MSI for Kubernetes Cluster (Control Plane)
# This ID is used by the AKS control plane to create or act on other resources in Azure.
# It is referenced in the "identity" block in the azurerm_kubernetes_cluster resource.
# Based on the structure of the aks_clusters map is created an identity per each AKS Cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_user_assigned_identity" "mi-aks-cp" {  # required pour l'utilisation de dns private zone 
  # for_each            = { for aks_clusters in local.aks_clusters : aks_clusters.name_prefix => aks_clusters if aks_clusters.aks_turn_on == true }
  name                = "mi-${var.prefix}-aks-cluster-cp"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
}

# Role Assignments for Control Plane MSI
# Based on the structure of the aks_clusters map is defined the role assignment per each AKS Cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks-to-rt" {
 # for_each             = azurerm_user_assigned_identity.mi-aks-cp
  scope                = data.terraform_remote_state.existing-lz.outputs.lz_rt_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id
}
/*The cluster identity used by the AKS cluster must have at least Network Contributor permissions
 on the subnet within your virtual network. If you wish to define a 
custom role instead of using the built-in Network Contributor role, the following permissions are required
*/
resource "azurerm_role_assignment" "aks-to-vnet" { 
 # for_each             = azurerm_user_assigned_identity.mi-aks-cp
  scope                = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id

}

# Role assignment to to create Private DNS zone for cluster
# Based on the structure of the aks_clusters map is defined the role assignment per each AKS Cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks-to-dnszone" {
 # for_each             = azurerm_user_assigned_identity.mi-aks-cp
  scope                = azurerm_private_dns_zone.aks-dns.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id
}

# The AKS cluster. 
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "appdevs_user" {
 # for_each             = module.aks
  scope                = azurerm_kubernetes_cluster.akscluster.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = data.terraform_remote_state.aad.outputs.appdev_object_id
}

resource "azurerm_role_assignment" "aksops_admin" {
 # for_each             = module.aks
  scope                = azurerm_kubernetes_cluster.akscluster.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.terraform_remote_state.aad.outputs.aksops_object_id
}

# This role assigned grants the current user running the deployment admin rights
# to the cluster. In production, you should use just the EID groups (above).
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks_rbac_admin" {
 # for_each             = module.aks
  scope                = azurerm_kubernetes_cluster.akscluster.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id

}

# Role Assignment to Azure Container Registry from AKS Cluster
# This must be granted after the cluster is created in order to use the kubelet identity.
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_role_assignment" "aks-to-acr" {
 # for_each             = module.aks
  scope                = data.terraform_remote_state.aks-support.outputs.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.akscluster.kubelet_identity.0.object_id
}

# Role Assignments for AGIC on AppGW
# This must be granted after the cluster is created in order to use the ingress identity.
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_role_assignment" "agic_appgw" {
 # for_each             = module.aks
  scope                = data.terraform_remote_state.existing-lz.outputs.gateway_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.akscluster.ingress_application_gateway.0.ingress_application_gateway_identity.0.object_id
}


/*With kubenet, only the nodes receive an IP address in the virtual network subnet. Pods can't communicate 
directly with each other. Instead, User Defined Routing (UDR) and IP forwarding handle connectivity 
between pods across nodes. UDRs and IP forwarding configuration is created and maintained by the AKS 
service by default, but you can bring your own route table for custom route management if you want. 
You can also deploy pods behind a service that receives an assigned IP address and load balances traffic
 for the application. The following diagram shows how the AKS nodes receive an IP address in the virtual 
 network subnet, but not the pods
 */
 