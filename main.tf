# Terraform will scan through system env and put value in here
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {} 

# variables
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_name" {}
variable "environment" {}
variable "web_server_count" {}
variable "terraform_script_version" {}
variable "domain_name_label" {}
variable "jump_server_location" {}   
variable "jump_server_prefix" {}
variable "jump_server_name" {}      


provider "azurerm" {
    version         = "1.16"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
}

module "location_us2w" {
  source = "./geo-vnetPeering-lb-jumpServer"

  web_server_location      = "westus2"
  web_server_rg            = "${var.web_server_rg}-us2w"
  resource_prefix          = "${var.resource_prefix}-us2w"
  web_server_address_space = "1.0.0.0/22"
  web_server_name          = "${var.web_server_name}"
  environment              = "${var.environment}"
  web_server_count         = "${var.web_server_count}"
  web_server_subnets       = ["1.0.1.0/24","1.0.2.0/24"]
  domain_name_label        = "${var.domain_name_label}"
  terraform_script_version = "${var.terraform_script_version}"
}

module "location_asia" {
  source = "./geo-vnetPeering-lb-jumpServer"

  web_server_location      = "southeastasia"
  web_server_rg            = "${var.web_server_rg}-asia"
  resource_prefix          = "${var.resource_prefix}-asia"
  web_server_address_space = "2.0.0.0/22"
  web_server_name          = "${var.web_server_name}"
  environment              = "${var.environment}"
  web_server_count         = "${var.web_server_count}"
  web_server_subnets       = ["2.0.1.0/24","2.0.2.0/24"]
  domain_name_label        = "${var.domain_name_label}"
  terraform_script_version = "${var.terraform_script_version}"
}

resource "azurerm_traffic_manager_profile" "traffic_manager" {
  name                   = "${var.resource_prefix}-traffic-manager"
  # traffic manager don't have location, but we still need to put it under one rg
  resource_group_name    = "${module.location_us2w.web_server_rg_name}"
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "${var.domain_name_label}"
    ttl           = 100
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_traffic_manager_endpoint" "traffic_manager_us2w" {
  name                   = "${var.resource_prefix}-us2w-endpoint"
  # traffic manager inside us2w rg, refer to azurerm_traffic_manager_profile.traffic_manager
  resource_group_name    = "${module.location_us2w.web_server_rg_name}"
  profile_name           = "${azurerm_traffic_manager_profile.traffic_manager.name}"
  target_resource_id     = "${module.location_us2w.web_server_lb_public_ip_id}"
  type                   = "azureEndpoints"
  weight                 = 100
}

resource "azurerm_traffic_manager_endpoint" "traffic_manager_asia" {
  name                   = "${var.resource_prefix}-eu1w-endpoint"
  # traffic manager inside us2w rg, refer to azurerm_traffic_manager_profile.traffic_manager
  resource_group_name    = "${module.location_us2w.web_server_rg_name}"
  profile_name           = "${azurerm_traffic_manager_profile.traffic_manager.name}"
  target_resource_id     = "${module.location_asia.web_server_lb_public_ip_id}"
  type                   = "azureEndpoints"
  weight                 = 100
}

resource "azurerm_resource_group" "jump_server_rg" {
  name        = "${var.jump_server_prefix}-rg"
  location    = "${var.jump_server_location}"
}

resource "azurerm_virtual_network" "jump_server_vnet" {
  name                = "${var.jump_server_prefix}-vnet"
  location            = "${var.jump_server_location}" 
  resource_group_name = "${azurerm_resource_group.jump_server_rg.name}"
  address_space       = ["3.0.0.0/24"]
}

resource "azurerm_subnet" "jump_server_subnet" {
  name                 = "${var.jump_server_prefix}-3.0.0.0-subnet"
  resource_group_name  = "${azurerm_resource_group.jump_server_rg.name}"  
  virtual_network_name = "${azurerm_virtual_network.jump_server_vnet.name}"
  address_prefix       = "3.0.0.0/24"
}

resource "azurerm_virtual_network_peering" "jump_server_peer_web_us2w" {
  name                         = "jump-asia-peer-web-us2w"
  resource_group_name          = "${azurerm_resource_group.jump_server_rg.name}"  
  virtual_network_name         = "${azurerm_virtual_network.jump_server_vnet.name}"  
  remote_virtual_network_id    = "${module.location_us2w.web_server_vnet_id}"
  allow_virtual_network_access = true
  depends_on                   = ["azurerm_subnet.jump_server_subnet"]
}

resource "azurerm_virtual_network_peering" "web_us2w_peer_jump_server" {
  name                         = "web-us2w-peer-jump-asia"
  resource_group_name          = "${module.location_us2w.web_server_rg_name}"  
  virtual_network_name         = "${module.location_us2w.web_server_vnet_name}"  
  remote_virtual_network_id    = "${azurerm_virtual_network.jump_server_vnet.id}"
  allow_virtual_network_access = true
  depends_on                   = ["azurerm_subnet.jump_server_subnet"]
}

resource "azurerm_virtual_network_peering" "jump_server_peer_web_asia" {
  name                         = "jump-asia-peer-web-asia"
  resource_group_name          = "${azurerm_resource_group.jump_server_rg.name}"  
  virtual_network_name         = "${azurerm_virtual_network.jump_server_vnet.name}"  
  remote_virtual_network_id    = "${module.location_asia.web_server_vnet_id}"
  allow_virtual_network_access = true
  depends_on                   = ["azurerm_subnet.jump_server_subnet"]
}

resource "azurerm_virtual_network_peering" "web_asia_peer_jump_server" {
  name                         = "web-asia-peer-jump-asia"
  resource_group_name          = "${module.location_asia.web_server_rg_name}"  
  virtual_network_name         = "${module.location_asia.web_server_vnet_name}"  
  remote_virtual_network_id    = "${azurerm_virtual_network.jump_server_vnet.id}"
  allow_virtual_network_access = true
  depends_on                   = ["azurerm_subnet.jump_server_subnet"]
}

resource "azurerm_network_interface" "jump_server_nic" {
  name                      = "${var.jump_server_name}-nic"
  location                  = "${var.jump_server_location}"
  resource_group_name       = "${azurerm_resource_group.jump_server_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.jump_server_nsg.id}"

  ip_configuration {
    name                          = "${var.jump_server_name}-ip"
    subnet_id                     = "${azurerm_subnet.jump_server_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jump_server_public_ip.id}"
  }
}

resource "azurerm_public_ip" "jump_server_public_ip" {
  name                         = "${var.jump_server_name}-public-ip"
  location                     = "${var.jump_server_location}"
  resource_group_name          = "${azurerm_resource_group.jump_server_rg.name}"
  public_ip_address_allocation = "${var.environment == "production" ? "static" : "dynamic"}"
}

resource "azurerm_network_security_group" "jump_server_nsg" {
  name                = "${var.jump_server_name}-nsg"
  location            = "${var.jump_server_location}"
  resource_group_name = "${azurerm_resource_group.jump_server_rg.name}" 
}

resource "azurerm_network_security_rule" "jump_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.jump_server_rg.name}" 
  network_security_group_name = "${azurerm_network_security_group.jump_server_nsg.name}" 
}

resource "azurerm_virtual_machine" "jump_server" {
  name                         = "${var.jump_server_name}"
  location                     = "${var.jump_server_location}"
  resource_group_name          = "${azurerm_resource_group.jump_server_rg.name}"  
  network_interface_ids        = ["${azurerm_network_interface.jump_server_nic.id}"]
  vm_size                      = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.jump_server_name}-os"    
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile {
    computer_name      = "${var.jump_server_name}" 
    admin_username     = "jumpserver"
    admin_password     = "Passw0rd1234"
  }

  os_profile_windows_config {
  }

}