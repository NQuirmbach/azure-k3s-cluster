terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend"
    storage_account_name = "tfbackend1727941381"
    container_name       = "tfstate"
    key                  = "k3scluster.tfstate"
  }
}

provider "azurerm" {
  features {}
}
provider "random" {
}


resource "random_integer" "rid" {
  min = 1000
  max = 9999
}

locals {
  enviroment = terraform.workspace
  suffix     = random_integer.rid.result
  tags = {
    env = terraform.workspace
    app = "k3s-cluster"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${terraform.workspace}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "k3sclustervnet-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}
