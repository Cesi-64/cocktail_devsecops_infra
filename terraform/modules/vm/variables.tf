variable "name" {
  description = "Nom court de la machine (ex : cocktail-staging)"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Groupe de ressources cible"
  type        = string
}

variable "vm_size" {
  description = "Taille de la VM (ex : Standard_B2s)"
  type        = string
}

variable "admin_username" {
  description = "Utilisateur administrateur créé sur la VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Clé publique SSH autorisée pour l'administrateur"
  type        = string
}

variable "address_space" {
  description = "Plage d'adresses du réseau virtuel"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_ports" {
  description = "Ports TCP ouverts à Internet"
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

variable "admin_ssh_cidrs" {
  description = "Plages IP autorisées en SSH de façon permanente (vide = aucune)"
  type        = list(string)
  default     = []
}

variable "os_disk_size_gb" {
  description = "Taille du disque système"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags appliqués aux ressources"
  type        = map(string)
  default     = {}
}
