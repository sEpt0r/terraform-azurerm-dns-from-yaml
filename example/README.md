# Examples

This directory contains complete examples demonstrating how to use the Azure DNS from this module.

## Quick Start

1. **Set up Azure credentials**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Initialize Terraform**:
   ```bash
   cd example
   terraform init
   ```

3. **Review and customize variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. **Plan and apply**:
   ```bash
   terraform plan
   terraform apply
   ```

## Examples Overview

### 1. YAML-Based DNS Management (`dns_records_from_yaml`)

This example demonstrates creating DNS zones from YAML configuration files:

**Files:**
- [`zones/example.com.yaml`](zones/example.com.yaml) - Complete example with all DNS record types
- [`zones/sub.example.com.yaml`](zones/sub.example.com.yaml) - Subdomain delegation example

**Configuration:**
```hcl
module "dns_records_from_yaml" {
  source = "../"

  for_each = { for zone_file in var.zone_files : zone_file => yamldecode(file(zone_file)) }

  dns_records         = each.value
  zone_name           = trimsuffix(basename(each.key), ".yaml")
  resource_group_name = var.resource_group_name

  default_tags = {
    default_tag1 = "default_value1",
    default_tag2 = "default_value2"
  }
}
```

**Benefits:**
- Human-readable configuration
- Version control friendly
- Easy to review and audit
- Supports all DNS record types

### 2. Variable-Based DNS Management (`dns_records_from_var`)

This example shows programmatic DNS record creation using Terraform variables:

**Configuration:**
```hcl
module "dns_records_from_var" {
  source = "../"

  for_each = var.dns_records

  dns_records         = each.value
  zone_name           = each.key
  resource_group_name = var.resource_group_name
}
```

**Benefits:**
- Programmatic generation
- Dynamic configuration
- Integration with other Terraform resources
- Conditional logic support

## File Structure

```
example/
├── README.md                    # This file
├── main.tf                      # Main module usage examples
├── variables.tf                 # Variable definitions
├── versions.tf                  # Provider configuration
├── terraform.tfvars.example     # Example variable values
└── zones/
    ├── example.com.yaml         # Complete DNS record types example
    └── sub.example.com.yaml     # Subdomain delegation example
```

## YAML Zone File Examples

### Complete Record Types (`zones/example.com.yaml`)

This file demonstrates all supported DNS record types:

- **A Records**: IPv4 address mapping
- **AAAA Records**: IPv6 address mapping
- **CAA Records**: Certificate Authority Authorization
- **CNAME Records**: Canonical name aliases
- **MX Records**: Mail exchange servers
- **NS Records**: Name server delegation
- **PTR Records**: Reverse DNS lookups
- **SOA Records**: Start of Authority (zone apex only)
- **SRV Records**: Service discovery
- **TXT Records**: Text records (SPF, DKIM, verification, etc.)

### Subdomain Example (`zones/sub.example.com.yaml`)

Shows how to configure a subdomain zone with:
- Basic A and AAAA records
- CNAME aliases
- Proper SOA configuration for subdomains

## Variables Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `resource_group_name` | Azure Resource Group | `"my-dns-rg"` |
| `subscription_id` | Azure Subscription ID | `"12345678-1234-5678-9012-123456789012"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `zone_files` | List of YAML zone files | `["zones/example.com.yaml", "zones/sub.example.com.yaml"]` |
| `dns_records` | DNS records as Terraform map | See [`variables.tf`](variables.tf) |

### Example `terraform.tfvars`

```hcl
subscription_id     = "12345678-1234-5678-9012-123456789012"
resource_group_name = "my-production-dns"

zone_files = [
  "zones/example.com.yaml",
  "zones/app.example.com.yaml"
]
```

## Testing and Validation

### 1. Syntax Validation
```bash
terraform validate
```

### 2. Plan Review
```bash
terraform plan -out=tfplan
terraform show tfplan
```

### 3. YAML Validation
```bash
# Install yamllint
pip install yamllint

# Validate YAML files
yamllint zones/
```

### 4. DNS Resolution Testing
```bash
# Test DNS resolution after apply
nslookup example.com
dig example.com ANY
```

## Common Patterns

### Environment-Specific Zones
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "zone_files" {
  description = "Environment-specific zone files"
  type        = list(string)
  default = [
    "zones/staging.example.com.yaml",
    "zones/api-staging.example.com.yaml"
  ]
}
```

### Conditional Zone Creation
```hcl
module "production_zones" {
  source = "../"

  for_each = var.environment == "production" ? var.production_zones : {}

  dns_records         = each.value
  zone_name          = each.key
  resource_group_name = var.resource_group_name
}
```

### Zone Delegation Chain
```hcl
# Parent zone
module "parent_zone" {
  source = "../"

  zone_name           = "example.com"
  resource_group_name = var.resource_group_name
  dns_records         = yamldecode(file("zones/example.com.yaml"))
}

# Child zone with automatic delegation
module "api_zone" {
  source = "../"

  zone_name           = "api.example.com"
  parent_zone         = "example.com"
  resource_group_name = var.resource_group_name
  dns_records         = yamldecode(file("zones/api.example.com.yaml"))

  depends_on = [module.parent_zone]
}
```

## Troubleshooting

### Common Issues

1. **YAML Parsing Errors**
   ```bash
   # Validate YAML syntax
   python -c "import yaml; yaml.safe_load(open('zones/example.com.yaml'))"
   ```

2. **Azure Authentication**
   ```bash
   az account show
   az account set --subscription "your-subscription-id"
   ```

3. **Resource Group Permissions**
   ```bash
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

### Debug Mode
```bash
export TF_LOG=DEBUG
terraform plan
```

## Next Steps

1. Customize the YAML files for your domains
2. Update variables for your Azure environment
3. Add additional zones as needed
4. Set up CI/CD for automated deployments
5. Implement monitoring and alerting for DNS changes

For more advanced usage patterns, see the main [README.md](../README.md).
