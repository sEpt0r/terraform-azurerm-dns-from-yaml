# Azure DNS Zone from YAML

This Terraform module creates Azure DNS zones and all record types from YAML configuration files or Terraform variables. It provides a declarative way to manage DNS records with support for all Azure DNS record types including A, AAAA, CAA, CNAME, MX, NS, PTR, SOA, SRV, and TXT records.

## Features

- **Complete DNS Record Support**: All 10 Azure DNS record types (A, AAAA, CAA, CNAME, MX, NS, PTR, SOA, SRV, TXT)
- **YAML Configuration**: Define DNS records in human-readable YAML files
- **Per-Record Tagging**: Apply Azure tags at individual record level
- **Flexible TTL**: Custom TTL per record with sensible defaults
- **Zone Delegation**: Automatic NS record creation for subdomain delegation
- **Multiple Input Methods**: YAML files or Terraform variables
- **Production Ready**: Comprehensive validation and error handling

## Quick Start

```hcl
module "dns_zone" {
  source = "sEpt0r/dns-from-yaml/azurerm"

  resource_group_name = "my-dns-rg"
  zone_name           = "example.com"
  dns_records         = yamldecode(file("zones/example.com.yaml"))
}
```

## Usage Methods

The module supports two primary usage patterns:

### 1. Using YAML Files

Create YAML files with DNS zone configurations. The filename determines the DNS zone name (e.g., `example.com.yaml` creates `example.com` zone).

**Example YAML Structure:**
```yaml
# Zone apex records (use "@" for root domain)
"@":
  A:
    records:
      - 203.0.113.1
      - 203.0.113.2
    ttl: 300
    tags:
      environment: production
  MX:
    records:
      - exchange: mail.example.com
        preference: 10
  TXT:
    records:
      - "v=spf1 a mx ~all"
      - "google-site-verification=abc123"

# Subdomain records
www:
  CNAME:
    record: example.com

# Additional records
api:
  A:
    records:
      - 203.0.113.3
      - 203.0.113.4
```

See the `example/zones` folder for a complete example with all the supported record types.

**Terraform Configuration:**

```hcl
variable "zone_files" {
  type        = list(string)
  description = "List of DNS zone YAML files"
  default = [
    "zones/example.com.yaml",
    "zones/app.example.com.yaml"
  ]
}

module "dns_records_from_yaml" {
  source = "sEpt0r/dns-from-yaml/azurerm"

  for_each = {
    for zone_file in var.zone_files :
    zone_file => yamldecode(file(zone_file))
  }

  dns_records         = each.value
  zone_name           = trimsuffix(basename(each.key), ".yaml")
  resource_group_name = var.resource_group_name

  default_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### 2. Using Terraform Variables

Pass DNS records directly as Terraform variables for programmatic generation:

```hcl
variable "dns_records" {
  description = "Object of DNS records to create from variable instead of yaml files"
  default = {
    "example3.com" = {
      "@" = {
        A = {
          records = ["203.0.113.1", "203.0.113.2"]
          ttl     = 300
        }
        MX = {
          records = [{
            exchange   = "mail.example.com"
            preference = 10
          }]
        }
      }
      www = {
        CNAME = {
          record = "example.com"
        }
      }
    }
  }
}

module "dns_records_from_var" {
    source = "sEpt0r/dns-from-yaml/azurerm"

    for_each = var.dns_records

    dns_records         = each.value
    zone_name           = each.key
    resource_group_name = var.resource_group_name
}
```

## Advanced Usage

### Zone Delegation

Automatically create NS records in a parent zone for subdomain delegation:

```hcl
module "subdomain_zone" {
  source = "sEpt0r/dns-from-yaml/azurerm"

  zone_name           = "api.example.com"
  parent_zone         = "example.com"  # Creates NS records in parent
  resource_group_name = "my-dns-rg"
  dns_records         = yamldecode(file("zones/api.example.com.yaml"))
}
```

### Custom TTL and Tagging

```hcl
module "dns_zone" {
  source = "sEpt0r/dns-from-yaml/azurerm"

  zone_name           = "example.com"
  resource_group_name = "my-dns-rg"
  dns_records         = yamldecode(file("zones/example.com.yaml"))

  # Override default TTL values
  default_ttl = {
    A     = 600    # 10 minutes
    CNAME = 7200   # 2 hours
    MX    = 86400  # 24 hours
  }

  # Apply tags to all DNS resources
  default_tags = {
    Environment = "production"
    Project     = "web-infrastructure"
    ManagedBy   = "terraform"
  }
}
```

## Supported DNS Record Types

This module supports all Azure DNS record types with their respective configurations:

### A Records
```yaml
subdomain:
  A:
    records: ["203.0.113.1", "203.0.113.2"]
    ttl: 300  # optional here and all below examples
    tags:     # optional
      key: value
```

### AAAA Records (IPv6)
```yaml
subdomain:
  AAAA:
    records: ["2001:db8::1", "2001:db8::2"]
    ttl: 300
```

### CNAME Records
```yaml
www:
  CNAME:
    record: "example.com"  # single target
    ttl: 3600
```

### MX Records
```yaml
"@":
  MX:
    records:
      - exchange: "mail1.example.com"
        preference: 10
      - exchange: "mail2.example.com"
        preference: 20
    ttl: 3600
```

### TXT Records
```yaml
"@":
  TXT:
    records:
      - "v=spf1 a mx ~all"
      - "google-site-verification=abc123"
    ttl: 300
```

### SRV Records
```yaml
_service._tcp:
  SRV:
    records:
      - priority: 10
        weight: 5
        port: 443
        target: "server1.example.com"
    ttl: 3600
```

### CAA Records (Certificate Authority Authorization)
```yaml
"@":
  CAA:
    records:
      - flags: 0
        tag: "issue"
        value: "letsencrypt.org"
      - flags: 0
        tag: "iodef"
        value: "mailto:security@example.com"
    ttl: 3600
```

### NS Records
```yaml
subdomain:
  NS:
    records: ["ns1.example.com", "ns2.example.com"]
    ttl: 3600
```

### PTR Records (Reverse DNS)
```yaml
"1":
  PTR:
    records: ["server1.example.com"]
    ttl: 3600
```

### SOA Records (Start of Authority)
```yaml
"@":
  SOA:
    email: "admin.example.com"
    host_name: "ns1.example.com"
    expire_time: 2419200
    minimum_ttl: 300
    refresh_time: 3600
    retry_time: 300
    serial_number: 1
    ttl: 3600
```

> [!NOTE]
> See `example/zones/example.com.yaml` for a complete working example with all record types.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_dns_a_record.a](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_aaaa_record.aaaa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_aaaa_record) | resource |
| [azurerm_dns_caa_record.caa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_caa_record) | resource |
| [azurerm_dns_cname_record.cname](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_mx_record.mx](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_mx_record) | resource |
| [azurerm_dns_ns_record.delegate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_ns_record) | resource |
| [azurerm_dns_ns_record.ns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_ns_record) | resource |
| [azurerm_dns_ptr_record.ptr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_ptr_record) | resource |
| [azurerm_dns_srv_record.srv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_srv_record) | resource |
| [azurerm_dns_txt_record.txt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags for DNS records | `map(string)` | `{}` | no |
| <a name="input_default_ttl"></a> [default\_ttl](#input\_default\_ttl) | Default TTL for DNS records | `map(number)` | <pre>{<br/>  "A": 300,<br/>  "AAAA": 300,<br/>  "CAA": 300,<br/>  "CNAME": 300,<br/>  "MX": 3600,<br/>  "NS": 3600,<br/>  "PTR": 3600,<br/>  "SRV": 3600,<br/>  "TXT": 300<br/>}</pre> | no |
| <a name="input_dns_records"></a> [dns\_records](#input\_dns\_records) | DNS records data | <pre>map(<br/>    object(<br/>      {<br/>        A = optional(object({<br/>          records = list(string)<br/>          ttl     = optional(number)<br/>          tags    = optional(map(string))<br/>        })),<br/>        AAAA = optional(object({<br/>          records = list(string)<br/>          ttl     = optional(number)<br/>          tags    = optional(map(string))<br/>        })),<br/>        CAA = optional(object({<br/>          records = list(object({<br/>            flags = number<br/>            tag   = string<br/>            value = string<br/>          }))<br/>          ttl  = optional(number)<br/>          tags = optional(map(string))<br/>        })),<br/>        CNAME = optional(object({<br/>          record = string<br/>          ttl    = optional(number)<br/>          tags   = optional(map(string))<br/>        })),<br/>        MX = optional(object({<br/>          records = list(object({<br/>            exchange   = string<br/>            preference = number<br/>          }))<br/>          ttl  = optional(number)<br/>          tags = optional(map(string))<br/>        })),<br/>        NS = optional(object({<br/>          records = list(string)<br/>          ttl     = optional(number)<br/>          tags    = optional(map(string))<br/>        })),<br/>        PTR = optional(object({<br/>          records = list(string)<br/>          ttl     = optional(number)<br/>          tags    = optional(map(string))<br/>        })),<br/>        SOA = optional(object({<br/>          email         = string<br/>          host_name     = optional(string)<br/>          expire_time   = optional(number)<br/>          minimum_ttl   = optional(number)<br/>          refresh_time  = optional(number)<br/>          retry_time    = optional(number)<br/>          serial_number = optional(number)<br/>          ttl           = optional(number)<br/>          tags          = optional(map(string))<br/>        })),<br/>        SRV = optional(object({<br/>          records = list(object({<br/>            port     = number<br/>            priority = number<br/>            target   = string<br/>            weight   = number<br/>          }))<br/>          ttl  = optional(number)<br/>          tags = optional(map(string))<br/>        })),<br/>        TXT = optional(object({<br/>          records = list(string)<br/>          ttl     = optional(number)<br/>          tags    = optional(map(string))<br/>        }))<br/>      }<br/>    )<br/>  )</pre> | `{}` | no |
| <a name="input_parent_zone"></a> [parent\_zone](#input\_parent\_zone) | Parent DNS zone name to create NS records for delegation | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group Name | `string` | n/a | yes |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | DNS zone name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_zone"></a> [dns\_zone](#output\_dns\_zone) | DNS zone information including ID and name |
<!-- END_TF_DOCS -->

## Examples

Complete examples are available in the [`example/`](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/tree/main/example) directory:

- **[Basic YAML Usage](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/tree/main/example/main.tf)**: Creating zones from YAML files
- **[Variable Usage](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/tree/main/example/main.tf)**: Creating zones from Terraform variables
- **[Complete Record Types](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/tree/main/example/zones/example.com.yaml)**: All supported DNS record types
- **[Subdomain Example](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/tree/main/example/zones/sub.example.com.yaml)**: Subdomain configuration

## Validation and Best Practices

### DNS Record Validation
- **CNAME Restrictions**: Cannot coexist with other record types for the same name
- **Zone Apex**: CNAME records cannot be created at zone apex (`@`)
- **TTL Limits**: Valid range is 1 to 2,147,483,647 seconds
- **Azure DNS Record Limits**: Maximum 20 records per record set (except TXT: 400). If you need to increase these [limits](https://learn.microsoft.com/en-us/azure/dns/dns-zones-records#limits), contact [Azure Support](https://azure.microsoft.com/en-us/support/).

### YAML Best Practices
```yaml
# Use quotes for zone apex
"@":
  # Use descriptive comments
  TXT:
    records:
      - "v=spf1 a mx ~all"  # SPF record

# Use consistent indentation (2 spaces)
www:
  A:
    records:
      - 203.0.113.1
    ttl: 300
    tags:
      Environment: production
```

### Security Considerations
- Store YAML files in version control for audit trail
- Use least-privilege Azure RBAC for DNS management
- Regularly review CAA records for certificate authority restrictions
- Implement proper SPF/DKIM/DMARC records for email security

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/blob/main/LICENSE) file for details.

## Issues

- 🐛 [Report Issues](https://github.com/sEpt0r/terraform-azurerm-dns-from-yaml/issues)
