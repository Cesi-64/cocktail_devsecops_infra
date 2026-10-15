# Terraform alimente Ansible : l'inventaire et les variables issues de
# l'infrastructure (IP, noms DNS, groupe de ressources...) sont générés ici.
#  - écrits sur disque (local_file) pour un usage en local ;
#  - exposés en output pour que la CI les régénère à chaque run
#    (terraform output -raw ansible_inventory), même sans apply.

locals {
  ansible_inventory = templatefile("${path.module}/../templates/hosts.yml.tftpl", {
    env   = local.env
    group = local.env
    host  = local.name
    ip    = module.vm.public_ip
    user  = module.vm.admin_username
  })

  ansible_tf_vars = yamlencode({
    domain                 = var.domain
    public_ip              = module.vm.public_ip
    azure_resource_group   = azurerm_resource_group.this.name
    nsg_name               = module.vm.nsg_name
    app_fqdn               = local.app_fqdn
    backup_storage_account = var.backup_storage_account_name
    backup_container       = var.backup_container_name
  })
}

resource "local_file" "inventory" {
  filename        = "${path.module}/../../ansible/inventories/${local.env}/hosts.yml"
  content         = local.ansible_inventory
  file_permission = "0644"
}

resource "local_file" "tf_vars" {
  filename        = "${path.module}/../../ansible/inventories/${local.env}/group_vars/all/terraform.yml"
  content         = "# Généré par Terraform - NE PAS MODIFIER À LA MAIN, NE PAS COMMITER\n${local.ansible_tf_vars}"
  file_permission = "0644"
}
