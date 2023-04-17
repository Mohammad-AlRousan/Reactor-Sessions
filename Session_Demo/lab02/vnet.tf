provider "azurerm" {
    features {}
}


terraform {
  backend "azurerm" {
    resource_group_name  = "devopsrousan-tfstate-rg"
    storage_account_name = "devopsrousantfgoxdvvmc"
    container_name       = "c-tfstate"
    key                  = "terraform.tfstate"
  }
}

resource "random_string" "name" {
  length = 8
  upper = false
  number = true
  lower = true
  special = false
}

####        Resource Group      ####
resource "azurerm_resource_group" "rg" {
    name     = var.rg_name
    location = var.location
}
####        NSG     ####

module "nsg222" {
  source = "./nsgmo"
  nsg_name = var.nsgname
  
}

####        vNet        ####
resource "azurerm_virtual_network" "vnet" {
  count               = var.vnet_required == true ? var.vnet_count : 0
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
  
  
  lifecycle {
    ignore_changes = [
        tags
    ]
  }
   depends_on = [azurerm_resource_group.rg,
   azurerm_network_security_group.ng]
}

####        Log Analytics       ####
data "azurerm_log_analytics_workspace" "loganalytics" {
  name                = "DefaultWorkspace-1a34732a-a593-48e6-9f34-42a43df0d52a-WEU"
  resource_group_name = "defaultresourcegroup-weu"
}


####        Subnet      ####
resource "azurerm_subnet" "subnet" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                                           = each.key
  resource_group_name                            = var.rg_name
  virtual_network_name                           = azurerm_virtual_network.vnet[0].name
  address_prefixes                               = each.value.address_prefixes
  enforce_private_link_endpoint_network_policies = each.value.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = each.value.enforce_private_link_service_network_policies

  depends_on                                     = [azurerm_network_security_group.nsg,azurerm_virtual_network.vnet]
}

resource "azurerm_monitor_diagnostic_setting" "settings" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_virtual_network.vnet[0].id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.loganalytics.id

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-assosiation" {
  for_each                  = azurerm_subnet.subnet
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}