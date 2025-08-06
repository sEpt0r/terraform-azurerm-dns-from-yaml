variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
}

variable "zone_name" {
  description = "DNS zone name"
  type        = string
}

variable "parent_zone" {
  description = "Parent DNS zone name to create NS records for delegation"
  type        = string
  default     = null
}

variable "dns_records" {
  description = "DNS records data"
  type = map(
    object(
      {
        A = optional(object({
          records = list(string)
          ttl     = optional(number)
          tags    = optional(map(string))
        })),
        AAAA = optional(object({
          records = list(string)
          ttl     = optional(number)
          tags    = optional(map(string))
        })),
        CAA = optional(object({
          records = list(object({
            flags = number
            tag   = string
            value = string
          }))
          ttl  = optional(number)
          tags = optional(map(string))
        })),
        CNAME = optional(object({
          record = string
          ttl    = optional(number)
          tags   = optional(map(string))
        })),
        MX = optional(object({
          records = list(object({
            exchange   = string
            preference = number
          }))
          ttl  = optional(number)
          tags = optional(map(string))
        })),
        NS = optional(object({
          records = list(string)
          ttl     = optional(number)
          tags    = optional(map(string))
        })),
        PTR = optional(object({
          records = list(string)
          ttl     = optional(number)
          tags    = optional(map(string))
        })),
        SOA = optional(object({
          email         = string
          host_name     = optional(string)
          expire_time   = optional(number)
          minimum_ttl   = optional(number)
          refresh_time  = optional(number)
          retry_time    = optional(number)
          serial_number = optional(number)
          ttl           = optional(number)
          tags          = optional(map(string))
        })),
        SRV = optional(object({
          records = list(object({
            port     = number
            priority = number
            target   = string
            weight   = number
          }))
          ttl  = optional(number)
          tags = optional(map(string))
        })),
        TXT = optional(object({
          records = list(string)
          ttl     = optional(number)
          tags    = optional(map(string))
        }))
      }
    )
  )
  default = {}
}

variable "default_ttl" {
  description = "Default TTL for DNS records"
  type        = map(number)
  default = {
    A     = 300
    AAAA  = 300
    CAA   = 300
    CNAME = 300
    MX    = 3600
    NS    = 3600
    PTR   = 3600
    SOA   = 3600
    SRV   = 3600
    TXT   = 300
  }

  validation {
    condition = alltrue([
      for ttl in values(var.default_ttl) : ttl >= 1 && ttl <= 2147483647
    ])
    error_message = "TTL values must be between 1 and 2147483647 seconds."
  }
}

variable "default_tags" {
  description = "Default tags for DNS records"
  type        = map(string)
  default     = {}
}
