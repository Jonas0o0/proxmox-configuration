# Terraform

Ce dossier contient les ressources Proxmox gerees par Terraform.

Terraform est adapte pour :

- creer des VM et containers ;
- gerer les templates cloud-init ;
- declarer les disques, CPU, RAM et cartes reseau ;
- appliquer une configuration reproductible apres une reinstall Proxmox.

Il n'est pas ideal pour tout ce qui touche a l'interieur des VM. Pour installer Docker, configurer WireGuard, creer des utilisateurs Linux ou deployer des services, utilise plutot Ansible ensuite.


## Flux conseille

1. Decris l'etat voulu dans `inventory/proxmox.yml`.
2. Traduis les VM importantes en ressources Terraform.
3. Lance `terraform init`.
4. Lance `terraform plan`.
5. Applique avec `terraform apply`.

## Modules disponibles

- [wireguard-ct](wireguard-ct/) : cree une CT LXC Alpine/Debian avec WireGuard.
