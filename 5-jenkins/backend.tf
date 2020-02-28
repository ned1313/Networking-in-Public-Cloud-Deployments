terraform {
  backend "azurerm" {  
      use_msi = true
      key = "terraform.tfstate"
  }
}