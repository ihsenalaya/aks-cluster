terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }

}
backend "azurerm" {
    # resource_group_name  = "StorageAccount-ResourceGroup"  # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
    # storage_account_name = "abcd1234"                      # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    # container_name       = "tfstate"                       # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "lz-net"        # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
  }
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
# Configure the Azure Active Directory Provider
provider "azuread" {
}