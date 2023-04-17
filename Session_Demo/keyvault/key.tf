provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}


data "azurerm_subnet" "appsnet" {
  name                 = "app01-snet"
  virtual_network_name = "hub01-vnet"
  resource_group_name  = "vm02-rg"
}


resource "azurerm_key_vault" "key_vault" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.sku_name
  tags                            = var.tags
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  
  timeouts {
    delete = "60m"
  }

  network_acls {
    bypass                     = var.bypass
    default_action             = var.default_action
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = [data.azurerm_subnet.appsnet.id]
  }

 access_policies = [
    {
      azure_ad_user_principal_names = ["mqalrousan09@outlook.com"]
      key_permissions               = ["get", "list","create"]
      secret_permissions            = ["get", "list","create"]
      certificate_permissions       = ["get", "import", "list","create"]
      storage_permissions           = ["backup", "get", "list", "recover","create"]
    }
 ]
  lifecycle {
      ignore_changes = [
          tags
      ]
  }
  
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                = var.private_end_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = "${data.azurerm_subnet.appsnet.id}"
  tags                = var.tags
  
  private_service_connection {
    name                           = "${var.name}Connection"
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = try([var.subresource_name], null)
    request_message                = try(var.request_message, null)
  }
  
  private_dns_zone_group {
    name                 = var.private_dns_zone_group_name
    private_dns_zone_ids = [azurerm_private_dns_zone.main.id]
  }
  
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  depends_on = [azurerm_key_vault.key_vault]
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault_secret" "kv_secret" {
  name         = "secret-sauce"
  value        = "P2ssw0rd123"
  key_vault_id = azurerm_key_vault.key_vault.id
}