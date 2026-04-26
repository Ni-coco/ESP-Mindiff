# ESP-Mindiff

Monorepo for the Mindiff fitness app: **FastAPI backend** (`Back/`), **Flutter client** (`App/`), and project documentation (`docs/`).

## Infrastructure documentation

- Complete architecture and environment credentials are documented in `docs/architecture-credentials.md`.

## Repository layout

| Path | Description |
|------|-------------|
| `Back/` | FastAPI API, Alembic migrations, Docker compose for local Postgres/Vault |
| `App/` | Flutter application (`mindiff_app`) |
| `docs/` | Architecture, credentials, and product docs |

## Local development

For day-to-day work, run optional services (Postgres), then the API, then the Flutter app. CI and production deployment are described [below](#ci-github-actions--deployment-dokploy).

### Prerequisites

- **Flutter** (stable channel), SDK compatible with `App/pubspec.yaml` (currently `^3.8.1`)
- **Python** 3.10+
- [**uv**](https://github.com/astral-sh/uv) (recommended; matches `.github/workflows/ci-back.yml`)
- **Docker** (optional), for Postgres / Vault / pgAdmin via `Back/docker/docker-compose.yml`

### Optional: PostgreSQL and Vault (Docker)

From `Back/`, ensure `Back/.env` exists (copy from `Back/.env.example` and align `POSTGRES_*` with the compose file), then:

```bash
cd Back
cp .env.example .env   # once, then edit values if needed
docker compose -f docker/docker-compose.yml up -d
```

This starts Postgres (and Vault, pgAdmin) using `../.env` relative to the compose file, i.e. `Back/.env`.

### Backend (FastAPI)

```bash
cd Back
cp .env.example .env   # if you do not already have a .env
uv sync
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: `http://localhost:8000`
- OpenAPI: `http://localhost:8000/docs`
- Health: `http://localhost:8000/health`

More detail (SQLite, manual Alembic, scripts, `ruff`, `pytest`) is in [`Back/README.md`](Back/README.md).

### Flutter app

```bash
cd App
flutter pub get
flutter run              # pick a device or emulator when prompted
# optional: web
flutter run -d chrome
```

The app resolves the API base URL from (highest priority first): `--dart-define=API_BASE_URL=...`, then a loaded `.env` asset, then the default `http://localhost:8000/api` (see `App/lib/config/app_config.dart`). At startup, `App/lib/main.dart` tries `.env` then falls back to the bundled `.env.example`. To point at another backend in **release** builds or CI, prefer `--dart-define=API_BASE_URL=https://your-api.example.com/api`. If you add a custom `App/.env` file for local overrides on device, list it under `flutter: assets:` in `App/pubspec.yaml` so Flutter can bundle it.

Start the backend before exercising login or other network features.

### Typical startup order

1. Postgres (and optional Vault) if you use Docker compose  
2. Backend (`uv run uvicorn …`)  
3. Flutter (`flutter run`)

## CI (GitHub Actions) + Deployment (Dokploy)

This repository is prepared to:
- run CI checks for backend and Flutter app on `dev` and `main`,
- build Android APKs and publish/update rolling GitHub Releases (`dev-latest`, `main-latest`),
- keep deployment responsibility in Dokploy.

### CI/CD workflows

- `.github/workflows/ci-back.yml`
  - FastAPI backend checks (`ruff` + `pytest`) with PostgreSQL service.
- `.github/workflows/ci-app.yml`
  - Flutter app checks (`flutter analyze` + `flutter test`).
- `.github/workflows/build-android-apk.yml`
  - builds `App/build/app/outputs/flutter-apk/app-release.apk`
  - uploads workflow artifact
  - updates release tag `main-latest` with the latest APK.
- `.github/workflows/build-android-apk-dev.yml`
  - same APK build pipeline on branch `dev`
  - updates release tag `dev-latest`.

### Required GitHub secrets/variables

Set these in repository settings:

- Variables:
  - `APP_API_BASE_URL_DEV` (used by `build-android-apk-dev.yml`)
  - `APP_API_BASE_URL_PROD` (used by `build-android-apk.yml`)

### Dokploy service setup

Create two services in Dokploy (Docker image mode):

1. Backend service
   - Image: `ghcr.io/<owner>/<repo>/backend:latest`
   - Container port: `8000`
   - Healthcheck path: `/health`
   - Environment variables (minimum):
     - `POSTGRES_USER`
     - `POSTGRES_PASSWORD`
     - `POSTGRES_DB`
     - `POSTGRES_HOST`
     - `POSTGRES_PORT`
     - `SECRET_KEY`
     - `CORS_ORIGINS` (e.g. `https://app.example.com`)
     - optional Edamam/Vault variables as needed by backend.

2. Web service
   - Image: `ghcr.io/<owner>/<repo>/app-web:latest`
   - Container port: `80`
   - Healthcheck path: `/health`
   - Public domain: `https://app.example.com`

Deployment is managed directly in Dokploy (no GitHub deploy webhook required for CI).

### Database migrations behavior

Backend runs Alembic migrations at startup in `Back/app/main.py` unless `SKIP_ALEMBIC` is set.
In production, keep `SKIP_ALEMBIC` unset so schema upgrades apply automatically.

### APK distribution URL

The APK is always attached to release tag `main-latest`.
Share this stable release page URL:

`https://github.com/<owner>/<repo>/releases/tag/main-latest`

### Rollback

- Backend/web rollback:
  - in Dokploy, pin image tag to a previous digest/tag and redeploy.
- APK rollback:
  - manually edit release `main-latest` and upload a previous APK artifact.