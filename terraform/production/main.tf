locals {
  env      = "production"
  name     = "cocktail-prod"
  app_fqdn = "${var.app_record_name}.${var.domain}"
  tags = {
    project    = "cocktail"
    env        = local.env
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-cocktail-production"
  location = var.location
  tags     = local.tags

  # Garde-fou : "terraform destroy" refusera de supprimer la production
  lifecycle {
    prevent_destroy = true
  }
}

module "vm" {
  source = "../modules/vm"

  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vm_size             = var.vm_size
  ssh_public_key      = var.ssh_public_key
  admin_ssh_cidrs     = var.admin_ssh_cidrs
  address_space       = "10.30.0.0/16"
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
  name                = var.app_record_name
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 300
  records             = [module.vm.public_ip]
  tags                = local.tags
}

# Sauvegardes : la VM écrit ses dumps chiffrés dans le compte de stockage
# partagé (qui survit à la destruction de la prod) grâce à son identité managée.
data "azurerm_storage_account" "backup" {
  name                = var.backup_storage_account_name
  resource_group_name = var.shared_resource_group
}

resource "azurerm_role_assignment" "backup_writer" {
  scope                = "${data.azurerm_storage_account.backup.id}/blobServices/default/containers/${var.backup_container_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.vm.principal_id
}
