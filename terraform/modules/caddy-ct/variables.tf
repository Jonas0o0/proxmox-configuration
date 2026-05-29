variable "node_name" {
  description = "Nom du node Proxmox qui heberge la CT."
  type        = string
  default     = "pve"
}

variable "container_id" {
  description = "VMID de la CT caddy."
  type        = number
  default     = 109
}

variable "container_hostname" {
  description = "Hostname de la CT caddy."
  type        = string
  default     = "caddy"
}

variable "container_description" {
  description = "Description visible dans Proxmox."
  type        = string
  default     = "caddy CT managed by Terraform"
}

variable "container_tags" {
  description = "Tags Proxmox."
  type        = list(string)
  default     = ["terraform", "caddy", "reverse-proxy"]
}

variable "container_unprivileged" {
  description = "Cree une CT non privilegiee. Docker dans LXC est plus simple en privilegie, donc false par defaut."
  type        = bool
  default     = false
}

variable "container_os_type" {
  description = "Type d'OS LXC Proxmox. Valeurs supportees par ce module: alpine ou debian."
  type        = string
  default     = "alpine"

  validation {
    condition     = contains(["alpine", "debian"], var.container_os_type)
    error_message = "container_os_type doit valoir alpine ou debian."
  }
}

variable "container_started" {
  description = "Demarre la CT apres creation."
  type        = bool
  default     = true
}

variable "container_start_on_boot" {
  description = "Demarre la CT automatiquement au boot du node."
  type        = bool
  default     = true
}

variable "template_datastore_id" {
  description = "Storage Proxmox pour le template LXC."
  type        = string
  default     = "local"
}

variable "container_template_file_id" {
  description = "Template LXC deja present, exemple: local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz. Si null, Terraform telecharge container_template_url."
  type        = string
  default     = null
  nullable    = true
}

variable "container_template_url" {
  description = "URL du template LXC a telecharger si container_template_file_id est null."
  type        = string
  default     = "http://download.proxmox.com/images/system/alpine-3.23-default_20260116_amd64.tar.xz"
}

variable "rootfs_datastore_id" {
  description = "Storage Proxmox pour le disque rootfs de la CT."
  type        = string
  default     = "local-lvm"
}

variable "rootfs_size_gb" {
  description = "Taille du rootfs en Go."
  type        = number
  default     = 8
}

variable "cpu_cores" {
  description = "Nombre de cores CPU."
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "RAM dediee en Mo."
  type        = number
  default     = 1024
}

variable "swap_mb" {
  description = "Swap en Mo."
  type        = number
  default     = 256
}

variable "network_bridge" {
  description = "Bridge Proxmox pour la CT."
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN de la CT. Null pour aucun VLAN."
  type        = number
  default     = null
  nullable    = true
}

variable "network_firewall" {
  description = "Active le firewall Proxmox sur l'interface de la CT."
  type        = bool
  default     = false
}

variable "ipv4_address" {
  description = "Adresse IPv4 de la CT en CIDR, ou dhcp."
  type        = string
  default     = "192.168.1.30/24"
}

variable "ipv4_gateway" {
  description = "Gateway IPv4. Doit rester null si ipv4_address vaut dhcp."
  type        = string
  default     = "192.168.1.1"
  nullable    = true
}

variable "dns_servers" {
  description = "Serveurs DNS injectes dans la CT."
  type        = list(string)
  default     = ["192.168.1.1", "1.1.1.1"]
}

variable "dns_domain" {
  description = "Domaine de recherche DNS."
  type        = string
  default     = "home.arpa"
}

variable "ssh_public_keys" {
  description = "Cles SSH autorisees pour root dans la CT."
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Mot de passe root de la CT. Si null, Terraform en genere un."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "snippets_datastore_id" {
  description = "Storage Proxmox avec contenu snippets active. Utilise pour le hookscript."
  type        = string
  default     = "snippets"
}
