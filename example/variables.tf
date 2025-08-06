variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where the DNS zone will be created"
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the DNS zone will be created"
  default     = "example-dns"
}

variable "zone_files" {
  type        = list(string)
  description = "List of zone files to create"
  default = [
    "zones/example.com.yaml",
    "zones/sub.example.com.yaml",
  ]
}

variable "dns_records" {
  description = "Object of DNS records to create from variable instead of yaml files"
  type = map(object({
    A = optional(object({
      records = list(string)
    }))
    AAAA = optional(object({
      records = list(string)
    }))
    CNAME = optional(object({
      record = string
    }))
    NS = optional(object({
      records = list(string)
    }))
    MX = optional(object({
      records = list(object({
        exchange   = string
        preference = number
      }))
    }))
    TXT = optional(object({
      records = list(string)
    }))
  }))
  default = {
    "example3.com" = {
      "@" = {
        A = {
          records = [
            "10.10.30.1",
            "10.10.30.2"
          ]
        },
        NS = {
          records = [
            "ns1.example3.com",
            "ns2.example3.com",
            "ns3.example3.com",
            "ns4.example3.com"
          ]
        },
        MX = {
          records = [
            {
              exchange   = "mail1.example3.com"
              preference = 10
            },
            {
              exchange   = "mail2.example3.com"
              preference = 20
            }
          ]
        },
        TXT = {
          records = [
            "v=spf1 a mx ~all"
          ]
        }
      }
      www = {
        CNAME = {
          record = "example3.com"
        }
      }
    }
  }
}
