# Nouvelle machine Proxmox

Cette procedure part du moment ou la cle USB avec l'ISO Proxmox est branchee sur la machine.

## 1. Avant de demarrer

Prepare ces valeurs avant l'installation :

| Valeur | Exemple |
| --- | --- |
| Nom du node Proxmox | `pve` |
| Nom DNS complet | `pve.home.arpa` |
| Interface reseau principale | `eno1` |
| IP de gestion Proxmox | `192.168.1.10/24` |
| Passerelle | `192.168.1.1` |
| DNS | `192.168.1.1`, `1.1.1.1` |
| Disque systeme | SSD/NVMe dedie a Proxmox |
| Systeme de fichiers | ext4, xfs ou zfs selon ton besoin |
| Mot de passe root | secret, hors Git |
| Email admin | adresse pour alertes Proxmox |

Si tu veux configurer le reseau avec le script plus tard, garde aussi les valeurs correspondantes dans `config/proxmox-bootstrap.yml`.

## 2. Booter sur la cle USB

1. Branche la cle USB Proxmox.
2. Allume la machine.
3. Ouvre le boot menu BIOS/UEFI.
4. Choisis la cle USB.
5. Lance l'installation Proxmox VE.

Si Secure Boot bloque le demarrage, desactive-le dans le BIOS/UEFI.

## 3. Installer Proxmox

Dans l'installateur Proxmox :

1. Choisis `Install Proxmox VE`.
2. Accepte la licence.
3. Choisis le disque cible.
4. Choisis le pays, le fuseau horaire et le clavier.
5. Renseigne le mot de passe `root` et l'email admin.
6. Configure le reseau de gestion :
   - interface principale, exemple `eno1` ;
   - hostname, exemple `pve.home.arpa` ;
   - IP/CIDR, exemple `192.168.1.10/24` ;
   - gateway, exemple `192.168.1.1` ;
   - DNS, exemple `192.168.1.1`.
7. Valide le resume d'installation.
8. Quand l'installation est terminee, retire la cle USB.
9. Redemarre sur le disque interne.

## 4. Premier acces Proxmox

Depuis ton navigateur :

```text
https://IP_DU_PROXMOX:8006
```

Exemple :

```text
https://192.168.1.10:8006
```

Connecte-toi avec :

```text
root@pam
```

Le navigateur peut afficher une alerte certificat. C'est normal sur une installation fraiche.

## 5. Recuperer le repo sur le node

Connecte-toi au shell Proxmox, soit depuis l'interface Web, soit en SSH :

```bash
ssh root@192.168.1.10
```

Installe `git` si besoin :

```bash
apt update
apt install -y git
```

Clone le repo :

```bash
git clone <url-du-repo> /root/prox
cd /root/prox
```

Si le node n'a pas encore acces a Git, copie le repo depuis ta machine :

```bash
scp -r ./prox root@192.168.1.10:/root/prox
```

## 6. Preparer la configuration bootstrap

Copie le fichier exemple :

```bash
cd /root/prox
cp config/proxmox-bootstrap.yml.example config/proxmox-bootstrap.yml
nano config/proxmox-bootstrap.yml
```

Verifie surtout :

```yaml
base:
  proxmox_hostname: pve
  timezone: Europe/Paris

apt:
  channel: no-subscription
  packages:
    - curl
    - git
    - vim
    - jq
    - ifupdown2
```

Pour le reseau, par defaut le script ne reecrit pas `/etc/network/interfaces` :

```yaml
network:
  enabled: false
```

Passe a `true` seulement si tu veux que le repo devienne la source de verite du reseau :

```yaml
network:
  enabled: true
  management:
    iface: eno1
    bridge: vmbr0
    address: 192.168.1.10/24
    gateway: 192.168.1.1
    dns:
      - 192.168.1.1
      - 1.1.1.1
```

Si tu actives `network.enabled: true`, fais le premier run depuis la console locale ou l'interface Web Proxmox. Une erreur reseau peut couper ta session SSH.

## 7. Tester sans appliquer

Lance un dry-run :

```bash
cd /root/prox
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --dry-run
```

Lis les commandes affichees. Si le script veut modifier un fichier critique comme `/etc/network/interfaces`, verifie les IP avant de continuer.

## 8. Appliquer la configuration du node

Quand le dry-run est correct :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --yes
```

Le script peut gerer :

- les repos APT Proxmox ;
- les paquets systeme ;
- le hostname ;
- la timezone ;
- SSH ;
- le reseau si active ;
- les storages Proxmox ;
- Proxmox Backup Server ;
- les jobs de backup ;
- Terraform si active.

## 9. Creer ou mettre a jour les VM

Si tu veux que le bootstrap lance aussi Terraform :

```bash
cd /root/prox
cp terraform/wireguard-ct/terraform.tfvars.example terraform/wireguard-ct/terraform.tfvars
nano terraform/wireguard-ct/terraform.tfvars
```

Puis dans `config/proxmox-bootstrap.yml` :

```yaml
terraform:
  enabled: true
  dir: /root/prox/terraform/wireguard-ct
  auto_approve: false
```

Sinon, lance Terraform manuellement :

```bash
cd /root/prox/terraform/wireguard-ct
terraform init
terraform plan
terraform apply
```

Garde `terraform.auto_approve: false` au debut pour voir le plan avant application.

## 10. Verification finale

Apres application :

```bash
pveversion
pvesm status
qm list
cat /etc/network/interfaces
```

Verifie aussi dans l'interface Proxmox :

- le node est joignable ;
- les storages sont presents ;
- les VM sont presentes ;
- les jobs de backup existent ;
- les VM importantes demarrent correctement.
