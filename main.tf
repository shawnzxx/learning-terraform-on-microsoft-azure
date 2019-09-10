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