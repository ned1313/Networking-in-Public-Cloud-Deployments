#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  type = string
}

variable "naming_prefix" {
  type    = string
  default = "pcd"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vm_count" {
  type    = number
  default = 1
}

variable "vnet_cidr_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "subnet_names" {
  type    = list(string)
  default = ["web", "database"]
}

locals {
  prefix = "${terraform.workspace}-${var.naming_prefix}"
}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  version = "~> 1.0"
}

#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_resource_group" "web" {
  name     = "${local.prefix}-web"
  location = var.location
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  vnet_name           = azurerm_resource_group.web.name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    environment = terraform.workspace

  }
}

resource "azurerm_availability_set" "web" {
  name                = "${local.prefix}-aset"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  managed             = true

  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_public_ip" "web" {
  count               = var.vm_count
  name                = "${local.prefix}-${count.index}-pip"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "web" {
  count                     = var.vm_count
  name                      = "${local.prefix}-${count.index}-nic"
  location                  = azurerm_resource_group.web.location
  resource_group_name       = azurerm_resource_group.web.name
  network_security_group_id = azurerm_network_security_group.web.id

  ip_configuration {
    name                          = "config1"
    subnet_id                     = module.vnet-main.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web[count.index].id
  }
}

resource "azurerm_network_security_group" "web" {
  name                = "web-servers"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_virtual_machine" "web" {
  count                 = var.vm_count
  name                  = "${local.prefix}-${count.index}"
  location              = azurerm_resource_group.web.location
  resource_group_name   = azurerm_resource_group.web.name
  network_interface_ids = [azurerm_network_interface.web[count.index].id]
  availability_set_id   = azurerm_availability_set.web.id
  vm_size               = "Standard_D2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${local.prefix}${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.naming_prefix}${count.index}vm"
    admin_username = "tfadmin"
    admin_password = "ggrz@BSc9sQrMQHh"
    custom_data    = file("cloud-init.txt")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = terraform.workspace
  }


}

#############################################################################
# OUTPUTS
#############################################################################

output "public_ips" {
  value = azurerm_public_ip.web[*].ip_address
}