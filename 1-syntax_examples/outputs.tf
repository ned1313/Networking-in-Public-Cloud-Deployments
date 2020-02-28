output "resource_group_name" {
  value = azurerm_resource_group.setup.name
}

output "subnet_cidr" {
  value = data.template_file.subnet_prefixes.rendered
}