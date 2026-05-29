# GitOps Proxmox

Cette page decrit le workflow GitOps du repo.

Objectif : `main` est la source de verite. A chaque push sur `main`, GitHub Actions remet le node Proxmox et les ressources Terraform dans l'etat decrit par le repo.

Le workflow applique donc deux couches :

1. `scripts/bootstrap-proxmox.sh` pour la configuration du node Proxmox ;
2. Terraform, lance par ce meme script, pour les CT, VM, snippets et ressources Proxmox.

## Principe

```text
push sur main
  -> GitHub Actions
  -> runner self-hosted dans le homelab
  -> upload du repo sur le node Proxmox
  -> bootstrap-proxmox.sh
  -> terraform init / validate / plan / apply depuis le bootstrap
  -> API Proxmox + SSH Proxmox
```

Le workflow est defini ici :

```text
.github/workflows/proxmox-gitops.yml
```

Il tourne sur un runner `self-hosted`, pas sur `ubuntu-latest`. C'est volontaire : le runner doit pouvoir joindre Proxmox en SSH et via l'API locale, sans exposer Proxmox sur Internet.

## Ce que le workflow fait

Sur chaque push vers `main`, le workflow :

1. clone le repo ;
2. installe Terraform ;
3. verifie que les secrets obligatoires existent ;
4. lance `terraform fmt -check -recursive` ;
5. prepare la configuration bootstrap ;
6. prepare les secrets Terraform temporaires ;
7. upload le repo sur le node Proxmox ;
8. lance `scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.yml --yes` sur le node.

Le bootstrap lance ensuite Terraform si `terraform.enabled: true` dans `config/proxmox-bootstrap.yml`.

Le workflow utilise une `concurrency` GitHub Actions pour eviter deux `apply` en meme temps.

## Prerequis

Avant d'activer ce workflow, il faut :

- un runner GitHub Actions self-hosted dans le homelab ;
- un token API Proxmox avec les permissions necessaires ;
- une cle SSH qui permet au runner de se connecter au node Proxmox ;
- `config/proxmox-bootstrap.yml` versionne dans le repo, ou le secret `PROXMOX_BOOTSTRAP_CONFIG_YML` ;
- un backend Terraform distant pour stocker le state ;
- les secrets GitHub Actions configures.

Le backend distant est obligatoire. Sans backend distant, un runner pourrait perdre le fichier `terraform.tfstate`, et Terraform pourrait vouloir recreer ou modifier des ressources deja existantes.

## Source de verite bootstrap

Le fichier suivant est la configuration systeme du node Proxmox :

```text
config/proxmox-bootstrap.yml
```

Il doit contenir ce qui est non sensible :

- hostname ;
- timezone ;
- depots APT ;
- paquets systeme ;
- SSH ;
- reseau ;
- storages ;
- jobs de backup ;
- configuration PBS sans mot de passe ;
- activation de Terraform en fin de bootstrap.

Les secrets ne doivent pas etre mis dans ce fichier. Exemple : token Proxmox, cle SSH, mot de passe PBS ou identifiants de backend Terraform.

Si tu ne veux pas versionner ce fichier, le workflow accepte aussi un secret GitHub `PROXMOX_BOOTSTRAP_CONFIG_YML` qui contient le YAML complet. Pour une vraie philosophie GitOps, la version dans Git est preferable tant qu'elle ne contient pas de secret.

## Terraform

Dans le fichier versionne, la partie Terraform peut ressembler a ceci :

```yaml
terraform:
  enabled: true
  install: true
  version: 1.15.5
  bin_dir: /usr/local/bin
  dir: /root/prox/terraform
  plan_file: tfplan
  auto_approve: true
```

Avec cette configuration, le bootstrap fait :

```bash
terraform init -input=false
terraform validate
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

Le workflow ne relance pas Terraform apres le bootstrap. Le script `bootstrap-proxmox.sh` est le point d'entree unique.

## Reseau

Le bootstrap peut gerer `/etc/network/interfaces` avec :

```yaml
network:
  enabled: true
  reload: true
```

Attention : si `reload: true` change l'IP, le bridge ou la route par defaut, la connexion SSH du workflow peut etre coupee. Le workflow lance le bootstrap en arriere-plan sur le node pour eviter que le processus soit tue avec la session SSH, puis il attend un statut.

Si l'adresse de gestion Proxmox change, mets a jour les secrets `PROXMOX_ENDPOINT` et `PROXMOX_SSH_HOST` avant de pousser le changement. Sinon le bootstrap peut s'appliquer, mais Terraform ne saura plus joindre le node.

## Premier lancement

Avant le premier push qui declenche un `apply`, verifie deux choses :

1. le runner self-hosted peut joindre le node Proxmox en SSH ;
2. le state distant connait deja les ressources Terraform existantes.

Cas simples :

- si aucune CT/VM Terraform n'existe encore, le premier `apply` peut les creer ;
- si tu as deja applique Terraform en local, migre le state local vers le backend distant avec `terraform init -migrate-state` ;
- si des CT/VM existent dans Proxmox mais pas dans le state Terraform, importe-les dans le state avant d'activer l'apply automatique.

Ne lance pas le workflow GitOps avec un state vide si les ressources existent deja dans Proxmox.

## Secrets GitHub Actions

Dans GitHub :

```text
Settings -> Secrets and variables -> Actions -> New repository secret
```

Secrets obligatoires :

| Secret | Exemple | Role |
| --- | --- | --- |
| `PROXMOX_ENDPOINT` | `https://pve.home.arpa:8006/api2/json` | Endpoint API Proxmox. |
| `PROXMOX_API_TOKEN` | `root@pam!terraform=xxxxxxxx` | Token API Proxmox utilise par Terraform. |
| `PROXMOX_SSH_PRIVATE_KEY` | contenu complet d'une cle privee SSH | Cle SSH pour uploader le repo, lancer le bootstrap, puis permettre a Terraform d'uploader les snippets et hooks. |
| `TF_BACKEND_HCL` | bloc `terraform { backend ... }` | Backend distant pour le state Terraform. |

Secrets optionnels :

| Secret | Exemple | Role |
| --- | --- | --- |
| `PROXMOX_SSH_HOST` | `pve.home.arpa` | Host SSH Proxmox. Si absent, le workflow le deduit de `PROXMOX_ENDPOINT`. |
| `PROXMOX_SSH_USERNAME` | `root` | Utilisateur SSH Proxmox. Si absent, Terraform garde son defaut. |
| `PROXMOX_BOOTSTRAP_CONFIG_YML` | contenu YAML complet | Alternative si `config/proxmox-bootstrap.yml` n'est pas versionne. |
| `CT_SSH_PUBLIC_KEYS` | `["ssh-ed25519 AAAA... jonas"]` | Cles SSH injectees dans les CT. Format HCL/JSON sur une ligne. |
| `TF_STATE_ACCESS_KEY_ID` | `minio-access-key` | Access key pour un backend S3 compatible. |
| `TF_STATE_SECRET_ACCESS_KEY` | `minio-secret-key` | Secret key pour un backend S3 compatible. |
| `TF_STATE_SESSION_TOKEN` | `...` | Token temporaire si ton backend S3 en demande un. |

Variable optionnelle du repo GitHub Actions :

| Variable | Exemple | Role |
| --- | --- | --- |
| `PROXMOX_REMOTE_REPO_DIR` | `/root/prox` | Dossier ou le workflow copie le repo sur le node Proxmox. |

## Exemple de backend S3 compatible

Exemple de valeur pour le secret `TF_BACKEND_HCL` avec MinIO, Ceph, Garage, Backblaze B2 ou un autre backend compatible S3 :

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "proxmox/homelab.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "https://s3.home.arpa"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}
```

Les identifiants du backend S3 ne doivent pas etre mis dans `TF_BACKEND_HCL`. Mets-les plutot dans :

```text
TF_STATE_ACCESS_KEY_ID
TF_STATE_SECRET_ACCESS_KEY
```

Le workflow les expose a Terraform sous forme de variables d'environnement AWS standard.

## Runner self-hosted

Le runner peut tourner sur :

- une machine Linux du reseau local ;
- une VM dediee ;
- une CT dediee dans Proxmox.

Il doit pouvoir joindre :

- l'API Proxmox sur `:8006` ;
- SSH sur le node Proxmox ;
- GitHub pour recevoir les jobs ;
- le backend distant du state Terraform.

Pour rester propre, evite de mettre le runner dans une CT qui heberge deja un service applicatif. Une CT dediee `github-runner` sera plus simple a maintenir et a isoler.

Pour une machine Proxmox completement fraiche, il reste une limite physique : il faut au minimum que le node soit joignable en SSH depuis le runner. L'installation initiale Proxmox depuis l'ISO doit donc fournir une IP de gestion temporaire ou definitive.

## Workflow de travail

Pour changer le serveur :

1. modifie `config/proxmox-bootstrap.yml` pour le node, ou les fichiers Terraform pour les CT/VM ;
2. teste localement avec `scripts/bootstrap-proxmox.sh --dry-run` ou `terraform plan` si possible ;
3. commit ;
4. push sur `main` ;
5. GitHub Actions lance le bootstrap, qui applique automatiquement le node puis Terraform.

Si un apply echoue, corrige le repo puis repush. Le repo reste la source de verite.

## Limites

Ce workflow ne remplace pas l'installation Proxmox depuis l'ISO.

Ordre normal :

1. installer Proxmox ;
2. rendre le node joignable en SSH depuis le runner ;
3. configurer le runner, les secrets et le backend Terraform ;
4. laisser GitHub Actions lancer le bootstrap a chaque push.
