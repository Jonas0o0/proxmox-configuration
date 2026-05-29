output "container_id" {
  description = "ID de la CT WireGuard."
  value       = proxmox_virtual_environment_container.wireguard.vm_id
}

output "container_hostname" {
  description = "Hostname de la CT WireGuard."
  value       = var.container_hostname
}

output "container_ipv4" {
  description = "Adresse IPv4 configuree pour la CT."
  value       = var.ipv4_address
}

output "wireguard_listen_port" {
  description = "Port UDP WireGuard."
  value       = var.wg_listen_port
}

output "wireguard_server_address" {
  description = "Adresse du serveur dans le tunnel WireGuard."
  value       = var.wg_address
}

output "root_password" {
  description = "Mot de passe root de la CT si genere par Terraform ou fourni via variable."
  value       = local.root_password
  sensitive   = true
}

output "ssh_command" {
  description = "Commande SSH vers la CT."
  value       = var.ipv4_address == "dhcp" ? "ssh root@<ip-dhcp>" : "ssh root@${split("/", var.ipv4_address)[0]}"
}

output "wireguard_public_key_command" {
  description = "Commande a lancer sur le node Proxmox pour recuperer la cle publique WireGuard serveur."
  value       = "pct exec ${var.container_id} -- wg show ${var.wg_interface} public-key"
}

output "wireguard_status_command" {
  description = "Commande a lancer sur le node Proxmox pour verifier WireGuard."
  value       = "pct exec ${var.container_id} -- wg show ${var.wg_interface}"
}
