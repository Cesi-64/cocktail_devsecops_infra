locals {
  env  = "monitoring"
  name = "cocktail-monitoring"
  tags = {
    project    = "cocktail"
    env        = local.env
    managed_by = "terraform"
  }
  # Sous-domaines servis par la VM de supervision
  #   grafana / wazuh : interfaces web (HTTPS)
  #   loki / metrics  : points d'entrée des agents Alloy (HTTPS + authentification)
  #   monitoring      : adresse du manager Wazuh pour les agents (1514/1515)
  records = ["grafana", "wazuh", "loki", "metrics", "monitoring"]
}

resource "azurerm_resource_group" "this" {
  name     = "rg-cocktail-monitoring"
  location = var.location
  tags     = local.tags

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
  address_space       = "10.40.0.0/16"
  os_disk_size_gb     = 64
  tags                = local.tags

  public_ports = [
    { name = "http", port = 80 },
    { name = "https", port = 443 },
    { name = "wazuh-agent", port = 1514 },
    { name = "wazuh-enroll", port = 1515 },
  ]
}

data "azurerm_dns_zone" "zone" {
  name                = var.domain
  resource_group_name = var.dns_zone_resource_group
}

resource "azurerm_dns_a_record" "records" {
  for_each = toset(local.records)

  name                = each.key
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 300
  records             = [module.vm.public_ip]
  tags                = local.tags
}
