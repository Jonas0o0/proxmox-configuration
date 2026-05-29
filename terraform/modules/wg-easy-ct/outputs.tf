output "container_id" {
  description = "ID de la CT wg-easy."
  value       = proxmox_virtual_environment_container.wg_easy.vm_id
}

output "container_hostname" {
  description = "Hostname de la CT wg-easy."
  value       = var.container_hostname
}

output "container_ipv4" {
  description = "Adresse IPv4 configuree pour la CT."
  value       = var.ipv4_address
}

output "wg_easy_url" {
  description = "URL de l'interface Web wg-easy."
  value       = var.ipv4_address == "dhcp" ? "http://<ip-dhcp>:51821" : "http://${split("/", var.ipv4_address)[0]}:51821"
}

output "wg_easy_wireguard_port" {
  description = "Port UDP WireGuard expose par wg-easy."
  value       = 51820
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

output "wg_easy_status_command" {
  description = "Commande a lancer sur le node Proxmox pour verifier le container Docker wg-easy."
  value       = "pct exec ${var.container_id} -- docker ps --filter name=wg-easy"
}

output "wg_easy_logs_command" {
  description = "Commande a lancer sur le node Proxmox pour lire les logs wg-easy."
  value       = "pct exec ${var.container_id} -- docker logs wg-easy"
}
