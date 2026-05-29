resource "random_password" "root" {
  count = var.root_password == null ? 1 : 0

  length           = 24
  override_special = "_%@-"
  special          = true
}

resource "proxmox_virtual_environment_download_file" "lxc_template" {
  count = var.container_template_file_id == null ? 1 : 0

  content_type = "vztmpl"
  datastore_id = var.template_datastore_id
  node_name    = var.node_name
  url          = var.container_template_url
  file_name    = basename(var.container_template_url)
}

resource "proxmox_virtual_environment_file" "wireguard_hook" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name
  file_mode    = "0700"

  source_raw {
    data      = local.wireguard_hook_script
    file_name = "${var.container_hostname}-wireguard-hook.sh"
  }
}

resource "proxmox_virtual_environment_container" "wireguard" {
  description = var.container_description
  tags        = var.container_tags

  node_name = var.node_name
  vm_id     = var.container_id

  hook_script_file_id = proxmox_virtual_environment_file.wireguard_hook.id
  protection          = false
  started             = var.container_started
  start_on_boot       = var.container_start_on_boot
  unprivileged        = var.container_unprivileged

  features {
    keyctl  = true
    mknod   = true
    nesting = true
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.rootfs_datastore_id
    size         = var.rootfs_size_gb
  }

  device_passthrough {
    path = "/dev/net/tun"
    mode = "0666"
  }

  initialization {
    hostname = var.container_hostname

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

    user_account {
      keys     = var.ssh_public_keys
      password = local.root_password
    }
  }

  network_interface {
    name     = "eth0"
    bridge   = var.network_bridge
    firewall = var.network_firewall
    vlan_id  = var.network_vlan_id
  }

  operating_system {
    template_file_id = local.container_template_id
    type             = var.container_os_type
  }

  startup {
    order      = "1"
    up_delay   = "30"
    down_delay = "30"
  }
}
