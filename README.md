# ESP-Mindiff

## Infrastructure documentation

- Complete architecture and environment credentials are documented in `docs/architecture-credentials.md`.

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