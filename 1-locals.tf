locals {
  # Network Security Group for Subnets
  subnet_nsgs = flatten([
    for subnet in var.vnet01.subnets : {
      nsg_name            = "nsg-${var.vnet01.name}-${subnet.name}"
      subnet_name         = subnet.name
      vnet_name           = var.vnet01.name
      resource_group_name = azurerm_virtual_network.vnet01.resource_group_name
      location            = azurerm_virtual_network.vnet01.location
    }
  ])
  subnet_route_tables = flatten([
    for subnet in var.vnet01.subnets : {
      route_table_name    = "rt-${var.vnet01.name}-${subnet.name}"
      subnet_name         = subnet.name
      vnet_name           = var.vnet01.name
      resource_group_name = azurerm_virtual_network.vnet01.resource_group_name
      location            = azurerm_virtual_network.vnet01.location
    }
  ])

  # NSG Rules : 
  nsg_rules = flatten([
      for subnet in var.vnet01.subnets : [        
        subnet.nsg_rules == null ? [] : [
        for nsg_rule in subnet.nsg_rules : {
          virtual_network_name = var.vnet01.name
          subnet_name          = subnet.name 
          nsg_name             = "nsg-${var.vnet01.name}-${subnet.name}"
          location             = var.vnet01.location
          resource_group_name  = var.vnet01.resource_group_name

          key_name = "nsg-${var.vnet01.name}-${subnet.name}~${nsg_rule.rule_name}"

          rule_name                    = nsg_rule.rule_name
          rule_description             = nsg_rule.rule_description
          access                       = nsg_rule.access
          direction                    = nsg_rule.direction
          priority                     = nsg_rule.priority
          protocol                     = nsg_rule.protocol
          source_port_ranges           = nsg_rule.source_port_ranges
          destination_port_ranges      = nsg_rule.destination_port_ranges
          source_address_prefixes      = nsg_rule.source_address_prefixes
          destination_address_prefixes = nsg_rule.destination_address_prefixes

        }
      ]
      ]
  ])
  
  # Data Disks for Linux VM: 
  linuxvm_data_disks = flatten([
    for vm in var.linux_vms : [
      for disk in vm.data_disks : {
        disk_name            = "${vm.hostname}-datadisk-${disk.name}"
        location             = vm.location
        resource_group_name  = vm.resource_group_name
        hostname             = vm.hostname
        disk_size_gb         = disk.disk_size_gb
        storage_account_type = disk.storage_account_type
        mountpoint           = disk.mountpoint
        lun                  = "${index(vm.data_disks, disk) + 1}"
      }
    ]
  ])

  # Custom Data to deploy Nginx inside Linux VMs 
  linuxvm_custom_data = base64encode(<<EOF
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
# Create a default.html file with the hostname
echo "<html>
<head><title>Hostname</title></head>
<body>
<h1>Server Hostname is $(hostname)</h1>
</body>
</html>" > /var/www/html/default.html
EOF
  )
  
  # Load balancer specific locals: 

  # Health Probe
  health_probe_list = flatten([
    for probe in var.public_alb.health_probes : {
      probe_name          = probe.probe_name
      protocol            = probe.protocol
      port                = probe.port
      probe_threshold     = probe.probe_threshold
      interval_in_seconds = probe.interval_in_seconds
    }
  ])
  
  # Load Balancer Rules: 
  lb_rules_list = flatten([
    for rule in var.public_alb.lb_rules : {
      rule_name                      = rule.rule_name
      frontend_ip_configuration_name = rule.frontend_ip_configuration_name
      frontend_port                  = rule.frontend_port
      protocol                       = rule.protocol
      backend_address_pool_name      = rule.backend_address_pool_name
      backend_port                   = rule.backend_port
      enable_floating_ip             = rule.enable_floating_ip
      idle_timeout_in_minutes        = rule.idle_timeout_in_minutes
      probe_name                     = rule.probe_name
      enable_tcp_reset               = rule.enable_tcp_reset
    }
  ])
}
