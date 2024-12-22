
resource "azurerm_virtual_network" "vnet01" {
  name                = var.vnet01.name
  resource_group_name = azurerm_resource_group.rg01.name
  location            = azurerm_resource_group.rg01.location
  address_space       = var.vnet01.address_space
  dns_servers         = var.vnet01.dns_servers != null ? var.vnet01.dns_servers : null
  tags                = var.default_tags
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for subnet in var.vnet01.subnets : subnet.name => subnet }
  name                 = each.value.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = [each.value.address_prefixes]
  resource_group_name  = azurerm_resource_group.rg01.name

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = each.value.delegation.name
      service_delegation {
        name    = each.value.delegation.service_delegation_name
        actions = each.value.delegation.actions
      }
    }
  }
  service_endpoints = each.value.service_endpoints != null ? each.value.service_endpoints : []
}

# NSG:
resource "azurerm_network_security_group" "subnet_nsgs" {
  for_each            = { for nsg in local.subnet_nsgs : nsg.nsg_name => nsg }
  name                = each.value.nsg_name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  depends_on = [ azurerm_resource_group.rg01 ]
}


# Route Tables: 
resource "azurerm_route_table" "subnet_route_tables" {
  for_each = { for rt in local.subnet_route_tables : rt.route_table_name => rt }
  name                = each.value.route_table_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  depends_on = [ azurerm_resource_group.rg01, azurerm_virtual_network.vnet01, azurerm_subnet.subnets ]
}


resource "azurerm_subnet_network_security_group_association" "nsg_on_subnet" {
  for_each            = { for nsg in local.subnet_nsgs : nsg.nsg_name => nsg }
  subnet_id                 = azurerm_subnet.subnets[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.subnet_nsgs[each.value.nsg_name].id
}

resource "azurerm_subnet_route_table_association" "routetable_on_subnet" {
  for_each = { for rt in local.subnet_route_tables : rt.route_table_name => rt }
  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  route_table_id = azurerm_route_table.subnet_route_tables[each.value.route_table_name].id
}



resource "azurerm_network_security_rule" "NgsRule" {
  for_each    = { for nsg_rule in local.nsg_rules : nsg_rule.key_name => nsg_rule }
  name        = each.value.rule_name
  description = each.value.rule_description
  access      = each.value.access
  direction   = each.value.direction
  priority    = each.value.priority
  protocol    = each.value.protocol

  source_port_range  = length(each.value.source_port_ranges) == 1 ? each.value.source_port_ranges[0] : null
  source_port_ranges = length(each.value.source_port_ranges) != 1 ? each.value.source_port_ranges : null
  destination_port_range  = length(each.value.destination_port_ranges) == 1 ? each.value.destination_port_ranges[0] : null
  destination_port_ranges = length(each.value.destination_port_ranges) != 1 ? each.value.destination_port_ranges : null
  source_address_prefix   = length(each.value.source_address_prefixes) == 1 ? each.value.source_address_prefixes[0] : null
  source_address_prefixes = length(each.value.source_address_prefixes) != 1 ? each.value.source_address_prefixes : null
  destination_address_prefix   = length(each.value.destination_address_prefixes) == 1 ? each.value.destination_address_prefixes[0] : null
  destination_address_prefixes = length(each.value.destination_address_prefixes) != 1 ? each.value.destination_address_prefixes : null


  resource_group_name         = each.value.resource_group_name
  network_security_group_name = each.value.nsg_name

  depends_on = [ azurerm_network_security_group.subnet_nsgs ]
}

 
