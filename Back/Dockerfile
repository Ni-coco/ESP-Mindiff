FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml uv.lock ./
RUN pip install --upgrade pip \
    && pip install uv \
    && uv pip install --system .

COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app
COPY scripts ./scripts

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8000/health || exit 1

CMD ["sh", "-c", "alembic upgrade head && if [ -n \"$EXERCISES_JSON_PATH\" ] && [ -f \"$EXERCISES_JSON_PATH\" ]; then python scripts/import_exercices.py \"$EXERCISES_JSON_PATH\"; else echo \"EXERCISES_JSON_PATH absent ou fichier introuvable, import_exercices skip\"; fi && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
