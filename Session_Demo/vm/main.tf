
locals {
  server_name = "${var.vm_name}${var.app}"
  dns_name    = lower("${var.app}")
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.nw_rg_name
}
data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = var.nw_rg_name
}
data "azurerm_key_vault" "kv" {
  count               = var.disk_encryption_required ? 1 :0
  name                = var.keyvault_name
  resource_group_name = var.keyvault_rg_name
}
data "azurerm_key_vault_key" "key" {
  count               = var.disk_encryption_required ? 1 :0
  name                = var.key_name
  key_vault_id        = data.azurerm_key_vault.kv[0].id
}

resource "azurerm_public_ip" "pip" {
  count                   = var.public_ip_required == true ? var.node_count : 0
  name                    = "${local.server_name}0${count.index + 1}-pip"
  location                = var.location_name
  resource_group_name     = var.vm_rg_name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30
  domain_name_label       = "${local.dns_name}0${count.index + 1}"
  #zones                   = [var.zones[count.index % length(var.zones)]]

  tags = merge(var.tags, {"SubNet" : var.subnet_name})

}
resource "azurerm_network_interface" "private_nic" {
  count               = var.node_count
  name                = "${local.server_name}0${count.index + 1}-nic01"  
  location            = var.location_name
  resource_group_name = var.vm_rg_name

  ip_configuration {
    name                          = "${local.server_name}0${count.index + 1}-ip1"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = var.ip_type
    private_ip_address            = var.ip_addr
    public_ip_address_id          = var.public_ip_required == true ? azurerm_public_ip.pip[count.index].id : ""
  }
  enable_accelerated_networking = var.enable_accelerated_nw
    
  tags = merge(var.tags, {"SubNet" : var.subnet_name})
}

resource "azurerm_virtual_machine" "vm" {
  count                 = var.node_count
  name                  = "${local.server_name}0${count.index + 1}"
  location              = var.location_name
  #zones                 = [var.zones[count.index % length(var.zones)]]
  resource_group_name   = var.vm_rg_name
  network_interface_ids = [element(azurerm_network_interface.private_nic.*.id, count.index)]
  vm_size               = var.vm_sku_type
  license_type          = var.win_license_type != "" ? var.win_license_type : null
  
  delete_os_disk_on_termination    = var.delete_os_disk
  delete_data_disks_on_termination = var.delete_data_disks

  storage_image_reference {
    id        = var.os_cs_img_required == true ? var.os_cs_img_id : ""
    publisher = var.os_cs_img_required == true ? "" : var.os_mk_img_publisher
    offer     = var.os_cs_img_required == true ? "" : var.os_mk_img_offer
    sku       = var.os_cs_img_required == true ? "" : var.os_mk_img_sku
    version   = var.os_cs_img_required == true ? "" : var.os_mk_img_version
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = var.diag_storage_name
  }
  storage_os_disk {
    name              = "${local.server_name}0${count.index + 1}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.osdisk_type
    #disk_size_gb      = var.osdisk_size
  }
  dynamic "storage_data_disk" {
    for_each = var.data_disk_required ? [""] : []
    content {
      name              = "${local.server_name}0${count.index + 1}-ddisk01"
      caching           = "ReadWrite"
      create_option     = "Empty"
      lun               = 01
      managed_disk_type = var.mddisk_type != "" ? var.mddisk_type : null
      disk_size_gb      = var.mddisk_size != "" ? var.mddisk_size : null
    }
  }
  os_profile {
    computer_name  = "${local.server_name}0${count.index + 1}"
    admin_username = var.vm_username
    admin_password = var.vm_password
  }
  os_profile_windows_config {
    provision_vm_agent = true
    timezone           = "Arab Standard Time"
  }
  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "nw-watcher" {
  count                        = var.nw_watcher_required == true ? var.node_count : 0
  name                         = "NetworkWatcher"
  virtual_machine_id           = element(azurerm_virtual_machine.vm.*.id, count.index + 1)
  publisher                    = "Microsoft.Azure.NetworkWatcher"
  type                         = var.nwwType
  type_handler_version         = "1.4"
  auto_upgrade_minor_version   = true

  depends_on = [azurerm_virtual_machine.vm]
}

resource "azurerm_virtual_machine_extension" "log_analytics" {
  count                         = var.enable_log_analytics == true ? var.node_count : 0
  name                          = "LogAnalytics"
  virtual_machine_id            = element(azurerm_virtual_machine.vm.*.id, count.index + 1)
  publisher                     = "Microsoft.EnterpriseCloud.Monitoring"
  type                          = var.agntType
  type_handler_version          = "1.0"

   settings = <<SETTINGS
     {
         "workspaceId": ""
     }
 SETTINGS
   protected_settings = <<PROTECTED_SETTINGS
     {
         "workspaceKey": ""
     }
 PROTECTED_SETTINGS
 
  depends_on = [azurerm_virtual_machine_extension.nw-watcher]
}