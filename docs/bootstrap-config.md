# Reference proxmox-bootstrap.env

Ce fichier explique toutes les variables utilisables dans `config/proxmox-bootstrap.env`.

Le fichier reel n'est pas versionne. Cree-le depuis l'exemple :

```bash
cp config/proxmox-bootstrap.env.example config/proxmox-bootstrap.env
nano config/proxmox-bootstrap.env
```

Avant d'appliquer :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --dry-run
```

Puis :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --yes
```

## Regles de syntaxe

Le fichier est un fichier shell charge par `source`.

Utilise ce format :

```bash
VARIABLE="valeur"
OPTION=true
OPTION=false
```

Regles importantes :

- pas d'espace autour de `=` ;
- mets les valeurs texte entre guillemets ;
- pour les booleens, utilise `true` ou `false` ;
- ne mets pas de secrets dans Git ;
- ne commit jamais `config/proxmox-bootstrap.env`.

## Base

### `PROXMOX_HOSTNAME`

Nom court du node Proxmox.

Exemple :

```bash
PROXMOX_HOSTNAME="pve"
```

Le script applique la valeur avec :

```bash
hostnamectl set-hostname
```

### `TIMEZONE`

Fuseau horaire du serveur.

Exemple :

```bash
TIMEZONE="Europe/Paris"
```

Le script applique la valeur avec :

```bash
timedatectl set-timezone
```

## APT

### `APT_CHANNEL`

Configure les depots Proxmox.

Valeurs possibles :

| Valeur | Effet |
| --- | --- |
| `no-subscription` | active le repo Proxmox gratuit `pve-no-subscription` |
| `enterprise` | ne modifie pas les repos enterprise |
| `none` | ne gere pas les repos APT |

Exemple :

```bash
APT_CHANNEL="no-subscription"
```

Pour un homelab sans licence Proxmox, utilise generalement `no-subscription`.

### `RUN_APT_UPDATE`

Lance `apt-get update`.

Exemple :

```bash
RUN_APT_UPDATE=true
```

### `RUN_APT_DIST_UPGRADE`

Lance une mise a jour systeme avec :

```bash
apt-get -y dist-upgrade
```

Exemple prudent :

```bash
RUN_APT_DIST_UPGRADE=false
```

Active-le seulement si tu veux que le bootstrap mette aussi a jour les paquets systeme.

### `INSTALL_PACKAGES`

Liste de paquets a installer.

Exemple :

```bash
INSTALL_PACKAGES="curl git vim jq ifupdown2"
```

`ifupdown2` est utile pour recharger proprement la configuration reseau avec `ifreload -a`.

## SSH

### `SSH_HARDENING`

Active ou non la generation du fichier :

```text
/etc/ssh/sshd_config.d/99-proxmox-bootstrap.conf
```

Exemple :

```bash
SSH_HARDENING=false
```

Passe a `true` quand tes cles SSH sont pretes.

### `SSH_PASSWORD_AUTH`

Configure `PasswordAuthentication`.

Exemple :

```bash
SSH_PASSWORD_AUTH="no"
```

Valeurs courantes :

| Valeur | Effet |
| --- | --- |
| `no` | refuse la connexion SSH par mot de passe |
| `yes` | autorise la connexion SSH par mot de passe |

### `SSH_PERMIT_ROOT_LOGIN`

Configure `PermitRootLogin`.

Exemple :

```bash
SSH_PERMIT_ROOT_LOGIN="prohibit-password"
```

Valeurs courantes :

| Valeur | Effet |
| --- | --- |
| `prohibit-password` | root autorise seulement avec cle SSH |
| `yes` | root autorise |
| `no` | root interdit en SSH |

## Reseau

### `MANAGE_NETWORK`

Variable critique.

Si `false`, le script ne modifie pas `/etc/network/interfaces`.

Si `true`, le script reecrit `/etc/network/interfaces` a partir des variables reseau.

Exemple prudent :

```bash
MANAGE_NETWORK=false
```

Active seulement apres avoir verifie tes interfaces et IP :

```bash
MANAGE_NETWORK=true
```

Pour un premier run avec `MANAGE_NETWORK=true`, utilise la console locale ou l'interface Web Proxmox. Une erreur reseau peut couper SSH.

### `APPLY_NETWORK_RELOAD`

Recharge le reseau apres avoir ecrit `/etc/network/interfaces`.

Exemple prudent :

```bash
APPLY_NETWORK_RELOAD=false
```

Si `true`, le script utilise `ifreload -a` quand disponible, sinon `systemctl restart networking`.

### `MGMT_IFACE`

Interface physique principale.

Exemple :

```bash
MGMT_IFACE="eno1"
```

Commandes utiles pour trouver le bon nom :

```bash
ip link
ip address
```

### `MGMT_BRIDGE`

Bridge de gestion Proxmox.

Exemple :

```bash
MGMT_BRIDGE="vmbr0"
```

Le bridge principal est souvent `vmbr0`.

### `MGMT_ADDRESS`

Adresse IP de gestion du node Proxmox, avec CIDR.

Exemple :

```bash
MGMT_ADDRESS="192.168.1.10/24"
```

### `MGMT_GATEWAY`

Passerelle par defaut.

Exemple :

```bash
MGMT_GATEWAY="192.168.1.1"
```

### `MGMT_DNS`

Serveurs DNS.

Exemple :

```bash
MGMT_DNS="192.168.1.1 1.1.1.1"
```

### `BRIDGE_VLAN_AWARE`

Active le mode VLAN-aware sur le bridge principal.

Exemple :

```bash
BRIDGE_VLAN_AWARE=true
```

Garde `true` si tu veux utiliser des VLAN sur les VM.

### `BRIDGE_VIDS`

Liste des VLAN autorises sur le bridge VLAN-aware.

Exemple large :

```bash
BRIDGE_VIDS="2-4094"
```

Exemple limite :

```bash
BRIDGE_VIDS="10 20 30"
```

### `EXTRA_BRIDGES`

Permet de declarer des bridges supplementaires.

Format :

```text
"bridge:address:ports:comment"
```

Utilise `none` pour `address` ou `ports` si vide.

Exemple avec un bridge qui a une IP :

```bash
EXTRA_BRIDGES="vmbr20:192.168.20.1/24:none:services"
```

Exemple avec deux bridges :

```bash
EXTRA_BRIDGES="vmbr20:192.168.20.1/24:none:services vmbr30:none:none:lab"
```

Important : le format actuel separe les bridges par des espaces. N'utilise pas d'espaces dans le commentaire.

## Storage local Proxmox

### `CREATE_SNIPPETS_STORAGE`

Cree ou met a jour un storage Proxmox de type `dir` pour les snippets cloud-init.

Exemple :

```bash
CREATE_SNIPPETS_STORAGE=true
```

### `SNIPPETS_STORAGE_ID`

Nom du storage snippets dans Proxmox.

Exemple :

```bash
SNIPPETS_STORAGE_ID="snippets"
```

### `SNIPPETS_PATH`

Chemin local du storage snippets.

Exemple :

```bash
SNIPPETS_PATH="/var/lib/vz/snippets"
```

### `CREATE_BACKUP_DIR_STORAGE`

Cree ou met a jour un storage local de backups.

Exemple :

```bash
CREATE_BACKUP_DIR_STORAGE=false
```

Passe a `true` si tu veux declarer un dossier local comme destination de backup.

### `BACKUP_DIR_STORAGE_ID`

Nom du storage local de backups dans Proxmox.

Exemple :

```bash
BACKUP_DIR_STORAGE_ID="backup-local"
```

### `BACKUP_DIR_PATH`

Chemin local ou stocker les backups.

Exemple :

```bash
BACKUP_DIR_PATH="/var/lib/vz/dump"
```

## Proxmox Backup Server

### `PBS_ENABLED`

Ajoute ou met a jour un storage Proxmox Backup Server.

Exemple :

```bash
PBS_ENABLED=false
```

Passe a `true` si tu as deja un PBS pret.

### `PBS_STORAGE_ID`

Nom du storage PBS dans Proxmox.

Exemple :

```bash
PBS_STORAGE_ID="pbs"
```

### `PBS_SERVER`

Adresse DNS ou IP du serveur PBS.

Exemple :

```bash
PBS_SERVER="pbs.home.arpa"
```

### `PBS_DATASTORE`

Nom du datastore cote PBS.

Exemple :

```bash
PBS_DATASTORE="datastore"
```

### `PBS_USERNAME`

Utilisateur PBS.

Exemple :

```bash
PBS_USERNAME="root@pam"
```

### `PBS_PASSWORD_FILE`

Fichier local contenant le mot de passe PBS.

Exemple :

```bash
PBS_PASSWORD_FILE="/root/.pbs-password"
```

Le fichier doit exister sur le node Proxmox et ne doit pas etre commit.

Exemple de creation :

```bash
printf '%s\n' 'mot-de-passe-pbs' > /root/.pbs-password
chmod 600 /root/.pbs-password
```

### `PBS_FINGERPRINT`

Fingerprint du certificat PBS.

Exemple :

```bash
PBS_FINGERPRINT="AA:BB:CC:..."
```

Laisse vide si tu ne veux pas le fournir dans la configuration :

```bash
PBS_FINGERPRINT=""
```

## Job de backup Proxmox

### `BACKUP_JOB_ENABLED`

Cree ou met a jour un job de backup Proxmox.

Exemple :

```bash
BACKUP_JOB_ENABLED=false
```

Passe a `true` quand le storage cible existe.

### `BACKUP_JOB_ID`

Identifiant du job de backup.

Exemple :

```bash
BACKUP_JOB_ID="daily-all"
```

### `BACKUP_JOB_STORAGE`

Storage ou envoyer les backups.

Exemples :

```bash
BACKUP_JOB_STORAGE="backup-local"
BACKUP_JOB_STORAGE="pbs"
```

### `BACKUP_JOB_SCHEDULE`

Planification du job.

Exemples :

```bash
BACKUP_JOB_SCHEDULE="daily"
BACKUP_JOB_SCHEDULE="sat 03:00"
BACKUP_JOB_SCHEDULE="mon..fri 02:30"
```

### `BACKUP_JOB_MODE`

Mode de backup.

Valeurs courantes :

| Valeur | Usage |
| --- | --- |
| `snapshot` | backup sans arret de la VM quand possible |
| `suspend` | suspend temporairement la VM |
| `stop` | arrete la VM pendant le backup |

Exemple :

```bash
BACKUP_JOB_MODE="snapshot"
```

### `BACKUP_JOB_VMID`

VM concernees par le job.

Exemples :

```bash
BACKUP_JOB_VMID="all"
BACKUP_JOB_VMID="101,102,103"
```

### `BACKUP_JOB_PRUNE`

Retention des backups.

Exemple :

```bash
BACKUP_JOB_PRUNE="keep-daily=7,keep-weekly=4,keep-monthly=3"
```

## Terraform

### `RUN_TERRAFORM`

Lance Terraform a la fin du bootstrap.

Exemple prudent :

```bash
RUN_TERRAFORM=false
```

Passe a `true` si tu veux qu'une seule commande configure le node puis applique les VM.

### `TERRAFORM_DIR`

Dossier Terraform a executer.

Exemple :

```bash
TERRAFORM_DIR="/root/prox/terraform/wireguard-ct"
```

Le script lance :

```bash
terraform -chdir="$TERRAFORM_DIR" init
terraform -chdir="$TERRAFORM_DIR" apply
```

### `TERRAFORM_AUTO_APPROVE`

Ajoute `-auto-approve` a `terraform apply`.

Exemple prudent :

```bash
TERRAFORM_AUTO_APPROVE=false
```

Pour les premiers runs, garde `false` afin de lire le plan Terraform avant application.

## Exemples de profils

### Profil minimal

```bash
PROXMOX_HOSTNAME="pve"
TIMEZONE="Europe/Paris"
APT_CHANNEL="no-subscription"
RUN_APT_UPDATE=true
RUN_APT_DIST_UPGRADE=false
INSTALL_PACKAGES="curl git vim jq ifupdown2"

SSH_HARDENING=false

MANAGE_NETWORK=false

CREATE_SNIPPETS_STORAGE=true
CREATE_BACKUP_DIR_STORAGE=false
PBS_ENABLED=false
BACKUP_JOB_ENABLED=false

RUN_TERRAFORM=false
```

### Profil avec reseau gere par le repo

```bash
MANAGE_NETWORK=true
APPLY_NETWORK_RELOAD=false
MGMT_IFACE="eno1"
MGMT_BRIDGE="vmbr0"
MGMT_ADDRESS="192.168.1.10/24"
MGMT_GATEWAY="192.168.1.1"
MGMT_DNS="192.168.1.1 1.1.1.1"
BRIDGE_VLAN_AWARE=true
BRIDGE_VIDS="2-4094"
```

Applique d'abord avec `APPLY_NETWORK_RELOAD=false`, relis `/etc/network/interfaces`, puis active le reload quand tu es certain.

### Profil avec PBS et backup journalier

```bash
PBS_ENABLED=true
PBS_STORAGE_ID="pbs"
PBS_SERVER="pbs.home.arpa"
PBS_DATASTORE="datastore"
PBS_USERNAME="root@pam"
PBS_PASSWORD_FILE="/root/.pbs-password"
PBS_FINGERPRINT=""

BACKUP_JOB_ENABLED=true
BACKUP_JOB_ID="daily-all"
BACKUP_JOB_STORAGE="pbs"
BACKUP_JOB_SCHEDULE="daily"
BACKUP_JOB_MODE="snapshot"
BACKUP_JOB_VMID="all"
BACKUP_JOB_PRUNE="keep-daily=7,keep-weekly=4,keep-monthly=3"
```

### Profil avec Terraform

```bash
RUN_TERRAFORM=true
TERRAFORM_DIR="/root/prox/terraform/wireguard-ct"
TERRAFORM_AUTO_APPROVE=false
```

## Verification apres modification

Avant application :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --dry-run
```

Apres application :

```bash
pveversion
pvesm status
qm list
cat /etc/network/interfaces
```
