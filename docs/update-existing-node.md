# Mettre a jour un node Proxmox existant

Cette procedure sert quand le repo a change et que tu veux appliquer les changements sur une machine Proxmox deja installee.

Exemples :

- ajout d'une nouvelle VM Terraform ;
- modification CPU/RAM/disque d'une VM ;
- ajout d'un storage ;
- ajout d'un job de backup ;
- modification du script bootstrap.

## 1. Recuperer les changements du repo

Sur le node Proxmox :

```bash
ssh root@192.168.1.10
cd /root/prox
git status
git pull
```

Si `git status` montre des fichiers modifies localement, lis-les avant de faire `git pull`.

## 2. Verifier la configuration locale

Le fichier reel de bootstrap n'est pas versionne :

```bash
config/proxmox-bootstrap.yml
```

Verifie qu'il existe toujours :

```bash
test -f config/proxmox-bootstrap.yml
```

Si le fichier exemple a change, compare :

```bash
diff -u config/proxmox-bootstrap.yml.example config/proxmox-bootstrap.yml
```

Adapte `config/proxmox-bootstrap.yml` si une nouvelle variable utile a ete ajoutee.

## 3. Appliquer les changements du node

Si les changements concernent le node Proxmox lui-meme, lance d'abord un dry-run :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --dry-run
```

Puis applique :

```bash
sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --yes
```

Tu n'es pas oblige de relancer le bootstrap pour chaque nouvelle VM. Si seuls les fichiers Terraform ont change, passe directement a la partie Terraform.

## 4. Appliquer les changements Terraform

Va dans le dossier Terraform concerne :

```bash
cd /root/prox/terraform/wireguard-ct
```

Initialise ou mets a jour les providers/modules :

```bash
terraform init
```

Verifie la syntaxe :

```bash
terraform validate
```

Regarde le plan :

```bash
terraform plan
```

Applique seulement si le plan correspond a ce que tu veux :

```bash
terraform apply
```

Pour une nouvelle VM, le plan doit normalement afficher une creation, pas une destruction d'une VM existante.

## 5. Cas typique : ajout d'une nouvelle VM

Workflow recommande :

1. Ajouter les fichiers Terraform de la VM dans le repo.
2. Commit et push depuis ta machine de dev.
3. Sur Proxmox : `git pull`.
4. Sur Proxmox : `terraform init`.
5. Sur Proxmox : `terraform validate`.
6. Sur Proxmox : `terraform plan`.
7. Lire le plan.
8. Appliquer avec `terraform apply`.
9. Verifier la VM dans Proxmox.

Commandes :

```bash
cd /root/prox
git pull

cd /root/prox/terraform/wireguard-ct
terraform init
terraform validate
terraform plan
terraform apply
```

## 6. Points de controle avant apply

Avant `terraform apply`, verifie :

- le `vm_id` n'est pas deja utilise ;
- le `node_name` correspond au node Proxmox ;
- le datastore existe ;
- le bridge reseau existe ;
- l'IP de la VM ne collisionne pas avec une autre machine ;
- le plan Terraform ne detruit pas une ressource que tu veux garder.

Commandes utiles :

```bash
qm list
pvesm status
ip address
cat /etc/network/interfaces
```

## 7. Apres application

Verifie l'etat :

```bash
qm list
terraform output
terraform state list
```

Puis teste l'acces a la VM :

```bash
ssh utilisateur@ip-de-la-vm
```

Si la VM utilise cloud-init, attends quelques minutes avant de conclure que SSH ne marche pas.

## 8. Rollback simple

Si le changement vient d'etre applique et pose probleme :

1. Regarde ce que Terraform gere :

```bash
terraform state list
```

2. Corrige le fichier Terraform.
3. Relance :

```bash
terraform plan
terraform apply
```

Ne supprime pas manuellement les ressources dans l'interface Proxmox si elles sont gerees par Terraform, sauf si tu sais ensuite reparer le state Terraform.

## 9. Regle importante sur le state Terraform

Le fichier `terraform.tfstate` est la memoire de Terraform.

Il ne doit pas etre commit dans Git, mais il doit etre conserve sur la machine qui applique Terraform, ou mieux dans un backend distant plus tard.

Si le state est perdu, Terraform peut croire que les VM n'existent plus et vouloir les recreer.
