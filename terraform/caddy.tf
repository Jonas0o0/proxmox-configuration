module "caddy_ct" {
  source = "./modules/caddy-ct"

  node_name          = var.caddy_node_name
  container_id       = var.caddy_container_id
  container_hostname = var.caddy_container_hostname

  rootfs_datastore_id   = var.caddy_rootfs_datastore_id
  snippets_datastore_id = var.caddy_snippets_datastore_id

  network_bridge  = var.caddy_network_bridge
  network_vlan_id = var.caddy_network_vlan_id
  ipv4_address    = var.caddy_ipv4_address
  ipv4_gateway    = var.caddy_ipv4_gateway
  dns_servers     = var.caddy_dns_servers
  dns_domain      = var.caddy_dns_domain

  ssh_public_keys = var.ssh_public_keys
}
