from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.auth import router as auth_router
from app.api.exercise import router as exercises_router
from app.api.program import router as program_router
from app.api.user import router as user_router
from app.db.database import Base, engine

# Create database tables
Base.metadata.create_all(bind=engine)

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
app.include_router(auth_router)
app.include_router(exercises_router)
app.include_router(program_router)
app.include_router(user_router)
