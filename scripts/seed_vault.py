#!/usr/bin/env python3
"""
Reads the .env file and pushes all secrets (excluding Vault connection vars)
into HashiCorp Vault KV v2 at secret/mindiff.
"""

import sys
import time
from pathlib import Path

import hvac
from dotenv import dotenv_values
from requests.exceptions import ConnectionError

VAULT_PATH = "mindiff"
EXCLUDED_KEYS = {"VAULT_ADDR", "VAULT_TOKEN"}

ENV_FILE = Path(__file__).resolve().parent.parent / ".env"

MAX_RETRIES = 10
RETRY_INTERVAL = 2


def wait_for_vault(client: hvac.Client, addr: str) -> None:
    """Wait for Vault to be reachable, initialized, and unsealed."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            if not client.sys.is_initialized():
                print(
                    f"    Vault not yet initialized (attempt {attempt}/{MAX_RETRIES})"
                )
            elif client.sys.is_sealed():
                print(f"    Vault is sealed (attempt {attempt}/{MAX_RETRIES})")
            else:
                return
        except ConnectionError:
            print(f"    Vault not reachable (attempt {attempt}/{MAX_RETRIES})")

        if attempt < MAX_RETRIES:
            time.sleep(RETRY_INTERVAL)

    print(f"Error: Vault at {addr} is not ready after {MAX_RETRIES * RETRY_INTERVAL}s.")
    sys.exit(1)


def main() -> None:
    if not ENV_FILE.is_file():
        print(f"Error: .env file not found at {ENV_FILE}")
        sys.exit(1)

    env = dotenv_values(ENV_FILE)

    vault_addr = env.get("VAULT_ADDR")
    vault_token = env.get("VAULT_TOKEN")

    if not vault_addr:
        print("Error: VAULT_ADDR not found in .env")
        sys.exit(1)

    if not vault_token:
        print("Error: VAULT_TOKEN not found in .env")
        sys.exit(1)

    print(f"==> Waiting for Vault at {vault_addr} ...")

    client = hvac.Client(url=vault_addr, token=vault_token)

    wait_for_vault(client, vault_addr)

    if not client.is_authenticated():
        print("Error: Vault authentication failed. Check your VAULT_TOKEN.")
        sys.exit(1)

    print("==> Vault is ready!")

    secrets = {
        key: value
        for key, value in env.items()
        if key not in EXCLUDED_KEYS and value is not None
    }

    if not secrets:
        print("Warning: No secrets found to push.")
        sys.exit(0)

    print(f"==> Pushing secrets to secret/{VAULT_PATH} ...")

    for key in secrets:
        print(f"    • {key}")

    client.secrets.kv.v2.create_or_update_secret(
        path=VAULT_PATH,
        secret=secrets,
    )

    print(f"==> Done! {len(secrets)} secret(s) pushed to secret/{VAULT_PATH}")


if __name__ == "__main__":
    main()
