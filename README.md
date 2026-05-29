# Homelab Proxmox

Ce projet contient ma configuration Proxmox VE pour mon homelab.

Il me sert a heberger mes projets personnels sur une infrastructure reproductible, avec un axe fort autour de l'automatisation.

L'objectif est simple : apres une installation Proxmox fraiche, je dois pouvoir relancer une configuration propre avec un script de bootstrap, puis creer ou mettre a jour les ressources Proxmox avec Terraform.

## Objectifs

- Centraliser la configuration de mon homelab Proxmox.
- Heberger mes projets personnels dans des VM ou CT reproductibles.
- Garder une trace claire des choix reseau, stockage, VM, CT et backups.
- Automatiser les actions repetitives avec un script unique.
- Gerer les ressources Proxmox avec Terraform.
- Eviter de stocker les secrets dans Git.

## Demarrage rapide

Sur un serveur Proxmox fraichement installe :

```bash
git clone <url-du-repo> /root/prox
cd /root/prox

nano config/proxmox-bootstrap.yml

sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --dry-run
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --yes
```

Le `--dry-run` permet de voir les actions avant de modifier le systeme.

## Structure du projet

```text
.
|-- config/
|   |-- proxmox-bootstrap.yml
|   `-- proxmox-bootstrap.yml.example
|-- .github/
|   `-- workflows/
|       `-- proxmox-gitops.yml
|-- docs/
|   |-- bootstrap-config.md
|   |-- gitops.md
|   |-- new-machine.md
|   `-- update-existing-node.md
|-- scripts/
|   `-- bootstrap-proxmox.sh
`-- terraform/
    |-- README.md
    |-- caddy.tf
    |-- provider.tf
    |-- versions.tf
    |-- wg-easy.tf
    `-- modules/
```

## Bootstrap Proxmox

Le script principal est :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --yes
```

Il peut gerer :

- hostname et timezone ;
- depots Proxmox `no-subscription` ;
- `apt update`, installation de paquets et upgrade optionnel ;
- durcissement SSH optionnel ;
- configuration reseau optionnelle via `/etc/network/interfaces` ;
- storages Proxmox locaux pour snippets et backups ;
- Proxmox Backup Server ;
- jobs de backup ;
- lancement Terraform optionnel.

La reference complete des variables est ici :

[docs/bootstrap-config.md](docs/bootstrap-config.md)

## Nouvelle machine

Pour installer une nouvelle machine depuis une cle USB avec l'ISO Proxmox, suis cette procedure :

[docs/new-machine.md](docs/new-machine.md)

Elle couvre :

- les valeurs a preparer avant installation ;
- le boot sur la cle USB ;
- les choix dans l'installateur Proxmox ;
- le premier acces Web ;
- le clone du repo ;
- le bootstrap ;
- le lancement Terraform.

## Mise a jour d'un node existant

Quand le repo change, par exemple apres ajout d'une nouvelle CT ou VM Terraform :

[docs/update-existing-node.md](docs/update-existing-node.md)

Workflow typique :

```bash
cd /root/prox
git pull

cd /root/prox/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

## GitOps

Le repo peut appliquer automatiquement les changements Proxmox a chaque push sur `main`.

Le workflow est ici :

[.github/workflows/proxmox-gitops.yml](.github/workflows/proxmox-gitops.yml)

Il utilise un runner GitHub Actions self-hosted dans le homelab. A chaque run, il upload le repo sur le node Proxmox puis lance `scripts/bootstrap-proxmox.sh`.

Le bootstrap configure le node et lance Terraform si `terraform.enabled: true` dans `config/proxmox-bootstrap.yml`.

Les secrets restent dans GitHub Actions. La configuration non sensible du node est dans :

[config/proxmox-bootstrap.yml](config/proxmox-bootstrap.yml)

Documentation :

[docs/gitops.md](docs/gitops.md)

## Terraform

Terraform est utilise pour gerer les ressources Proxmox : VM, CT, disques, reseau et templates.

Module disponible :

- [terraform/wg-easy.tf](terraform/wg-easy.tf) : declare la CT wg-easy.
- [terraform/caddy.tf](terraform/caddy.tf) : declare la CT Caddy.
- [terraform/modules/wg-easy-ct](terraform/modules/wg-easy-ct/) : module reutilisable qui cree une CT LXC Alpine/Debian avec wg-easy.
- [terraform/modules/caddy-ct](terraform/modules/caddy-ct/) : module reutilisable qui cree une CT LXC Alpine/Debian avec Caddy.

Exemple wg-easy :

```bash
cd /root/prox/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
nano wg-easy.tf

terraform init
terraform validate
terraform plan
terraform apply
```


## Realise par

Projet realise par Jonas Facon.

- Email : [jonas.facon@proton.me](mailto:jonas.facon@proton.me)
- GitHub : [Jonas0o0](https://github.com/Jonas0o0)
