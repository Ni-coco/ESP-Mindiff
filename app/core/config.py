import os

import hvac
from pydantic_settings import BaseSettings

VAULT_PATH = "mindiff"


class VaultConfig:
    def __init__(self):
        self.client = hvac.Client(
            url=os.getenv("VAULT_ADDR"), token=os.getenv("VAULT_TOKEN")
        )
        if not self.client.is_authenticated():
            raise Exception("Vault authentication failed")

    def get_secrets(self, path: str) -> dict:
        secret = self.client.secrets.kv.v2.read_secret_version(path=path)
        return secret["data"]["data"]

    def get_secret(self, path: str, key: str) -> str:
        return self.get_secrets(path)[key]


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str

    # JWT Configuration
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Application
    DEBUG: bool = False

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


def load_settings() -> Settings:
    """
    Load settings from Vault secrets first, falling back to .env / env vars
    for any missing values.
    """
    vault_secrets: dict = {}

    vault_addr = os.getenv("VAULT_ADDR")
    vault_token = os.getenv("VAULT_TOKEN")

    if vault_addr and vault_token:
        try:
            vault = VaultConfig()
            vault_secrets = vault.get_secrets(VAULT_PATH)
        except Exception as e:
            print(
                f"Warning: Could not load secrets from Vault ({e}), falling back to .env"
            )
    else:
        print("Warning: VAULT_ADDR or VAULT_TOKEN not set, falling back to .env")

    return Settings(**vault_secrets)


settings = load_settings()
