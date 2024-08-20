variable "hub_prefix" {
  default = "escs-hub"
}

variable "location" {
  default = "eastus"
}

variable "tags" {
    type = map(string)

  default = {
    project = "cs-aks"
  }
}

# variable "server_name" {
#   default = server-dev-linux
# }

# variable "admin_username" {
#   default = ihsen
# }
# variable "admin_password" {
#   sensitive = true
#   type = string
#   description = "password du jampbox"
#   default = "ihsenAlaya@2024"
# }