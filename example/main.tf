# Example usage of the module with records from a yaml file
module "dns_records_from_yaml" {
  source = "../../terraform-azurerm-dns-from-yaml"

  for_each = { for zone_file in var.zone_files : zone_file => yamldecode(file(zone_file)) }

  dns_records         = each.value
  zone_name           = trimsuffix(basename(each.key), ".yaml")
  resource_group_name = var.resource_group_name

  default_tags = {
    default_tag1 = "default_value1",
    default_tag2 = "default_value2"
  }
}

# Example usage of the module with records from a variable
module "dns_records_from_var" {
  source = "../../terraform-azurerm-dns-from-yaml"

  for_each = var.dns_records

  dns_records         = each.value
  zone_name           = each.key
  resource_group_name = var.resource_group_name
}
