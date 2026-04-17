from starlette.testclient import TestClient
import pytest
from app.main import app

@pytest.fixture
def get_api_client():
    return TestClient(app)
