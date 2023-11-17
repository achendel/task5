resource "azurerm_resource_group" "pt_resources" {
  name     = "pt_resources_akshatha_v2"
  location = "northeurope"
}

resource "azurerm_virtual_network" "pt_virtual_network" {
  name                = "pt_network_akshatha"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.pt_resources.location
  resource_group_name = azurerm_resource_group.pt_resources.name
}

resource "azurerm_subnet" "pt_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.pt_resources.name
  virtual_network_name = azurerm_virtual_network.pt_virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pt_public_ip" {
  name                    = "pt_public_ip_akshatha"
  location                = azurerm_resource_group.pt_resources.location
  resource_group_name     = azurerm_resource_group.pt_resources.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "test"
  }
}


data "azurerm_public_ip" "vm_public_ip" {
  name                = azurerm_public_ip.pt_public_ip.name
  resource_group_name = azurerm_resource_group.pt_resources.name
}

 
resource "azurerm_network_interface" "pt_network_interface" {
  name                = "pt_nic_akshatha"
  location            = azurerm_resource_group.pt_resources.location
  resource_group_name = azurerm_resource_group.pt_resources.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pt_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "pt_linux_vm" {
  name                = "SnipeITServer"
  resource_group_name = azurerm_resource_group.pt_resources.name
  location            = azurerm_resource_group.pt_resources.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  depends_on = [azurerm_public_ip.pt_public_ip]
  custom_data = base64encode(local.data_inputs)

  network_interface_ids = [
    azurerm_network_interface.pt_network_interface.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("sa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "public_ip_address" {
  value = data.azurerm_public_ip.vm_public_ip.ip_address

}