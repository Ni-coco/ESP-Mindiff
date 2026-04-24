# ESP-Mindiff

## Deployment (Dokploy + Flutter Web/APK)

This repository is prepared to:
- build and push backend and Flutter web Docker images on each push to `main`,
- trigger Dokploy redeploys via webhooks,
- build an Android APK and publish/update a rolling GitHub Release (`main-latest`).

### CI/CD workflows

- `.github/workflows/deploy-back-web.yml`
  - builds and pushes:
    - `ghcr.io/<owner>/<repo>/backend:latest`
    - `ghcr.io/<owner>/<repo>/app-web:latest`
  - optionally calls Dokploy redeploy webhooks.
- `.github/workflows/build-android-apk.yml`
  - builds `App/build/app/outputs/flutter-apk/app-release.apk`
  - uploads workflow artifact
  - updates release tag `main-latest` with the latest APK.

### Required GitHub secrets/variables

Set these in repository settings:

- Secrets:
  - `DOKPLOY_WEBHOOK_BACKEND` (optional; backend redeploy webhook)
  - `DOKPLOY_WEBHOOK_WEB` (optional; web redeploy webhook)
- Variables:
  - `APP_API_BASE_URL` (recommended; e.g. `https://api.example.com/api`)

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

After service creation, copy each Dokploy deploy webhook URL into:
- `DOKPLOY_WEBHOOK_BACKEND`
- `DOKPLOY_WEBHOOK_WEB`

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