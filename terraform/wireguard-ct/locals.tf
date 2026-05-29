locals {
  container_template_id = var.container_template_file_id != null ? var.container_template_file_id : proxmox_virtual_environment_download_file.lxc_template[0].id
  root_password         = var.root_password != null ? var.root_password : random_password.root[0].result
}
