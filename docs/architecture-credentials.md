# Mindiff — Architecture & Credentials

> Dernière mise à jour : 24 avril 2026

---

## Serveur (VM Proxmox)

| Paramètre | Valeur |
|---|---|
| IP locale | `192.168.1.21` |
| IP publique | `82.66.211.8` |
| OS | Ubuntu 24 |
| Disque | 111G total / 17G utilisé / 89G libre |
| SSH | `mindssh.nini.network` |

---

## Infrastructure Docker (Swarm)

| Service | Image | Rôle |
|---|---|---|
| Traefik | `traefik:v3.6.7` | Reverse proxy · ports 80 / 443 |
| Dokploy | `dokploy/dokploy:v0.29.1` | Deployment platform |
| dokploy-postgres | `postgres:16` | DB interne Dokploy |
| dokploy-redis | `redis:7` | Cache interne Dokploy |

---

## Cloudflare Tunnel

| Paramètre | Valeur |
|---|---|
| Tunnel ID | `f944bda8-f625-4855-a08e-8b011cd76c89` |
| Config | `/etc/cloudflared/config.yml` |
| Credentials | `/etc/cloudflared/f944bda8-f625-4855-a08e-8b011cd76c89.json` |
| Protocol | `http2` |
| Service systemd | `cloudflared.service` |

### Routes Cloudflare

| Hostname | Service | Notes |
|---|---|---|
| `dokdiff.nini.network` | `localhost:3000` | Dokploy UI |
| `apidev.nini.network` | `localhost:80` | API dev |
| `adminerdev.nini.network` | `localhost:80` | Adminer dev |
| `mindev.nini.network` | `localhost:80` | App dev (Flutter) |
| `api.nini.network` | `localhost:80` | API prod |
| `adminer.nini.network` | `localhost:80` | Adminer prod |
| `mindiff.nini.network` | `localhost:80` | App prod (Flutter) |
| `mind.nini.network` | `localhost:80` | Site vitrine |
| `mindssh.nini.network` | `localhost:22` | SSH |

---

## Dokploy

| Paramètre | Valeur |
|---|---|
| URL | `https://dokdiff.nini.network` |
| Accès local | `http://192.168.1.21:3000` |
| Version | `v0.29.1` |
| Server Domain | `dokdiff.nini.network` |

---

## Environnement DEV

### Backend (FastAPI)

| Paramètre | Valeur |
|---|---|
| URL | `https://apidev.nini.network` |
| Docs Swagger | `https://apidev.nini.network/docs` |
| Health check | `https://apidev.nini.network/health` |
| Framework | FastAPI · Python 3.11 |
| Port interne | `8000` |
| Branche | `dev` |
| Dockerfile | `Back/Dockerfile` |
| Docker context | `Back` |

### Base de données dev

| Paramètre | Valeur |
|---|---|
| Host interne | `mindiff-database-dev-j9ckf3` |
| Port | `5432` |
| Database | `mindiff_db` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Image Docker | `postgres:16-alpine` |
| Connection URL | `postgresql://mindiff_user:mindiff_password@mindiff-database-dev-j9ckf3:5432/mindiff_db` |

### Adminer dev

| Paramètre | Valeur |
|---|---|
| URL | `https://adminerdev.nini.network` |
| System | PostgreSQL |
| Server | `mindiff-database-dev-j9ckf3` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Database | `mindiff_db` |

### App Flutter web (dev)

| Paramètre | Valeur |
|---|---|
| URL | `https://mindev.nini.network` |
| Branche | `dev` |
| Dockerfile | `App/Dockerfile.web` |
| Docker context | `App` |
| Build arg | `API_BASE_URL=https://apidev.nini.network/api` |
| Port interne | `80` |

---

## Environnement PROD

### Backend (FastAPI)

| Paramètre | Valeur |
|---|---|
| URL | `https://api.nini.network` |
| Docs Swagger | `https://api.nini.network/docs` |
| Health check | `https://api.nini.network/health` |
| Framework | FastAPI · Python 3.11 |
| Port interne | `8000` |
| Branche | `main` |
| Dockerfile | `Back/Dockerfile` |
| Docker context | `Back` |

### Base de données prod

| Paramètre | Valeur |
|---|---|
| Host interne | `mindiff-database-zsdxtt` |
| Port | `5432` |
| Database | `mindiff_db` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Image Docker | `postgres:16-alpine` |
| Connection URL | `postgresql://mindiff_user:mindiff_password@mindiff-database-zsdxtt:5432/mindiff_db` |

### Adminer prod

| Paramètre | Valeur |
|---|---|
| URL | `https://adminer.nini.network` |
| System | PostgreSQL |
| Server | `mindiff-database-zsdxtt` |
| User | `mindiff_user` |
| Password | `mindiff_password` |
| Database | `mindiff_db` |

### App Flutter web (prod)

| Paramètre | Valeur |
|---|---|
| URL | `https://mindiff.nini.network` |
| Branche | `main` |
| Dockerfile | `App/Dockerfile.web` |
| Docker context | `App` |
| Build arg | `API_BASE_URL=https://api.nini.network/api` |
| Port interne | `80` |

---

## Site Vitrine

| Paramètre | Valeur |
|---|---|
| URL | `https://mind.nini.network` |
| Framework | React 19 · Vite · TypeScript |
| Branche | `website` |
| Dockerfile | `dockerfile` (racine) |
| Docker context | `.` |
| Port interne | `80` |
| Variables d'env | Aucune |

---

## Projet — Structure

```
ESP-Mindiff/
├── App/                  # Flutter (Android / iOS / Web)
│   ├── Dockerfile.web
│   └── lib/main.dart
├── Back/                 # FastAPI Python 3.11
│   ├── Dockerfile
│   ├── app/main.py
│   ├── alembic/          # Migrations DB
│   └── scripts/
├── IOT/                  # ESP32 / PlatformIO
│   └── Mindiff_Balance/
└── web/                  # Site vitrine (React + Vite)
    ├── src/main.tsx
    ├── package.json
    └── vite.config.ts
```

---

## Migrations Alembic

| Version | Description |
|---|---|
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