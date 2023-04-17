
variable "rg_name" {
  type = string
  default = "vm02-rg"
}

variable "location" {
  type = string
  default = "northeurope"
}

variable "nsg_name" {
  type = string
  default = "vm01-nsg"
}

variable "sec_rules" {
    description = "NSG security rules"
    type = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
    }))
    default = [{
        name                       = "Rule01"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    },
    {
        name                       = "Rule02"
        priority                   = 130
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }]
    }

variable "vnet_name" {
  description = "VNET name"
  type        = string
  default = "hub02-vnet"
}

variable "address_space" {
  description = "VNET address space"
  type        = list(string)
  default     = ["10.44.0.0/16"]
}

variable "subnets" {
  description = "Subnets configuration"
  type = list(object({
    name                                           = string
    address_prefixes                               = list(string)
    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool
  }))

  default = [ {
    address_prefixes = [ "10.44.0.0/24" ]
    enforce_private_link_endpoint_network_policies = true
    enforce_private_link_service_network_policies = false
    name = "app01-snet"
  } ]
}


variable "log_analytics_retention_days" {
  description = "Specifies the number of days of the retention policy"
  type        = number
  default     = 7
}

variable vnet_required {
description = "Is the vnet required?"
  type        = bool
  default     = true
}

variable vnet_count {
description = "Number of vnet"
  type        = number
  default     = 1
}


variable "tags" {
  description = "(Optional) Specifies tags for all the resources"
  default     = {
    createdWith = "Terraform"
  }
}