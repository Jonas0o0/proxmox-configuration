provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent       = var.proxmox_ssh_agent
    username    = var.proxmox_ssh_username
    private_key = var.proxmox_ssh_agent || var.proxmox_ssh_private_key_path == null ? null : file(pathexpand(var.proxmox_ssh_private_key_path))
  }
}
