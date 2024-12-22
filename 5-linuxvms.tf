
resource "azurerm_public_ip" "linuxvm_public_ips" {
  for_each            = { for linux_vm in var.linux_vms : linux_vm.hostname => linux_vm }
  name                = "${each.value.hostname}-pip"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = "Static"
  sku                 = "Standard" # "Basic"
  sku_tier            = "Regional"
  depends_on = [ azurerm_resource_group.rg01 ]
}

resource "azurerm_network_interface" "linuxvm_nics" {
  for_each = { for linux_vm in var.linux_vms : linux_vm.hostname => linux_vm }

  name                = "${each.value.hostname}-nic"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  #enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnets[each.value.subnet_details.subnet_name].id
    private_ip_address_allocation = each.value.subnet_details.ip == "" ? "Dynamic" : "Static"
    private_ip_address            = each.value.subnet_details.ip == "" ? null : "${each.value.subnet_details.ip}"
    public_ip_address_id          = azurerm_public_ip.linuxvm_public_ips["${each.value.hostname}"].id
  }

  depends_on = [ azurerm_resource_group.rg01 ]

}


resource "azurerm_linux_virtual_machine" "linux_vm" {
  for_each            = { for linux_vm in var.linux_vms : linux_vm.hostname => linux_vm }
  name                = each.value.hostname
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  size                = each.value.vm_size

  disable_password_authentication = false # This has to be set else requires SSH keys 

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.linuxvm_nics["${each.value.hostname}"].id
  ]

  os_disk {
    name                 = "${each.value.hostname}_disk_os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  custom_data = each.value.install_nginx != null ?  local.linuxvm_custom_data : null 

  depends_on = [ azurerm_network_interface.linuxvm_nics, azurerm_public_ip.lb_frontendips ]
}


resource "azurerm_managed_disk" "linuxvm_data_disks" {
  for_each = { for disk in local.linuxvm_data_disks : disk.disk_name => disk }

  name                 = each.value.disk_name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb

  depends_on = [ azurerm_resource_group.rg01 ]
}


resource "azurerm_virtual_machine_data_disk_attachment" "linuxvm_disk_attach" {
  for_each = { for disk in local.linuxvm_data_disks : disk.disk_name => disk }
  managed_disk_id    = azurerm_managed_disk.linuxvm_data_disks[each.value.disk_name].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux_vm[each.value.hostname].id
  #lun                = each.value.index
  lun        = each.value.lun
  caching    = "ReadWrite"
  depends_on = [azurerm_linux_virtual_machine.linux_vm]
}



resource "azurerm_dev_test_global_vm_shutdown_schedule" "autoshutdown" {
  for_each            = { for linux_vm in var.linux_vms : linux_vm.hostname => linux_vm }
  virtual_machine_id = azurerm_linux_virtual_machine.linux_vm["${each.value.hostname}"].id
  location           = each.value.location
  enabled            = true

  daily_recurrence_time = "2000"
  timezone              = "India Standard Time"

  notification_settings {
    enabled         = true
    email           = var.autoshut_notification_email
    time_in_minutes = "30"
  }
  depends_on = [azurerm_linux_virtual_machine.linux_vm]
}
