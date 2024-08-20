#creation des groupes AAD

resource "azuread_group" "appdevs" {
  display_name     = var.aks_admin_group
 # security_enabled = true
}
resource "azuread_group" "aksops" {
  display_name     = var.aks_user_group
 # security_enabled = true     #L'attribut security_enabled dans la ressource azuread_group détermine 
                              # si le groupe Azure Active Directory (AAD) est un groupe de sécurité ou non.
}


#extraction des Id des groupes crées
output "appdev_object_id" {
  value = azuread_group.appdevs.id
}

output "aksops_object_id" {
  value = azuread_group.aksops.id
}