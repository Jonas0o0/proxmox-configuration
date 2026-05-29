locals {
  container_template_id = var.container_template_file_id != null ? var.container_template_file_id : proxmox_virtual_environment_download_file.lxc_template[0].id
  root_password         = var.root_password != null ? var.root_password : random_password.root[0].result

  wg_nat_lines = var.wg_enable_nat ? [
    "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s ${var.wg_network_cidr} -o ${var.wg_wan_interface} -j MASQUERADE",
    "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s ${var.wg_network_cidr} -o ${var.wg_wan_interface} -j MASQUERADE",
  ] : []
  wg_nat_config = join("\n", local.wg_nat_lines)

  wg_peers_config = join("\n\n", [
    for peer in var.wg_peers : join("\n", compact([
      "[Peer]",
      "# ${peer.name}",
      "PublicKey = ${peer.public_key}",
      try(peer.preshared_key, null) == null ? "" : "PresharedKey = ${peer.preshared_key}",
      "AllowedIPs = ${join(", ", peer.allowed_ips)}",
    ]))
  ])

  wg_extra_config = trimspace(join("\n\n", compact([
    trimspace(local.wg_nat_config),
    trimspace(local.wg_peers_config),
  ])))

  wireguard_hook_script = templatefile("${path.module}/templates/wireguard-hook.sh.tftpl", {
    wg_interface    = jsonencode(var.wg_interface)
    wg_address      = jsonencode(var.wg_address)
    wg_listen_port  = var.wg_listen_port
    wg_private_key  = jsonencode(coalesce(var.wg_private_key, ""))
    wg_extra_config = local.wg_extra_config
  })
}
