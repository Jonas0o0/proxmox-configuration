variable "proxmox_endpoint" {
  description = "Endpoint API Proxmox, exemple: https://pve.home.arpa:8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Token API Proxmox."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Ignore la verification TLS du certificat Proxmox."
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "Utilisateur SSH sur le node Proxmox. Requis pour uploader les snippets/hook scripts."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_private_key_path" {
  description = "Chemin de la cle privee SSH pour le node Proxmox."
  type        = string
  default     = "~/.ssh/proxmox_terraform"
  nullable    = true
}

variable "proxmox_ssh_agent" {
  description = "Utilise ssh-agent au lieu d'une cle privee explicite."
  type        = bool
  default     = false
}

variable "ssh_public_keys" {
  description = "Cles SSH autorisees dans les CT. Laisse vide si tu utilises seulement le mot de passe root genere par Terraform."
  type        = list(string)
  default     = []
}

variable "wg_easy_node_name" {
  description = "Nom du node Proxmox qui heberge la CT wg-easy."
  type        = string
  default     = "pve"
}

variable "wg_easy_container_id" {
  description = "VMID de la CT wg-easy."
  type        = number
  default     = 110
}

variable "wg_easy_container_hostname" {
  description = "Hostname de la CT wg-easy."
  type        = string
  default     = "wg-easy"
}

variable "wg_easy_rootfs_datastore_id" {
  description = "Storage Proxmox pour le disque rootfs de la CT wg-easy."
  type        = string
  default     = "local-lvm"
}

variable "wg_easy_snippets_datastore_id" {
  description = "Storage Proxmox avec contenu snippets active."
  type        = string
  default     = "snippets"
}

variable "wg_easy_network_bridge" {
  description = "Bridge Proxmox pour la CT wg-easy."
  type        = string
  default     = "vmbr0"
}

variable "wg_easy_network_vlan_id" {
  description = "VLAN de la CT wg-easy. Null pour aucun VLAN."
  type        = number
  default     = null
  nullable    = true
}

variable "wg_easy_ipv4_address" {
  description = "Adresse IPv4 de la CT wg-easy en CIDR, ou dhcp."
  type        = string
  default     = "192.168.1.20/24"
}

variable "wg_easy_ipv4_gateway" {
  description = "Gateway IPv4 de la CT wg-easy. Doit rester null si wg_easy_ipv4_address vaut dhcp."
  type        = string
  default     = "192.168.1.1"
  nullable    = true
}

variable "wg_easy_dns_servers" {
  description = "Serveurs DNS injectes dans la CT wg-easy."
  type        = list(string)
  default     = ["192.168.1.1", "1.1.1.1"]
}

variable "wg_easy_dns_domain" {
  description = "Domaine de recherche DNS de la CT wg-easy."
  type        = string
  default     = "home.arpa"
}

variable "caddy_node_name" {
  description = "Nom du node Proxmox qui heberge la CT Caddy."
  type        = string
  default     = "pve"
}

variable "caddy_container_id" {
  description = "VMID de la CT Caddy."
  type        = number
  default     = 109
}

variable "caddy_container_hostname" {
  description = "Hostname de la CT Caddy."
  type        = string
  default     = "caddy"
}

variable "caddy_rootfs_datastore_id" {
  description = "Storage Proxmox pour le disque rootfs de la CT Caddy."
  type        = string
  default     = "local-lvm"
}

variable "caddy_snippets_datastore_id" {
  description = "Storage Proxmox avec contenu snippets active."
  type        = string
  default     = "snippets"
}

variable "caddy_network_bridge" {
  description = "Bridge Proxmox pour la CT Caddy."
  type        = string
  default     = "vmbr0"
}

variable "caddy_network_vlan_id" {
  description = "VLAN de la CT Caddy. Null pour aucun VLAN."
  type        = number
  default     = null
  nullable    = true
}

variable "caddy_ipv4_address" {
  description = "Adresse IPv4 de la CT Caddy en CIDR, ou dhcp."
  type        = string
  default     = "192.168.1.30/24"
}

variable "caddy_ipv4_gateway" {
  description = "Gateway IPv4 de la CT Caddy. Doit rester null si caddy_ipv4_address vaut dhcp."
  type        = string
  default     = "192.168.1.1"
  nullable    = true
}

variable "caddy_dns_servers" {
  description = "Serveurs DNS injectes dans la CT Caddy."
  type        = list(string)
  default     = ["192.168.1.1", "1.1.1.1"]
}

variable "caddy_dns_domain" {
  description = "Domaine de recherche DNS de la CT Caddy."
  type        = string
  default     = "home.arpa"
}
