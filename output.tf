output "dns_zone" {
  description = "DNS zone information including ID, name, and name servers"
  value = {
    id           = azurerm_dns_zone.this.id
    name         = azurerm_dns_zone.this.name
    name_servers = azurerm_dns_zone.this.name_servers
  }
}

output "dns_zone_id" {
  description = "The ID of the DNS zone"
  value       = azurerm_dns_zone.this.id
}

output "dns_zone_name" {
  description = "The name of the DNS zone"
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "List of name servers for the DNS zone"
  value       = azurerm_dns_zone.this.name_servers
}
