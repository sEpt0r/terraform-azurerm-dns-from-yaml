resource "azurerm_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.default_tags

  dynamic "soa_record" {
    for_each = {
      for subdomain, entries in var.dns_records :
      subdomain => entries
      if subdomain == "@" && entries.SOA != null
    }

    content {
      email         = soa_record.value.SOA.email
      host_name     = soa_record.value.SOA.host_name
      expire_time   = soa_record.value.SOA.expire_time
      minimum_ttl   = soa_record.value.SOA.minimum_ttl
      refresh_time  = soa_record.value.SOA.refresh_time
      retry_time    = soa_record.value.SOA.retry_time
      serial_number = soa_record.value.SOA.serial_number
      ttl           = soa_record.value.SOA.ttl != null ? soa_record.value.SOA.ttl : var.default_ttl["SOA"]
      tags          = soa_record.value.SOA.tags != null ? soa_record.value.SOA.tags : var.default_tags
    }
  }
}

resource "azurerm_dns_ns_record" "delegate" {
  count = var.parent_zone != null ? 1 : 0

  name                = replace(var.zone_name, ".${var.parent_zone}", "")
  zone_name           = var.parent_zone
  resource_group_name = var.resource_group_name
  ttl                 = var.default_ttl["NS"]
  records             = azurerm_dns_zone.this.name_servers
  tags                = var.default_tags
}

resource "azurerm_dns_a_record" "a" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.A != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.A.ttl != null ? each.value.A.ttl : var.default_ttl["A"]
  records             = each.value.A.records
  tags                = each.value.A.tags != null ? each.value.A.tags : var.default_tags
}

resource "azurerm_dns_aaaa_record" "aaaa" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.AAAA != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.AAAA.ttl != null ? each.value.AAAA.ttl : var.default_ttl["AAAA"]
  records             = each.value.AAAA.records
  tags                = each.value.AAAA.tags != null ? each.value.AAAA.tags : var.default_tags
}

resource "azurerm_dns_caa_record" "caa" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.CAA != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.CAA.ttl != null ? each.value.CAA.ttl : var.default_ttl["CAA"]
  tags                = each.value.CAA.tags != null ? each.value.CAA.tags : var.default_tags

  dynamic "record" {
    for_each = each.value.CAA.records

    content {
      flags = record.value.flags
      tag   = record.value.tag
      value = record.value.value
    }
  }
}

resource "azurerm_dns_cname_record" "cname" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.CNAME != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.CNAME.ttl != null ? each.value.CNAME.ttl : var.default_ttl["CNAME"]
  record              = each.value.CNAME.record
  tags                = each.value.CNAME.tags != null ? each.value.CNAME.tags : var.default_tags
}

resource "azurerm_dns_mx_record" "mx" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.MX != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.MX.ttl != null ? each.value.MX.ttl : var.default_ttl["MX"]
  tags                = each.value.MX.tags != null ? each.value.MX.tags : var.default_tags

  dynamic "record" {
    for_each = each.value.MX.records

    content {
      exchange   = record.value.exchange
      preference = record.value.preference
    }
  }
}

resource "azurerm_dns_ns_record" "ns" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.NS != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.NS.ttl != null ? each.value.NS.ttl : var.default_ttl["NS"]
  records             = each.value.NS.records
  tags                = each.value.NS.tags != null ? each.value.NS.tags : var.default_tags
}

resource "azurerm_dns_ptr_record" "ptr" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.PTR != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.PTR.ttl != null ? each.value.PTR.ttl : var.default_ttl["PTR"]
  records             = each.value.PTR.records
  tags                = each.value.PTR.tags != null ? each.value.PTR.tags : var.default_tags
}

resource "azurerm_dns_srv_record" "srv" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.SRV != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.SRV.ttl != null ? each.value.SRV.ttl : var.default_ttl["SRV"]
  tags                = each.value.SRV.tags != null ? each.value.SRV.tags : var.default_tags

  dynamic "record" {
    for_each = each.value.SRV.records

    content {
      port     = record.value.port
      priority = record.value.priority
      target   = record.value.target
      weight   = record.value.weight
    }
  }
}

resource "azurerm_dns_txt_record" "txt" {
  for_each = {
    for subdomain, entries in var.dns_records :
    subdomain => entries
    if entries.TXT != null
  }

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.TXT.ttl != null ? each.value.TXT.ttl : var.default_ttl["TXT"]
  tags                = each.value.TXT.tags != null ? each.value.TXT.tags : var.default_tags

  dynamic "record" {
    for_each = each.value.TXT.records

    content {
      value = record.value
    }
  }
}
