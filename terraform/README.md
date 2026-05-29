# Terraform

Ce dossier contient les ressources Proxmox gerees par Terraform.

Terraform est adapte pour :

- creer des VM et containers ;
- gerer les templates cloud-init ;
- declarer les disques, CPU, RAM et cartes reseau ;
- appliquer une configuration reproductible apres une reinstall Proxmox.

Il n'est pas ideal pour tout ce qui touche a l'interieur des VM. Pour installer des services complexes, creer des utilisateurs Linux ou deployer des fichiers applicatifs, utilise plutot Ansible ensuite.


## Flux conseille

1. Decris les ressources voulues directement dans les fichiers Terraform.
2. Lance `terraform init`.
3. Lance `terraform plan`.
4. Applique avec `terraform apply`.

## Modules disponibles

- [wireguard-ct](wireguard-ct/) : cree une CT LXC Alpine/Debian avec wg-easy.
