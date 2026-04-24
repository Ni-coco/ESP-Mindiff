import os

from alembic.config import Config
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from alembic import command
from app.api.auth import router as auth_router
from app.api.dashboard import router as dashboard_router
from app.api.exercise import router as exercises_router
from app.api.meals import router as meals_router
from app.api.program import router as program_router
from app.api.user import router as user_router
from app.api.weight_log import router as weight_log_router
from app.api.workout import router as workout_router
from app.core.config import settings

# Lancer les migrations Alembic au démarrage (crée et met à jour les tables)
# Sauf en test
if not os.environ.get("SKIP_ALEMBIC"):
    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")

from pathlib import Path

app = FastAPI(
    title="Mindiff API",
    description="Audran a toujours kiffé bouffer les orteils d'Alexis",
    version="1.0.0",
)


def _parse_cors_origins(raw_origins: str) -> list[str]:
    if not raw_origins.strip():
        return []
    if raw_origins.strip() == "*":
        return ["*"]
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]


# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=_parse_cors_origins(settings.CORS_ORIGINS),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health")
def health_check():
    return {"status": "ok"}


# Enregistrer tous les routers API
app.include_router(auth_router, prefix="/api")
app.include_router(user_router, prefix="/api")
app.include_router(exercises_router, prefix="/api")
app.include_router(meals_router, prefix="/api")
app.include_router(weight_log_router, prefix="/api")
app.include_router(workout_router, prefix="/api")
app.include_router(program_router, prefix="/api")
app.include_router(dashboard_router, prefix="/api")

# Monter les fichiers statiques
static_path = Path(__file__).parent.parent / "static"
if static_path.exists():
    app.mount("/static", StaticFiles(directory=str(static_path)), name="static")
