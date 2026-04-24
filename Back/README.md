# Mindiff Backend API

## 📋 Overview

Mindiff Backend is a comprehensive fitness and nutrition management API built with **FastAPI**. It provides features for exercise management, workout tracking, meal planning, and user authentication.

## ✨ Key Features

- 🔐 **Authentication & Authorization**: JWT-based user authentication with role-based access control
- 💪 **Exercise Management**: Comprehensive exercise database with filtering by body part, equipment, and target muscle
- 🏋️ **Workout Tracking**: Create, manage, and track workout programs and sessions
- 🍽️ **Meal Planning**: Integration with Edamam API for meal suggestions and nutrition analysis
- ⚖️ **Weight Logging**: Track weight progress over time
- 📊 **Dashboard**: User analytics and performance metrics
- 🗄️ **Database Migrations**: Alembic-based schema versioning
- 🔒 **Vault Integration**: Optional HashiCorp Vault support for secrets management

## 🚀 Quick Start

### Prerequisites

- Python 3.10+
- PostgreSQL (recommended) or SQLite for development
- `uv` package manager (recommended) or `pip`

### 1. Clone and Setup

```bash
# Install dependencies with uv
uv sync

# Or with pip
pip install -e .
```

### 2. Configure Environment

Create a `.env` file at the project root:

```bash
cp .env.example .env
```

Configure your database and application settings:

```env
# Database Configuration
POSTGRES_USER=mindiff_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=mindiff
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
# Optional (if set, this takes precedence)
DATABASE_URL=postgresql://mindiff_user:your_password@localhost:5432/mindiff

# JWT Configuration
SECRET_KEY=your-very-long-and-secure-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Edamam Nutrition API (optional)
EDAMAM_APP_ID=your_edamam_app_id
EDAMAM_APP_KEY=your_edamam_app_key
EDAMAM_NUTRITION_URL=https://api.edamam.com/api/nutrition-details

# Edamam Meal Planner API (optional)
EDAMAM_MEAL_APP_ID=your_meal_app_id
EDAMAM_MEAL_APP_KEY=your_meal_app_key
EDAMAM_RECIPE_URL=https://api.edamam.com/api/recipes/v2

# Application Settings
DEBUG=False
CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# Vault Integration (optional)
VAULT_ADDR=https://vault.example.com
VAULT_TOKEN=your_vault_token
```

**⚠️ Generate a secure SECRET_KEY:**

```bash
openssl rand -hex 32
```

### 3. Database Setup

#### Option A: PostgreSQL (Production)

```bash
# Create database and user
sudo -u postgres psql
CREATE DATABASE mindiff;
CREATE USER mindiff_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE mindiff TO mindiff_user;
GRANT USAGE ON SCHEMA public TO mindiff_user;
GRANT CREATE ON SCHEMA public TO mindiff_user;
\q
```

Update `.env` (either explicit host/port or a full URL):
```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=mindiff
POSTGRES_USER=mindiff_user
POSTGRES_PASSWORD=your_password

# Optional override
DATABASE_URL=postgresql://mindiff_user:your_password@localhost:5432/mindiff
```

#### Option B: SQLite (Development)

SQLite is the default. The database will be created automatically at startup.

### 4. Run Migrations

Migrations run automatically on application startup. To manually manage migrations:

```bash
# Create a new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1
```

### 5. Start the Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- **API**: http://localhost:8000
- **Interactive Docs (Swagger UI)**: http://localhost:8000/docs
- **Alternative Docs (ReDoc)**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## 🏗️ Project Structure

```
mindiff-back/
├── app/
│   ├── api/                    # API route handlers
│   │   ├── auth.py             # Authentication endpoints (register, login)
│   │   ├── user.py             # User management endpoints
│   │   ├── exercise.py         # Exercise database endpoints
│   │   ├── workout.py          # Workout tracking endpoints
│   │   ├── program.py          # Workout program management
│   │   ├── meals.py            # Meal logging endpoints
│   │   ├── weight_log.py       # Weight tracking endpoints
│   │   └── dashboard.py        # User dashboard/analytics
│   │
│   ├── core/
│   │   ├── config.py           # Settings and environment configuration
│   │   ├── security.py         # JWT and password hashing utilities
│   │   └── dependencies.py     # FastAPI dependency injection
│   │
│   ├── db/
│   │   └── database.py         # SQLAlchemy configuration and session
│   │
│   ├── models/                 # SQLAlchemy ORM models
│   │   ├── user.py             # User model
│   │   ├── exercise.py         # Exercise and related models
│   │   ├── workout.py          # Workout and session models
│   │   └── program.py          # Program models
│   │
│   ├── schemas/                # Pydantic request/response schemas
│   │   └── *.py                # Request/response validators
│   │
│   ├── services/               # Business logic layer
│   │   └── *.py                # Service classes for each domain
│   │
│   └── main.py                 # Application entry point
│
├── alembic/                    # Database migrations
│   ├── versions/               # Migration files
│   └── env.py
│
├── scripts/                    # Utility scripts
│   ├── import_exercices.py     # Import exercise data
│   ├── seed_db.py              # Populate database with sample data
│   ├── seed_exercises.py       # Seed exercises specifically
│   ├── seed_vault.py           # Initialize Vault secrets
│   └── download_gifs.py        # Download exercise GIFs
│
├── tests/                      # Test suite
│   ├── api/                    # API endpoint tests
│   ├── core/                   # Core functionality tests
│   ├── services/               # Service layer tests
│   ├── conftest.py             # Pytest configuration
│   └── test_main.py            # Main application tests
│
├── docker/
│   └── docker-compose.yml      # Docker setup for local development
│
├── static/                     # Static files (if needed)
│
├── pyproject.toml              # Project metadata and dependencies
├── alembic.ini                 # Alembic configuration
├── pytest.ini                  # Pytest configuration
├── conftest.py                 # Shared pytest fixtures
└── README.md                   # This file
```

## 🔌 API Endpoints

### Authentication
```
POST   /api/auth/register         # Register new user
POST   /api/auth/login            # Login with email/password
POST   /api/auth/token            # OAuth2 token endpoint
GET    /api/auth/me               # Get current user info
```

### Users
```
GET    /api/users                 # List all users
POST   /api/users                 # Create new user
GET    /api/users/{user_id}       # Get user by ID
PUT    /api/users/{user_id}       # Update user
DELETE /api/users/{user_id}       # Delete user
```

### Exercises
```
GET    /api/exercises             # List exercises (with filters)
GET    /api/exercises/count       # Count exercises matching filters
GET    /api/exercises/search      # Search exercises by query
GET    /api/exercises/{id}        # Get exercise details
```

**Query Parameters:**
- `body_part`: Filter by body part (e.g., "chest", "back")
- `equipment`: Filter by equipment (e.g., "barbell", "dumbbell")
- `target`: Filter by target muscle
- `secondary_muscle`: Filter by secondary muscle
- `skip`: Pagination offset (default: 0)
- `limit`: Results per page (default: 100, max: 500)

### Workouts
```
GET    /api/workouts             # List user workouts
POST   /api/workouts             # Create new workout
GET    /api/workouts/{id}        # Get workout details
PUT    /api/workouts/{id}        # Update workout
DELETE /api/workouts/{id}        # Delete workout
```

### Programs
```
GET    /api/programs             # List programs
POST   /api/programs             # Create new program
GET    /api/programs/{id}        # Get program details
PUT    /api/programs/{id}        # Update program
DELETE /api/programs/{id}        # Delete program
```

### Meals
```
POST   /api/users/{user_id}/meals           # Add meal
GET    /api/users/{user_id}/meals           # Get meals (by date)
DELETE /api/users/{user_id}/meals/{meal_id} # Delete meal
```

### Weight Tracking
```
POST   /api/users/{user_id}/weight          # Log weight
GET    /api/users/{user_id}/weight          # Get weight history
DELETE /api/users/{user_id}/weight/{id}     # Delete weight entry
```

### Dashboard
```
GET    /api/dashboard/meals      # Get meal suggestions
GET    /api/dashboard/stats      # Get user statistics
```

### Health
```
GET    /health                   # Health check endpoint
```

## 🧪 Testing

Run the test suite with pytest:

```bash
# Run all tests
pytest

# Run with coverage report
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/api/test_auth.py

# Run tests matching a pattern
pytest -k "test_login"

# Run with verbose output
pytest -v

# Run only fast tests (exclude slow tests)
pytest -m "not slow"
```

**Test Configuration** (`pytest.ini`):
- Tests are located in the `tests/` directory
- Test files follow the pattern `test_*.py`
- Test classes follow the pattern `Test*`
- Test functions follow the pattern `test_*`

**Fixtures** are defined in `conftest.py` and shared across the test suite.

## 🔐 Security

### Password Management
- Passwords are hashed using **bcrypt** with automatic salt generation
- Minimum 8 characters required
- Never transmitted in plain text

### JWT Tokens
- Signed with **HS256** algorithm
- Configurable expiration (default: 30 minutes)
- Contains user ID and email
- Should be sent in `Authorization: Bearer <token>` header

### CORS
- Controlled via `CORS_ORIGINS` (comma-separated origins)
- Example: `CORS_ORIGINS=https://app.example.com,https://admin.example.com`

### Validation
- Email validation via `email-validator`
- Username length: 3-50 characters
- Input validation using Pydantic schemas

### Environment Secrets
- Use `.env` for local development (not committed to git)
- Use HashiCorp Vault for production secrets (optional)
- Keep `SECRET_KEY` secure and unique per environment

## 🛠️ Development Tools

### Pre-commit Hooks

Configuration available in `.pre-commit-config.yaml`:

```bash
# Install pre-commit
pip install pre-commit

# Setup hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

### Code Quality

- **Ruff**: Fast Python linter and formatter
- **Pre-commit**: Automated code quality checks

```bash
# Format code with ruff
ruff format app tests

# Lint code
ruff check app tests
```

## 📦 Dependencies

### Core
- **FastAPI** (>=0.104.1): Modern web framework
- **Uvicorn** (>=0.24.0): ASGI server
- **SQLAlchemy** (>=2.0.23): ORM
- **Alembic** (>=1.13.0): Database migrations
- **Pydantic** (>=2.5.0): Data validation

### Authentication & Security
- **python-jose** (>=3.3.0): JWT handling
- **bcrypt** (>=4.0.0): Password hashing
- **passlib**: Password utilities

### Database Drivers
- **psycopg2-binary** (>=2.9.9): PostgreSQL driver
- **PyMySQL** (>=1.0.3): MySQL driver (optional)

### External APIs
- **httpx** (>=0.27.0): Async HTTP client
- **hvac** (>=2.4.0): HashiCorp Vault client

### Development & Testing
- **pytest** (>=7.4.0): Test framework
- **pytest-cov**: Coverage reporting
- **Faker** (>=24.0.0): Fake data generation
- **ruff** (>=0.15.0): Linter & formatter
- **pre-commit** (>=4.5.1): Git hooks

## 🐳 Docker

Run the application with Docker:

```bash
# Using docker-compose
docker-compose -f docker/docker-compose.yml up

# Build image
docker build -t mindiff-backend .

# Run container
docker run -p 8000:8000 --env-file .env mindiff-backend
```

See `docker/docker-compose.yml` for full configuration.

## 📚 Utility Scripts

### Import Exercises
Import exercise data from JSON files:

```bash
python scripts/import_exercices.py
```

### Seed Database
Populate database with sample data:

```bash
python scripts/seed_db.py
python scripts/seed_exercises.py
```

### Vault Integration
Initialize Vault secrets (requires Vault access):

```bash
python scripts/seed_vault.py
```

### Download Exercise GIFs
Download GIFs for exercises:

```bash
python scripts/download_gifs.py
```

## 🚀 Deployment

### Production Checklist

- [ ] Set `DEBUG=False` in environment
- [ ] Use strong `SECRET_KEY` (generated with `openssl rand -hex 32`)
- [ ] Use PostgreSQL instead of SQLite
- [ ] Restrict CORS origins in `app/main.py`
- [ ] Enable HTTPS/TLS on server
- [ ] Use environment variables or Vault for secrets
- [ ] Configure proper logging
- [ ] Set up database backups
- [ ] Use a production ASGI server (Gunicorn + Uvicorn)
- [ ] Configure reverse proxy (Nginx/Apache)
- [ ] Implement rate limiting
- [ ] Set up monitoring and alerting

### Example Gunicorn Command

```bash
gunicorn app.main:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --access-logfile - \
  --error-logfile -
```

## 📝 Configuration Files

- **pyproject.toml**: Project metadata, dependencies, and tool configurations
- **alembic.ini**: Database migration settings
- **pytest.ini**: Pytest test discovery and execution settings
- **conftest.py**: Shared pytest fixtures and configuration
- **.pre-commit-config.yaml**: Pre-commit hooks configuration
- **mise.toml**: Task runner configuration (optional)

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes and add tests
3. Run tests: `pytest`
4. Format code: `ruff format app tests`
5. Lint: `ruff check app tests`
6. Commit: `git commit -m "Add my feature"`
7. Push: `git push origin feature/my-feature`
8. Create Pull Request

## 📄 License

Specify your license here.

## 📧 Support

For issues, questions, or contributions, please open an issue in the repository.

---

**Last Updated**: January 2025
**Version**: 1.0.0
