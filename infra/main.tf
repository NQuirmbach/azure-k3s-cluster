terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend"
    storage_account_name = "tfbackend1727941381"
    container_name       = "tfstate"
    key                  = "k3scluster.tfstate"
    use_oidc             = true
  }
}

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
