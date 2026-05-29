# Terraform

Ce dossier contient les ressources Proxmox gerees par Terraform.

Terraform est adapte pour :

- creer des VM et containers ;
- gerer les templates cloud-init ;
- declarer les disques, CPU, RAM et cartes reseau ;
- appliquer une configuration reproductible apres une reinstall Proxmox.

Il n'est pas ideal pour tout ce qui touche a l'interieur des VM. Pour installer des services complexes, creer des utilisateurs Linux ou deployer des fichiers applicatifs, utilise plutot Ansible ensuite.


## Flux conseille

1. Configure Proxmox dans `terraform.tfvars`.
2. Decris les CT/VM voulues dans des fichiers `.tf` a la racine de ce dossier.
3. Lance `terraform init`.
4. Lance `terraform plan`.
5. Applique avec `terraform apply`.

Le token API Proxmox ne doit pas etre commit. Exporte-le avant de lancer Terraform :

```bash
export TF_VAR_proxmox_api_token='root@pam!terraform=token'
```

## Organisation

- `versions.tf` : versions Terraform/providers globales.
- `provider.tf` : configuration globale du provider Proxmox.
- `variables.tf` : variables globales Proxmox.
- `wg-easy.tf` : appel du module wg-easy.
- `modules/` : modules reutilisables pour les CT/VM.

## Modules disponibles

- [modules/wg-easy-ct](modules/wg-easy-ct/) : cree une CT LXC Alpine/Debian avec wg-easy.
