# wg-easy CT

Ce dossier cree une CT LXC Alpine par defaut pour lancer [wg-easy](https://github.com/wg-easy/wg-easy) sur Proxmox.

Terraform gere :

- le telechargement du template LXC ;
- la creation de la CT ;
- le passage de `/dev/net/tun` dans la CT ;
- l'upload d'un hook Proxmox ;
- l'installation de Docker dans la CT ;
- la generation d'un `docker-compose.yml` wg-easy ;
- le demarrage du container Docker `wg-easy`.

## Prerequis

- Proxmox VE 9.x recommande pour `device_passthrough`.
- Un storage avec le contenu `snippets` active. Le bootstrap du repo peut creer le storage `snippets`.
- Un token API Proxmox. Pour ce module, utilise idealement `root@pam` car le hookscript doit etre executable.
- Acces SSH au node Proxmox pour uploader les snippets.
- Le port UDP `51820` doit etre ouvert ou redirige vers l'IP de la CT.
- Le port TCP `51821` donne acces a l'interface Web wg-easy.
- Docker dans LXC est plus simple avec une CT privilegiee, donc `container_unprivileged = false` par defaut.

## Utilisation

```bash
cd /root/prox/terraform/wireguard-ct
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

terraform init
terraform validate
terraform plan
terraform apply
```

Apres application, affiche l'URL :

```bash
terraform output -raw wg_easy_url
```

Par defaut :

```text
http://192.168.1.20:51821
```

## Verification

Verifier la CT :

```bash
pct status 110
pct enter 110
```

Verifier Docker et wg-easy :

```bash
pct exec 110 -- docker ps
pct exec 110 -- docker logs wg-easy
pct exec 110 -- docker compose -f /etc/docker/containers/wg-easy/docker-compose.yml ps
```

Relancer wg-easy :

```bash
pct exec 110 -- docker compose -f /etc/docker/containers/wg-easy/docker-compose.yml restart
```

Redemarrer toute la CT :

```bash
pct reboot 110
```

## Configuration wg-easy

Les clients WireGuard ne sont plus declares dans Terraform. Tu les crees depuis l'interface Web wg-easy.

Terraform garde l'infrastructure :

- CT ;
- reseau ;
- Docker ;
- container wg-easy ;
- ports exposes.

wg-easy garde la configuration WireGuard dans son volume Docker `etc_wireguard`.

## Configuration utilisee

La configuration applicative est versionnee ici :

[files/docker-compose.yml](files/docker-compose.yml)

Elle utilise :

- image : `ghcr.io/wg-easy/wg-easy:15` ;
- port WireGuard : `51820/udp` ;
- interface Web : `51821/tcp` ;
- volume Docker : `etc_wireguard` ;
- mode `INSECURE=true`.

`INSECURE=true` est pratique en LAN, mais l'interface Web doit rester limitee a un reseau de confiance. Pour une exposition publique, mets wg-easy derriere un reverse proxy HTTPS et adapte le compose.

## Alpine ou Debian

Alpine est le defaut du module :

```hcl
container_os_type      = "alpine"
container_template_url = "http://download.proxmox.com/images/system/alpine-3.23-default_20260116_amd64.tar.xz"
```

Debian reste possible :

```hcl
container_os_type      = "debian"
container_template_url = "http://download.proxmox.com/images/system/debian-12-standard_12.12-1_amd64.tar.zst"
```

## Notes Proxmox 8

Le module utilise `device_passthrough`, disponible dans le provider recent et pense pour Proxmox VE 9.x.

Si tu es sur Proxmox 8 et que `/dev/net/tun` ne passe pas correctement, il faudra soit passer a Proxmox 9, soit ajouter manuellement les lignes LXC equivalentes dans `/etc/pve/lxc/<vmid>.conf` :

```text
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

Puis redemarrer la CT.
