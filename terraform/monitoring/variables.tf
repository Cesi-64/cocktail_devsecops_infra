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
  default     = "Standard_B4ms"
}
