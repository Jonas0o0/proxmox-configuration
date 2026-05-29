# Reference proxmox-bootstrap.yml

Ce fichier explique les cles utilisables dans `config/proxmox-bootstrap.yml`.

Le fichier reel n'est pas versionne. Cree-le depuis l'exemple :

```bash
cp config/proxmox-bootstrap.yml.example config/proxmox-bootstrap.yml
nano config/proxmox-bootstrap.yml
```

Avant d'appliquer :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --dry-run
```

Puis :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --yes
```

## Format

Le script lit un YAML simple et arborescent, sans dependance externe :

```yaml
section:
  cle: valeur
  liste:
    - valeur1
    - valeur2
```

Garde une indentation de 2 espaces. Les objets complexes dans des listes ne sont pas supportes par ce parser.

## Base

```yaml
base:
  proxmox_hostname: pve
  timezone: Europe/Paris
```

- `base.proxmox_hostname` : nom court du node Proxmox.
- `base.timezone` : fuseau horaire systeme.

## APT

```yaml
apt:
  channel: no-subscription
  update: true
  dist_upgrade: false
  packages:
    - curl
    - git
    - vim
    - jq
    - ifupdown2
```

- `apt.channel` : `no-subscription`, `enterprise` ou `none`.
- `apt.update` : lance `apt-get update`.
- `apt.dist_upgrade` : lance `apt-get -y dist-upgrade`.
- `apt.packages` : paquets a installer sur le node.

## SSH

```yaml
ssh:
  hardening: false
  password_auth: "no"
  permit_root_login: prohibit-password
```

- `ssh.hardening` : cree `/etc/ssh/sshd_config.d/99-proxmox-bootstrap.conf`.
- `ssh.password_auth` : valeur de `PasswordAuthentication`.
- `ssh.permit_root_login` : valeur de `PermitRootLogin`.

Active `ssh.hardening` seulement quand tes cles SSH sont pretes.

## Reseau

```yaml
network:
  enabled: false
  reload: false

  management:
    iface: eno1
    bridge: vmbr0
    address: 192.168.1.10/24
    gateway: 192.168.1.1
    dns:
      - 192.168.1.1
      - 1.1.1.1

  bridge:
    vlan_aware: true
    vids: 2-4094
```

- `network.enabled` : si `true`, le script reecrit `/etc/network/interfaces`.
- `network.reload` : recharge le reseau apres modification.
- `network.management.iface` : interface physique principale.
- `network.management.bridge` : bridge Proxmox principal.
- `network.management.address` : IP/CIDR du node Proxmox.
- `network.management.gateway` : passerelle.
- `network.management.dns` : serveurs DNS.
- `network.bridge.vlan_aware` : active le mode VLAN-aware.
- `network.bridge.vids` : VLAN autorises sur le bridge.

Pour un premier run avec `network.enabled: true`, utilise la console locale ou l'interface Web Proxmox. Une erreur reseau peut couper SSH.

## Bridges supplementaires

```yaml
network:
  extra_bridges:
    - "vmbr20:192.168.20.1/24:none:services"
    - "vmbr30:none:none:lab"
```

Format :

```text
bridge:address:ports:comment
```

Utilise `none` pour `address` ou `ports` si vide. N'utilise pas d'espaces dans le commentaire.

## Storage local

```yaml
storage:
  snippets:
    enabled: true
    id: snippets
    path: /var/lib/vz/snippets

  backup_dir:
    enabled: false
    id: backup-local
    path: /var/lib/vz/dump
```

- `storage.snippets.enabled` : cree un storage Proxmox pour les snippets.
- `storage.snippets.id` : nom du storage snippets.
- `storage.snippets.path` : chemin local du storage snippets.
- `storage.backup_dir.enabled` : cree un storage local pour les backups.
- `storage.backup_dir.id` : nom du storage backup.
- `storage.backup_dir.path` : chemin local des backups.

## Proxmox Backup Server

```yaml
pbs:
  enabled: false
  storage_id: pbs
  server: pbs.example.local
  datastore: datastore
  username: root@pam
  password_file: /root/.pbs-password
  fingerprint: ""
```

- `pbs.enabled` : ajoute ou met a jour un storage PBS.
- `pbs.storage_id` : nom du storage PBS dans Proxmox.
- `pbs.server` : DNS ou IP du serveur PBS.
- `pbs.datastore` : datastore cote PBS.
- `pbs.username` : utilisateur PBS.
- `pbs.password_file` : fichier local contenant le mot de passe PBS.
- `pbs.fingerprint` : fingerprint du certificat PBS, optionnel.

Le fichier `pbs.password_file` doit exister sur le node et ne doit pas etre commit.

## Backup

```yaml
backup:
  job:
    enabled: false
    id: daily-all
    storage: backup-local
    schedule: daily
    mode: snapshot
    vmid: all
    prune: keep-daily=7,keep-weekly=4,keep-monthly=3
```

- `backup.job.enabled` : cree ou met a jour un job de backup.
- `backup.job.id` : identifiant du job.
- `backup.job.storage` : storage cible.
- `backup.job.schedule` : planification Proxmox.
- `backup.job.mode` : `snapshot`, `suspend` ou `stop`.
- `backup.job.vmid` : `all` ou liste de VMID separees par virgules.
- `backup.job.prune` : retention des backups.

## Terraform

```yaml
terraform:
  enabled: false
  dir: /root/prox/terraform/wireguard-ct
  auto_approve: false
```

- `terraform.enabled` : lance Terraform a la fin du bootstrap.
- `terraform.dir` : dossier Terraform a executer.
- `terraform.auto_approve` : ajoute `-auto-approve` a `terraform apply`.

Garde `terraform.auto_approve: false` au debut pour lire le plan Terraform avant application.

## Profil minimal

```yaml
base:
  proxmox_hostname: pve
  timezone: Europe/Paris

apt:
  channel: no-subscription
  update: true
  dist_upgrade: false
  packages:
    - curl
    - git
    - vim
    - jq
    - ifupdown2

ssh:
  hardening: false

network:
  enabled: false

storage:
  snippets:
    enabled: true
  backup_dir:
    enabled: false

pbs:
  enabled: false

backup:
  job:
    enabled: false

terraform:
  enabled: false
```
