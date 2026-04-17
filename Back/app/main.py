from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from alembic.config import Config
from alembic import command
from app.api.auth import router as auth_router
from app.api.exercise import router as exercises_router
from app.api.user import router as user_router
from app.api.weight_log import router as weight_log_router
from app.api.meals import router as meals_router
from app.api.workout import router as workout_router
from app.api.dashboard import router as dashboard_router

# Lancer les migrations Alembic au démarrage (crée et met à jour les tables)
alembic_cfg = Config("alembic.ini")
command.upgrade(alembic_cfg, "head")

import os
from pathlib import Path

app = FastAPI(
    title="Mindiff API",
    description="Audran a toujours kiffé bouffer les orteils d'Alexis",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routing
static_dir = Path(__file__).parent.parent / "static"
static_dir.mkdir(exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

app.include_router(auth_router)
app.include_router(exercises_router)
app.include_router(user_router)
app.include_router(weight_log_router)
app.include_router(meals_router)
app.include_router(workout_router)
app.include_router(dashboard_router)
