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
  default = ["jenkins", "database"]
}

locals {
  prefix = "${terraform.workspace}-${var.naming_prefix}"
}

#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  version = "~> 1.0"
  use_msi = true
}

#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_resource_group" "jenkins" {
  name     = "${local.prefix}-jenkins"
  location = var.location
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.jenkins.name
  location            = azurerm_resource_group.jenkins.location
  vnet_name           = azurerm_resource_group.jenkins.name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    environment = terraform.workspace

  }
}


#############################################################################
# OUTPUTS
#############################################################################
