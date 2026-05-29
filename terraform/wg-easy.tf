module "wg_easy_ct" {
  source = "./modules/wg-easy-ct"

  node_name          = var.wg_easy_node_name
  container_id       = var.wg_easy_container_id
  container_hostname = var.wg_easy_container_hostname

  rootfs_datastore_id   = var.wg_easy_rootfs_datastore_id
  snippets_datastore_id = var.wg_easy_snippets_datastore_id

  network_bridge  = var.wg_easy_network_bridge
  network_vlan_id = var.wg_easy_network_vlan_id
  ipv4_address    = var.wg_easy_ipv4_address
  ipv4_gateway    = var.wg_easy_ipv4_gateway
  dns_servers     = var.wg_easy_dns_servers
  dns_domain      = var.wg_easy_dns_domain

  ssh_public_keys = var.ssh_public_keys
}
