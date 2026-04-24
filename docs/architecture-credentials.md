# Mindiff - Architecture & Credentials

Derniere mise a jour : 24 avril 2026

## Serveur (VM Proxmox)

| Parametre | Valeur |
| --- | --- |
| IP publique | `82.66.211.8` |
| OS | Ubuntu 24 |
| Disque | 111G total / 17G utilise / 89G libre |
| SSH | `<ssh-hostname>` |

## Infrastructure Docker (Swarm)

| Service | Image | Role |
| --- | --- | --- |
| Traefik | `traefik:v3.6.7` | Reverse proxy - ports 80 / 443 |
| Dokploy | `dokploy/dokploy:v0.29.1` | Deployment platform |
| dokploy-postgres | `postgres:16` | DB interne Dokploy |
| dokploy-redis | `redis:7` | Cache interne Dokploy |

## Cloudflare Tunnel

| Parametre | Valeur |
| --- | --- |
| Tunnel ID | `<cloudflare-tunnel-id>` |
| Config | `/etc/cloudflared/config.yml` |
| Credentials | `/etc/cloudflared/<tunnel-id>.json` |
| Protocol | `http2` |
| Service systemd | `cloudflared.service` |

## Routes Cloudflare

| Hostname | Service | Notes |
| --- | --- | --- |
| `<dokploy-domain>` | `localhost:3000` | Dokploy UI |
| `<api-dev-domain>` | `localhost:80` | API dev |
| `<adminer-dev-domain>` | `localhost:80` | Adminer dev |
| `<app-dev-domain>` | `localhost:80` | App dev (Flutter) |
| `<api-prod-domain>` | `localhost:80` | API prod |
| `<adminer-prod-domain>` | `localhost:80` | Adminer prod |
| `<app-prod-domain>` | `localhost:80` | App prod (Flutter) |
| `<landing-domain>` | `localhost:80` | Site vitrine |
| `<ssh-domain>` | `localhost:22` | SSH |

## Dokploy

| Parametre | Valeur |
| --- | --- |
| URL | `https://<dokploy-domain>` |
| Acces local | `http://<private-lan-ip>:3000` |
| Version | `v0.29.1` |
| Server Domain | `<dokploy-domain>` |

## Environnement DEV

### Backend (FastAPI)

| Parametre | Valeur |
| --- | --- |
| URL | `https://<api-dev-domain>` |
| Docs Swagger | `https://<api-dev-domain>/docs` |
| Health check | `https://<api-dev-domain>/health` |
| Framework | FastAPI - Python 3.11 |
| Port interne | `8000` |
| Branche | `dev` |
| Dockerfile | `Back/Dockerfile` |
| Docker context | `Back` |

#### Variables d'environnement (dev)

```env
POSTGRES_USER=mindiff_user
POSTGRES_PASSWORD=mindiff_password
POSTGRES_DB=<db-name>
POSTGRES_HOST=<db-host-dev>
POSTGRES_PORT=5432
DATABASE_URL=postgresql://mindiff_user:mindiff_password@<db-host-dev>:5432/<db-name>

SECRET_KEY=<secret-key>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

DEBUG=True
CORS_ORIGINS=https://<app-dev-domain>
```

### Base de donnees dev

| Parametre | Valeur |
| --- | --- |
| Host interne | `<db-host-dev>` |
| Port | `5432` |
| Database | `<db-name>` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Image Docker | `postgres:16-alpine` |
| Connection URL | `postgresql://mindiff_user:mindiff_password@<db-host-dev>:5432/<db-name>` |

### Adminer dev

| Parametre | Valeur |
| --- | --- |
| URL | `https://<adminer-dev-domain>` |
| System | PostgreSQL |
| Server | `<db-host-dev>` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Database | `<db-name>` |

## Environnement PROD

### Backend (FastAPI)

| Parametre | Valeur |
| --- | --- |
| URL | `https://<api-prod-domain>` |
| Docs Swagger | `https://<api-prod-domain>/docs` |
| Health check | `https://<api-prod-domain>/health` |
| Framework | FastAPI - Python 3.11 |
| Port interne | `8000` |
| Branche | `main` |
| Dockerfile | `Back/Dockerfile` |
| Docker context | `Back` |

#### Variables d'environnement (prod)

```env
POSTGRES_USER=mindiff_user
POSTGRES_PASSWORD=mindiff_password
POSTGRES_DB=<db-name>
POSTGRES_HOST=<db-host-prod>
POSTGRES_PORT=5432
DATABASE_URL=postgresql://mindiff_user:mindiff_password@<db-host-prod>:5432/<db-name>

SECRET_KEY=<secret-key>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

DEBUG=False
CORS_ORIGINS=https://<app-prod-domain>
```

### Base de donnees prod

| Parametre | Valeur |
| --- | --- |
| Host interne | `<db-host-prod>` |
| Port | `5432` |
| Database | `<db-name>` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Image Docker | `postgres:16-alpine` |
| Connection URL | `postgresql://mindiff_user:mindiff_password@<db-host-prod>:5432/<db-name>` |

### Adminer prod

| Parametre | Valeur |
| --- | --- |
| URL | `https://<adminer-prod-domain>` |
| System | PostgreSQL |
| Server | `<db-host-prod>` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Database | `<db-name>` |

## Projet - Structure

```text
ESP-Mindiff/
|-- App/                  # Flutter (Android / iOS / Web)
|   |-- Dockerfile.web
|   `-- lib/main.dart
|-- Back/                 # FastAPI Python 3.11
|   |-- Dockerfile
|   |-- app/main.py
|   |-- alembic/          # Migrations DB
|   `-- scripts/
|-- IOT/                  # ESP32 / PlatformIO
|   `-- Mindiff_Balance/
`-- web/                  # Site vitrine
```

## Migrations Alembic

| Version | Description |
| --- | --- |
| 001 | Add users table |
| 002 | Add exercise tables |
| 003 | Add program tables |
| 004 | Add profile columns to users |
| 005 | Add actual_weight to user_metrics |
| 006 | Create weight_log table |
| 007 | Create meal_log table |
| 008 | Rebuild exercise tables + workout tables |
| 009 | Ensure user_metrics.actual_weight on legacy DBs |
| 010 | Add analyzer_key to exercise |
