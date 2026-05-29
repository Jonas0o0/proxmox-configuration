# Caddy CT

Ce module cree une CT LXC Alpine par defaut pour lancer Caddy avec Docker Compose.

Terraform gere :

- le telechargement du template LXC ;
- la creation de la CT ;
- l'upload du hook Proxmox ;
- l'upload du `docker-compose.yml` ;
- l'upload du `Caddyfile` ;
- l'installation de Docker dans la CT ;
- le demarrage du container Docker `caddy`.

## Configuration

La configuration applicative est versionnee ici :

- [files/docker-compose.yml](files/docker-compose.yml)
- [files/Caddyfile](files/Caddyfile)

Le hook copie ces fichiers dans la CT :

```text
/etc/docker/containers/caddy/docker-compose.yml
/etc/docker/containers/caddy/Caddyfile
```

Il cree aussi :

```text
/etc/docker/containers/caddy/site/
/etc/docker/containers/caddy/sites/
```

## Verification

Depuis le node Proxmox :

```bash
pct exec 109 -- docker ps --filter name=caddy
pct exec 109 -- docker logs caddy
pct exec 109 -- docker compose -f /etc/docker/containers/caddy/docker-compose.yml ps
```

Relancer Caddy :

```bash
pct exec 109 -- docker compose -f /etc/docker/containers/caddy/docker-compose.yml restart
```

## Ajouter un vhost

Dans la CT :

```bash
pct enter 109
vi /etc/docker/containers/caddy/sites/app.caddy
```

Puis recharge Caddy :

```bash
pct exec 109 -- docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```
