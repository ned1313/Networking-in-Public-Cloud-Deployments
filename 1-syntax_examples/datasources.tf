data "template_file" "subnet_prefixes" {
  count = length(var.subnet_names)

  template = "$${cidrsubnet(vnet_cidr,8,current_count)}"

  vars = {
    vnet_cidr     = var.vnet_cidr_range[terraform.workspace]
    current_count = count.index
  }
}