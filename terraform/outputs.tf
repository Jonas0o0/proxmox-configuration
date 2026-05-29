output "wg_easy_url" {
  description = "URL de l'interface Web wg-easy."
  value       = module.wg_easy_ct.wg_easy_url
}

output "wg_easy_wireguard_port" {
  description = "Port UDP WireGuard expose par wg-easy."
  value       = module.wg_easy_ct.wg_easy_wireguard_port
}

output "wg_easy_status_command" {
  description = "Commande a lancer sur le node Proxmox pour verifier le container Docker wg-easy."
  value       = module.wg_easy_ct.wg_easy_status_command
}

output "wg_easy_logs_command" {
  description = "Commande a lancer sur le node Proxmox pour lire les logs wg-easy."
  value       = module.wg_easy_ct.wg_easy_logs_command
}

output "wg_easy_ssh_command" {
  description = "Commande SSH vers la CT wg-easy."
  value       = module.wg_easy_ct.ssh_command
}

output "wg_easy_root_password" {
  description = "Mot de passe root de la CT wg-easy si genere par Terraform."
  value       = module.wg_easy_ct.root_password
  sensitive   = true
}

output "caddy_http_url" {
  description = "URL HTTP de la CT Caddy."
  value       = module.caddy_ct.caddy_http_url
}

output "caddy_https_url" {
  description = "URL HTTPS de la CT Caddy."
  value       = module.caddy_ct.caddy_https_url
}

output "caddy_status_command" {
  description = "Commande a lancer sur le node Proxmox pour verifier le container Docker Caddy."
  value       = module.caddy_ct.caddy_status_command
}

output "caddy_logs_command" {
  description = "Commande a lancer sur le node Proxmox pour lire les logs Caddy."
  value       = module.caddy_ct.caddy_logs_command
}

output "caddy_ssh_command" {
  description = "Commande SSH vers la CT Caddy."
  value       = module.caddy_ct.ssh_command
}

output "caddy_root_password" {
  description = "Mot de passe root de la CT Caddy si genere par Terraform."
  value       = module.caddy_ct.root_password
  sensitive   = true
}
