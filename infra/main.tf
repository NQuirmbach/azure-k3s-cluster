provider "azurerm" {
  features {}
}

locals {
  tags = {
    env = var.enviroment
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.enviroment}"
  location = var.location
  tags     = local.tags
}
