# GitHub Actions Workflows

This directory contains all the GitHub Actions CI/CD workflows for the Mindiff Backend API.

## Available Workflows

### 1. **CI Pipeline** (`ci.yml`)
Main continuous integration workflow that runs on every push and pull request.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
- **Lint & Format Check**: Validates code style using Ruff
  - Runs `ruff check` for linting
  - Runs `ruff format --check` for formatting
  
- **Test Suite**: Runs the complete test suite
  - Tests against Python 3.10, 3.11, and 3.12
  - Spins up a PostgreSQL 15 service for integration tests
  - Generates coverage reports
  - Uploads coverage to Codecov
  
- **Security Checks**: Scans for security vulnerabilities
  - Uses Bandit to identify security issues
  - Generates security report artifacts
  
- **Type Checking**: Validates Python type hints
  - Runs mypy for static type checking

### 2. **Docker Build & Push** (`docker.yml`)
Builds and publishes Docker images to GitHub Container Registry.

**Triggers:**
- Push to `main` or `develop` branches
- Push of version tags (`v*`)
- Manual workflow dispatch

**Features:**
- Multi-platform Docker builds using Docker Buildx
- Automatic tagging based on git ref and semver tags
- GitHub Actions cache for faster builds
- Automatically pushes on main/develop branches only

**Image Tags:**
- Branch-based: `ghcr.io/your-org/backend:main`, `ghcr.io/your-org/backend:develop`
- Version-based: `ghcr.io/your-org/backend:v1.0.0`
- SHA-based: `ghcr.io/your-org/backend:sha-abc123def`

### 3. **Code Quality & Coverage** (`quality.yml`)
Detailed code quality analysis and coverage reporting.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Features:**
- Runs test suite with coverage analysis
- Uploads to Codecov with detailed metrics
- Comments on PRs with coverage reports
- Generates HTML coverage report artifacts
- Publishes test results

**Coverage Thresholds:**
- Green (good): ≥ 80% coverage
- Orange (acceptable): 60-80% coverage
- Red (needs improvement): < 60% coverage

### 4. **Dependency Check** (`dependencies.yml`)
Scans dependencies for known vulnerabilities and outdated packages.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Weekly schedule (Sunday at 00:00 UTC)

**Tools:**
- **Safety**: Checks for known security vulnerabilities in Python packages
- **Pip-audit**: Audits dependencies against known vulnerability databases

**Artifacts:**
- `safety-report.json`: Detailed safety check results
- `pip-audit-report.txt`: Pip-audit vulnerability report

## Environment Variables

The workflows use the following environment variables:

### CI Workflows
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port
- `SKIP_ALEMBIC`: Set to `"false"` to run migrations during tests

### Docker Workflows
- `REGISTRY`: Container registry (default: `ghcr.io`)
- `IMAGE_NAME`: Base image name (default: derived from repository)

## Secrets

No additional secrets are required by default, as GitHub provides `GITHUB_TOKEN` automatically.

**Optional Secrets** (if you want to push to other registries):
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub authentication token
- `REGISTRY_USERNAME`: Custom registry username
- `REGISTRY_PASSWORD`: Custom registry password

## Status Badges

You can add these badges to your README.md to display workflow status:

```markdown
[![CI Pipeline](https://github.com/your-org/mindiff-back/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/mindiff-back/actions/workflows/ci.yml)
[![Docker Build](https://github.com/your-org/mindiff-back/actions/workflows/docker.yml/badge.svg)](https://github.com/your-org/mindiff-back/actions/workflows/docker.yml)
[![Code Quality](https://github.com/your-org/mindiff-back/actions/workflows/quality.yml/badge.svg)](https://github.com/your-org/mindiff-back/actions/workflows/quality.yml)
[![Dependencies](https://github.com/your-org/mindiff-back/actions/workflows/dependencies.yml/badge.svg)](https://github.com/your-org/mindiff-back/actions/workflows/dependencies.yml)
```

## Codecov Integration

All workflows upload coverage reports to Codecov. To enable full Codecov features:

1. Go to [codecov.io](https://codecov.io)
2. Connect your GitHub repository
3. (Optional) Add `CODECOV_TOKEN` as a repository secret if your repo is private

## Running Workflows Locally

To test workflows locally before pushing to GitHub, use [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # macOS
# or see https://github.com/nektos/act for other platforms

# Run specific workflow
act -j lint

# Run all workflows
act

# Run with specific event
act pull_request
```

## Troubleshooting

### Tests failing in CI but passing locally

**Common causes:**
- Database connection issues: Ensure `POSTGRES_*` variables are correctly configured
- Python version differences: The CI tests multiple Python versions
- Missing dependencies: Run `uv sync` to ensure all dependencies are installed
- Alembic migrations: Set `SKIP_ALEMBIC: "false"` if your tests require migrations

### Docker build failures

**Common causes:**
- Missing Dockerfile: Ensure `mindiff-back/Dockerfile` exists
- Build context issues: Verify the build context path is correct
- Layer caching: Clear cache with `--no-cache` flag if needed

### Coverage not uploading to Codecov

**Troubleshooting:**
- Check if repository is public or private
- Verify Codecov service has access to your repository
- For private repos, add `CODECOV_TOKEN` secret
- Check Codecov workflow logs for detailed errors

## Best Practices

1. **Always run tests locally** before pushing:
   ```bash
   uv run pytest --cov=app
   ```

2. **Format and lint code** before committing:
   ```bash
   uv run ruff format app tests
   uv run ruff check app tests
   ```

3. **Check security** with Bandit:
   ```bash
   uv run bandit -r app
   ```

4. **Test multiple Python versions** locally using `pyenv` or similar

5. **Review workflow logs** in GitHub Actions tab to debug failures

## Adding New Workflows

To add new workflows:

1. Create a new `.yml` file in this directory
2. Define triggers (`on:`), jobs, and steps
3. Test with `act` locally
4. Push and monitor execution in GitHub Actions tab

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Python on GitHub Actions](https://docs.github.com/en/actions/automating-builds-and-testing/building-and-testing-python)
- [Docker on GitHub Actions](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
- [act - Run workflows locally](https://github.com/nektos/act)
- [Codecov - Coverage Analysis](https://codecov.io)