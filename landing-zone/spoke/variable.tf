variable "spoke_prefix" {
  default = "escs-lz01"
}

variable "tags" {
  type = map(string)

  default = {
    project = "spoke-lz"
  }
}

variable "location" {
  default = "eastus"
}

# Used to retrieve outputs from other state files.
# The "access_key" variable is sensitive and should be passed using
# a .TFVARS file or other secure method.

variable "state_sa_name" {
  default = "hub-net"
}

variable "container_name" {
  default = "akscs"
}

# Storage Account Access Key
variable "access_key" {}

# variables pour appgw

variable "appgw_name" {
  default = "lzappgw-blue"
}
