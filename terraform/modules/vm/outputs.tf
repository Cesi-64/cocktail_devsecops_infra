output "public_ip" {
  description = "IP publique statique de la VM"
  value       = azurerm_public_ip.this.ip_address
}

output "vm_name" {
  description = "Nom de la VM"
  value       = azurerm_linux_virtual_machine.this.name
}

output "principal_id" {
  description = "Identité managée de la VM (pour les attributions de rôles)"
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "nsg_name" {
  description = "Nom du NSG (utilisé par la CI pour ouvrir temporairement le SSH)"
  value       = azurerm_network_security_group.this.name
}

output "admin_username" {
  description = "Utilisateur administrateur"
  value       = var.admin_username
}
