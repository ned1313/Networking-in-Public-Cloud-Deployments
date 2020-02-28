# Create a random id - no provider declared

resource "random_integer" "sa_num" {
  min = 10000
  max = 99999
}

# Create an Azure resource group

resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-network"
  location = var.location

  tags = {
    environment = var.environment
  }
}