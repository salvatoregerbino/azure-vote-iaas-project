terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}
locals {
  ssh_public_key = " AAAAB3NzaC1yc2EAAAADAQABAAACAQDKVwbssyo8XpKI8An8N709C3KScDZOgLYTeHyt1z2gsooCt63TqHYPd/0BLhzxCcmi9bfVoaG2PnNfQQiUVt5McZQkAm3abyTF0lpg7Q+3zfQgZt2/JVSkvyqS9HsCc+lyn2An+M5MmcWRKN6Mk+NeEVDPv4Z7NtBKL4rMCFb5SRrLY0eyBzS7TahMo4JfwAarF9WaJydGWqo0HPyCEU5WWY50Kjnj5COxGM2h6BE7mb0hmYNo6gMBIQrpnTupYQomx/4KfcJN6qTDt0NApBeG6TJtAG7UVWoHZ7xvFb1OR/ws8bS7gdVKOPsS3OV+vjD44fEFdqpqVnNiU5z4tZ0HI25FLVDEgcuAZ4Geibw6gqlqAM0q9zXmq/EEdOGj6jl8E6w6XSahwz7ZB2lbly6y3JEVK8RAQKwNwagwFPeykgE8NzccNonXH9s8rCGMTgQ8D87+jw3IE0pDpkIJRkOfcRInYMVUl2OquQjMshsXTthNLWP/dsatWTO8/yeer0Moo81erl+3kursJpI7C+kvTAG01LSApfJPiqxxTdugUBDUTQ1vPT3F0tuJhj/cyoFm7HVW46EIN7CGrg9zWzdXqbwTV5A5fRa4FOnmNrdtDXvx+0vv4ZS3BfL0ejR3CjcLQF/scNJIiyDhvSryNA5IVwfngiHRUGd92sqaOS8XIQ== salvatore@LAPTOP-BOO3FVF2"
}


resource "azurerm_resource_group" "rg" {
  name     = "azure-vote-iaas-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "azure-vote-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "redis_subnet" {
  name                 = "redis-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "frontend_ip" {
  name                = "frontend-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg_frontend" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "frontend_nic" {
  name                = "frontend-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = "frontend-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.frontend_nic.id,
  ]

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

  custom_data = filebase64("cloud-init.yaml")

  admin_ssh_key {
    username   = "azureuser"
    public_key = local.ssh_public_key
  }
}

resource "azurerm_network_interface" "redis_nic" {
  name                = "redis-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.redis_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "redis_vm" {
  name                = "redis-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.redis_nic.id,
  ]

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

  admin_ssh_key {
    username   = "azureuser"
    public_key = local.ssh_public_key
  }
}