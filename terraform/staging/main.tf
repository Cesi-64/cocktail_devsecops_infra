locals {
  env      = "staging"
  name     = "cocktail-staging"
  app_fqdn = "staging.${var.domain}"
  tags = {
    project    = "cocktail"
    env        = local.env
    managed_by = "terraform"
    ephemeral  = "true" # détruit chaque soir à 17h par la CI
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-cocktail-staging"
  location = var.location
  tags     = local.tags
}

module "vm" {
  source = "../modules/vm"

  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vm_size             = var.vm_size
  ssh_public_key      = var.ssh_public_key
  admin_ssh_cidrs     = var.admin_ssh_cidrs
  address_space       = "10.20.0.0/16"
  os_disk_size_gb     = 30
  tags                = local.tags

  public_ports = [
    { name = "http", port = 80 },
    { name = "https", port = 443 },
  ]
}

data "azurerm_dns_zone" "zone" {
  name                = var.domain
  resource_group_name = var.dns_zone_resource_group
}

resource "azurerm_dns_a_record" "app" {
  name                = "staging"
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 60
  records             = [module.vm.public_ip]
  tags                = local.tags
}
