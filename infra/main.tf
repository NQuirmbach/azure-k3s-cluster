provider "azurerm" {
  features {}
}

locals {
  enviroment = terraform.workspace
  tags = {
    env = var.enviroment
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${terraform.workspace}"
  location = var.location
  tags     = local.tags
}
