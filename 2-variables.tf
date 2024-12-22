# Tailor this file as per your needs: 

variable "rg01" {
  description = "Resource Group details"
  type = object({
    name     = string
    location = string
  })
  default = {
    name     = "rsw-eus-rg-prod-lbdemo"
    location = "East US"
  }
}

variable "default_tags" {
  description = "Default Tags"
  type        = map(string)
  default = {
    createdvia = "Terraform"
    purpose    = "Load Balancer Demo"
  }
}

# Single VNet only 
variable "vnet01" {
  type = object({
    name                = string
    location            = string
    resource_group_name = string
    address_space       = list(string)
    dns_servers         = optional(list(string))
    subnets = list(object({
      name             = string
      address_prefixes = string
      delegation = optional(object({
        name                    = string
        service_delegation_name = string
        actions                 = list(string)
      }))
      service_endpoints = optional(list(string))
      nsg_rules = optional(list(object({
        rule_name                    = string
        rule_description             = string
        access                       = string
        direction                    = string
        priority                     = string
        protocol                     = string
        source_port_ranges           = list(string)
        destination_port_ranges      = list(string)
        source_address_prefixes      = list(string)
        destination_address_prefixes = list(string)
      })))
    }))
    tags = optional(map(string))
  })
  default = {
    name                = "vnet01"
    location            = "East US"
    resource_group_name = "rsw-eus-rg-prod-lbdemo"
    address_space       = ["10.10.0.0/16"]
    subnets = [
      {
        name             = "subnet00"
        address_prefixes = "10.10.0.0/24"
      },
      {
        name             = "subnet01"
        address_prefixes = "10.10.1.0/24"
        nsg_rules = [
          {
            rule_name                    = "SR-AllowRDPSSH-Inbound"
            rule_description             = "Allow RDP"
            access                       = "Allow"   # "Deny"
            direction                    = "Inbound" # "Outbound"
            priority                     = "1001"
            protocol                     = "*"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["3389", "22"]
            source_address_prefixes      = ["*"]
            destination_address_prefixes = ["*"]
          },
          {
            rule_name                    = "SR-AllowHttpPorts-Inbound"
            rule_description             = "Allow HTTP/HTTPS"
            access                       = "Allow"   # "Deny"
            direction                    = "Inbound" # "Outbound"
            priority                     = "1002"
            protocol                     = "*"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["80", "443"]
            source_address_prefixes      = ["*"]
            destination_address_prefixes = ["*"]
          }
        ]
      },
      # {
      #   name             = "subnet02"
      #   address_prefixes = "10.10.2.0/24"
      #   delegation = {
      #     name                    = "Delegation"
      #     service_delegation_name = "Microsoft.ContainerInstance/containerGroups"
      #     actions = [
      #       "Microsoft.Network/virtualNetworks/subnets/join/action",
      #       "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      #     ]
      #   }
      # },
      # {
      #   name              = "subnet03"
      #   address_prefixes  = "10.10.3.0/24"
      #   service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
      # },
    ]
  }
}


variable "linux_vms" {
  type = list(object({
    hostname            = string
    resource_group_name = string
    location            = string
    vm_size             = string
    subnet_details = object({
      vnet_rg_name = string
      vnet_name    = string
      subnet_name  = string
      ip           = string
    })
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    data_disks = list(object({
      name                 = string
      mountpoint           = string
      storage_account_type = string
      disk_size_gb         = string
    }))
    install_nginx = bool
    tags          = map(string)
  }))
  default = [
    {
      hostname            = "linuxvm01"
      location            = "East US"
      resource_group_name = "rsw-eus-rg-prod-lbdemo"
      vm_size             = "Standard_B1s" # Low cost Skus: Standard_B1s, Standard_B2ms, Standard_B1ls
      subnet_details = {
        vnet_rg_name = "rsw-eus-rg-prod-lbdemo"
        vnet_name    = "vnet01"
        subnet_name  = "subnet01"
        ip           = ""
      }
      source_image_reference = {
        publisher = "canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
      data_disks = [
        # {
        #   name                 = "data"
        #   mountpoint           = "/mnt/data"
        #   storage_account_type = "StandardSSD_LRS"
        #   disk_size_gb         = 32
        # }
      ]
      install_nginx = true
      tags = {
        "CreatedBy"   = "Terraform"
        "Application" = "Nginx"
      }
    },
    {
      hostname            = "linuxvm02"
      location            = "East US"
      resource_group_name = "rsw-eus-rg-prod-lbdemo"
      vm_size             = "Standard_B1s" # Standard_B1s, Standard_B2ms, Standard_B1ls
      subnet_details = {
        vnet_rg_name = "rsw-eus-rg-prod-lbdemo"
        vnet_name    = "vnet01"
        subnet_name  = "subnet01"
        ip           = ""
      }
      source_image_reference = {
        publisher = "canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
      data_disks = [
        # {
        #   name                 = "data"
        #   mountpoint           = "/mnt/data"
        #   storage_account_type = "StandardSSD_LRS"
        #   disk_size_gb         = 32
        # }
      ]
      install_nginx = true
      tags = {
        "CreatedBy"   = "Terraform"
        "Application" = "Nginx"
      }
    },
  ]
}

variable "vm_admin_username" {
  description = "Default OS Admin Username for Windows"
  type        = string
  default     = "nginxadmin" # Caution: Should use Keyvault here, or SSH Keys
}
variable "vm_admin_password" {
  description = "Default OS Admin Password for Windows"
  type        = string
  default     = "w!87mQy(!ZrQH!B" # Caution: Should use Keyvault here, or SSH Keys
}

## Should prompt for this
variable "autoshut_notification_email" {
  description = "Auto-shutdown for VMs: Enter your email ID on which auto-shutdown notification should be sent: "
  type = string
}

variable "public_alb" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    frontend_ip_configuration = object({
      fip_name = string
    })
    backend_pool_vms = list(string)
    health_probes = list(object({
      probe_name          = string
      protocol            = string
      port                = number
      probe_threshold     = number
      interval_in_seconds = number
    }))
    lb_rules = list(object({
      rule_name                      = string
      frontend_ip_configuration_name = string
      frontend_port                  = number
      protocol                       = string
      backend_address_pool_name      = string
      backend_port                   = number
      enable_floating_ip             = optional(bool)
      idle_timeout_in_minutes        = number
      probe_name                     = string
      enable_tcp_reset               = optional(bool)
    }))
    tags = map(string)
  })

  default = {
    name                = "rsw-eus-alb-prod-nginx"
    resource_group_name = "rsw-eus-rg-prod-lbdemo"
    location            = "East US"
    frontend_ip_configuration = {
      fip_name = "nginxfip"
    }
    backend_pool_vms = [
      "linuxvm01",
      "linuxvm02"
    ]
    health_probes = [
      {
        probe_name          = "nginx_http_probe"
        protocol            = "Tcp"
        port                = 80
        probe_threshold     = 2
        interval_in_seconds = 5
      }
    ]
    lb_rules = [
      {
        rule_name                      = "http-rule"
        backend_address_pool_name      = "bepool"
        backend_port                   = 80
        enable_floating_ip             = false
        enable_tcp_reset               = false
        frontend_ip_configuration_name = "nginxfip"
        frontend_port                  = 80
        idle_timeout_in_minutes        = 4
        probe_name                     = "nginx_http_probe"
        protocol                       = "Tcp"

      }
    ]
    tags = {
      "CreatedVia" = "Terraform"
    }
  }
}
