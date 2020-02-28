# Basic provider for Azure

provider "azurerm" {}

# Azure provider with versioning and alias

provider "azurerm" {
    version = "~>1.0"

    alias = "security"
}

