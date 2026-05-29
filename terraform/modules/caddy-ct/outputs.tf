output "container_id" {
  description = "ID de la CT Caddy."
  value       = proxmox_virtual_environment_container.caddy.vm_id
}

output "container_hostname" {
  description = "Hostname de la CT Caddy."
  value       = var.container_hostname
}

output "container_ipv4" {
  description = "Adresse IPv4 configuree pour la CT."
  value       = var.ipv4_address
}

output "caddy_http_url" {
  description = "URL HTTP de la CT Caddy."
  value       = var.ipv4_address == "dhcp" ? "http://<ip-dhcp>" : "http://${split("/", var.ipv4_address)[0]}"
}

output "caddy_https_url" {
  description = "URL HTTPS de la CT Caddy."
  value       = var.ipv4_address == "dhcp" ? "https://<ip-dhcp>" : "https://${split("/", var.ipv4_address)[0]}"
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

output "caddy_status_command" {
  description = "Commande a lancer sur le node Proxmox pour verifier le container Docker Caddy."
  value       = "pct exec ${var.container_id} -- docker ps --filter name=caddy"
}

output "caddy_logs_command" {
  description = "Commande a lancer sur le node Proxmox pour lire les logs Caddy."
  value       = "pct exec ${var.container_id} -- docker logs caddy"
}
