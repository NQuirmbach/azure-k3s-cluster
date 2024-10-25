resource "azurerm_linux_virtual_machine_scale_set" "master_nodes" {
  name                = "k3sclustermasternodes${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = var.cluster_master_node_sku
  instances           = var.cluster_master_node_count
  admin_username      = var.cluster_admin_username

  admin_ssh_key {
    username   = var.cluster_admin_username
    public_key = var.cluster_node_ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "k3sclustermaternic${local.suffix}"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.cluster-subnet.id
      primary   = true
    }
  }

  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}
