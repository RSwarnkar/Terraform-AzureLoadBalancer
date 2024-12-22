
resource "azurerm_public_ip" "lb_frontendips" {
  name                = "lb-fip-${var.public_alb.frontend_ip_configuration.fip_name}"
  location            = azurerm_resource_group.rg01.location
  resource_group_name = azurerm_resource_group.rg01.name
  sku                 = "Standard"
  allocation_method   = "Static"
  sku_tier            = "Regional"
  domain_name_label   = "lb-fip-${var.public_alb.frontend_ip_configuration.fip_name}"
  tags                = var.default_tags
  depends_on = [ azurerm_resource_group.rg01 ]
}

resource "azurerm_lb" "loadbalancer" {
  name                = var.public_alb.name
  location            = var.public_alb.location
  resource_group_name = var.public_alb.resource_group_name

  #   dynamic "frontend_ip_configuration" {
  #     for_each = var.public_alb.frontend_ip_configurations
  #     content {
  #       name                 = each.value.fip_name
  #       public_ip_address_id = azurerm_public_ip.lb_frontendips["lb-fip-${each.value.fip_name}"].id
  #     }
  #   }
  frontend_ip_configuration {
    name                 = var.public_alb.frontend_ip_configuration.fip_name
    public_ip_address_id = azurerm_public_ip.lb_frontendips.id
  }

  depends_on = [ azurerm_resource_group.rg01 ]

}

resource "azurerm_lb_backend_address_pool" "lb_bepool" {
  name            = "bepool"
  loadbalancer_id = azurerm_lb.loadbalancer.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vms_bepool" {
  for_each                = toset(var.public_alb.backend_pool_vms)
  ip_configuration_name   = "primary" # "primary" # azurerm_network_interface.linuxvm_nics["${each.value}"].ip_configuration.name 
  network_interface_id    = azurerm_network_interface.linuxvm_nics["${each.value}"].id
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_bepool.id
}

resource "azurerm_lb_probe" "lb_healthprobe" {
  for_each = { for probe in local.health_probe_list : probe.probe_name => probe}
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = each.value.probe_name
  protocol            = each.value.protocol
  port                = each.value.port
  probe_threshold     = each.value.probe_threshold
  interval_in_seconds = each.value.interval_in_seconds
  depends_on = [ 
    azurerm_lb.loadbalancer, 
    azurerm_lb_backend_address_pool.lb_bepool,
    azurerm_network_interface_backend_address_pool_association.vms_bepool
  ]
}

 
resource "azurerm_lb_rule" "lb_rules" {
  for_each = { for rule in local.lb_rules_list : rule.rule_name => rule}
  
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                      = each.value.rule_name
      frontend_ip_configuration_name = azurerm_lb.loadbalancer.frontend_ip_configuration[0].name #each.value.frontend_ip_configuration_name
      frontend_port                  = each.value.frontend_port
      protocol                       = each.value.protocol
      backend_address_pool_ids      = [azurerm_lb_backend_address_pool.lb_bepool.id]
      backend_port                   = each.value.backend_port
      enable_floating_ip             = each.value.enable_floating_ip
      idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
      probe_id                    = azurerm_lb_probe.lb_healthprobe[each.value.probe_name].id
      enable_tcp_reset               = each.value.enable_tcp_reset
  depends_on = [
    azurerm_lb_probe.lb_healthprobe
  ]
}


# Inbound NAT Rule
// Add here if needed

# Outbound Rule 
// Add here if needed