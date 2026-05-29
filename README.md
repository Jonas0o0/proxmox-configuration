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

cp config/proxmox-bootstrap.env.example config/proxmox-bootstrap.env
nano config/proxmox-bootstrap.env

sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --dry-run
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --yes
```

Le `--dry-run` permet de voir les actions avant de modifier le systeme.

## Structure du projet

```text
.
|-- config/
|   `-- proxmox-bootstrap.env.example
|-- docs/
|   |-- bootstrap-config.md
|   |-- new-machine.md
|   `-- update-existing-node.md
|-- inventory/
|   `-- proxmox.example.yml
|-- scripts/
|   `-- bootstrap-proxmox.sh
`-- terraform/
    |-- README.md
    `-- wireguard-ct/
```

## Bootstrap Proxmox

Le script principal est :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --yes
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

cd /root/prox/terraform/wireguard-ct
terraform init
terraform validate
terraform plan
terraform apply
```

## Terraform

Terraform est utilise pour gerer les ressources Proxmox : VM, CT, disques, reseau et templates.

Module disponible :

- [terraform/wireguard-ct](terraform/wireguard-ct/) : cree une CT LXC Alpine/Debian avec WireGuard.

Exemple WireGuard :

```bash
cd /root/prox/terraform/wireguard-ct
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

terraform init
terraform validate
terraform plan
terraform apply
```


## Realise par

Projet realise par Jonas Facon.

- Email : [jonas.facon@proton.me](mailto:jonas.facon@proton.me)
- GitHub : [Jonas0o0](https://github.com/Jonas0o0)
