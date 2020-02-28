#############################################################################
# VARIABLES
#############################################################################

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "naming_prefix" {
  type    = string
  default = "pcd"
}

variable "jenkins_object_id" {
  type = string
}

##################################################################################
# PROVIDERS
##################################################################################

provider "azurerm" {
  version = "~> 1.0"
}

##################################################################################
# RESOURCES
##################################################################################
resource "random_integer" "sa_num" {
  min = 10000
  max = 99999
}


resource "azurerm_resource_group" "setup" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = "${lower(var.naming_prefix)}${random_integer.sa_num.result}"
  resource_group_name      = azurerm_resource_group.setup.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_storage_container" "ct" {
  name                 = "terraform-state"
  storage_account_name = azurerm_storage_account.sa.name

}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "jenkins" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = var.jenkins_object_id
}



resource "local_file" "backend_config" {
    content = <<EOF
resource_group_name = "${azurerm_resource_group.setup.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name = "terraform-state"
key = "terraform.tfstate"
use_msi = true
EOF
    filename = "${path.module}/backend-config.txt"
}

##################################################################################
# OUTPUT
##################################################################################

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "resource_group_name" {
  value = azurerm_resource_group.setup.name
}