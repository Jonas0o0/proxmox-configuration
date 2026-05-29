# WireGuard CT

Ce dossier cree une CT LXC Alpine par defaut pour WireGuard sur Proxmox.

Terraform gere :

- le telechargement du template LXC ;
- la creation de la CT ;
- le passage de `/dev/net/tun` dans la CT ;
- le hook Proxmox qui installe et configure WireGuard dans la CT ;
- la configuration des peers WireGuard si tu les declares dans `wg_peers`.

## Prerequis

- Proxmox VE 9.x recommande pour `device_passthrough`.
- Un storage avec le contenu `snippets` active. Le bootstrap du repo peut creer le storage `snippets`.
- Un token API Proxmox. Pour ce module, utilise idealement `root@pam` car le hookscript doit etre executable.
- Acces SSH au node Proxmox pour uploader les snippets.
- Le port UDP WireGuard doit etre ouvert ou redirige vers l'IP de la CT.
- Si tu mets `network_firewall = true`, ajoute aussi une regle firewall Proxmox qui autorise l'UDP sur `wg_listen_port`.

## Alpine ou Debian

Alpine est le defaut du module :

```hcl
container_os_type      = "alpine"
container_template_url = "http://download.proxmox.com/images/system/alpine-3.23-default_20260116_amd64.tar.xz"
```

Pour WireGuard seul, Alpine est souvent le meilleur choix : image tres petite, surface systeme reduite, OpenRC simple.

Debian reste possible si tu veux un environnement plus familier ou plus proche de tes autres CT :

```hcl
container_os_type      = "debian"
container_template_url = "http://download.proxmox.com/images/system/debian-12-standard_12.12-1_amd64.tar.zst"
```

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

Apres application, recupere la cle publique du serveur :

```bash
terraform output -raw wireguard_public_key_command
pct exec 110 -- wg show wg0 public-key
```

Verifie le service :

```bash
pct exec 110 -- rc-service wg-quick.wg0 status
pct exec 110 -- wg show wg0
```

Sur Debian, la commande de service equivalente est :

```bash
pct exec 110 -- systemctl status wg-quick@wg0
```

## Ajouter un client

Ajoute un peer dans `terraform.tfvars` :

```hcl
wg_peers = [
  {
    name        = "phone"
    public_key  = "CLE_PUBLIQUE_DU_CLIENT"
    allowed_ips = ["10.8.0.2/32"]
  }
]
```

Puis applique :

```bash
terraform plan
terraform apply
```

Le hook mettra a jour `/etc/wireguard/wg0.conf` au prochain demarrage de la CT. Pour appliquer tout de suite :

```bash
pct reboot 110
```

Si tu mets `wg_private_key` ou `preshared_key` dans Terraform, ces secrets finiront dans le state Terraform. Pour eviter ca, laisse `wg_private_key` vide : la cle serveur sera generee dans la CT.

## Exemple de config client

```ini
[Interface]
Address = 10.8.0.2/32
PrivateKey = CLE_PRIVEE_DU_CLIENT
DNS = 192.168.1.1

[Peer]
PublicKey = CLE_PUBLIQUE_DU_SERVEUR
Endpoint = IP_PUBLIQUE_OU_DNS:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Notes Proxmox 8

Le module utilise `device_passthrough`, disponible dans le provider recent et pense pour Proxmox VE 9.x.

Si tu es sur Proxmox 8 et que `/dev/net/tun` ne passe pas correctement, il faudra soit passer a Proxmox 9, soit ajouter manuellement les lignes LXC equivalentes dans `/etc/pve/lxc/<vmid>.conf` :

```text
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

Puis redemarrer la CT.
