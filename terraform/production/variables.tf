variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "domain" {
  description = "Nom de domaine = nom de la zone Azure DNS (ex : cocktail.mon-ecole.fr)"
  type        = string
}

variable "dns_zone_resource_group" {
  description = "Groupe de ressources qui contient la zone Azure DNS"
  type        = string
}

variable "ssh_public_key" {
  description = "Clé publique SSH de déploiement"
  type        = string
}

variable "admin_ssh_cidrs" {
  description = "IP autorisées en SSH en permanence (ex : [\"203.0.113.10/32\"])"
  type        = list(string)
  default     = []
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "app_record_name" {
  description = "Sous-domaine de l'application en production (app => app.<domaine>)"
  type        = string
  default     = "app"
}

variable "shared_resource_group" {
  description = "Groupe de ressources partagé (state Terraform + sauvegardes), créé au bootstrap"
  type        = string
}

variable "backup_storage_account_name" {
  description = "Compte de stockage des sauvegardes MariaDB (créé au bootstrap)"
  type        = string
}

variable "backup_container_name" {
  description = "Conteneur blob des sauvegardes"
  type        = string
  default     = "mariadb"
}
