output "public_ip" {
  description = "IP publique de la VM"
  value       = module.vm.public_ip
}

output "resource_group" {
  description = "Groupe de ressources de l'environnement"
  value       = azurerm_resource_group.this.name
}

output "nsg_name" {
  description = "NSG de la VM (ouverture SSH temporaire par la CI)"
  value       = module.vm.nsg_name
}

output "ansible_inventory" {
  description = "Inventaire Ansible (YAML)"
  value       = local.ansible_inventory
}

output "ansible_tf_vars" {
  description = "Variables Ansible issues de Terraform (YAML)"
  value       = local.ansible_tf_vars
}

output "app_url" {
  description = "URL de la production"
  value       = "https://${local.app_fqdn}"
}
