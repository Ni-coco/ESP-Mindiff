"""Root conftest for pytest."""

import os

# Disable Alembic migrations during tests
os.environ["SKIP_ALEMBIC"] = "1"
