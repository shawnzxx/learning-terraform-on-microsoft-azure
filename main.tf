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