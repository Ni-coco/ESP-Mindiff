"""
Migration : remplace les URLs Firebase Storage par les URLs locales.

Firebase :  https://firebasestorage.googleapis.com/v0/b/.../o/gif_0.gif?alt=media&token=...
Cible    :  https://apidev.nini.network/static/gifs/gif_0.gif

Usage :
    python -m scripts.migrate_gif_urls
    ou avec une URL custom :
    DATABASE_URL=postgresql://... python -m scripts.migrate_gif_urls
"""

import os
import re
import sys

from sqlalchemy import create_engine, text

BASE_URL = "https://apidev.nini.network/static/gifs"
FIREBASE_PATTERN = re.compile(r"/o/([^?]+)\?")


def get_db_url() -> str:
    url = os.getenv("DATABASE_URL")
    if url:
        return url
    # Fallback : reconstruire depuis les variables individuelles
    user = os.getenv("POSTGRES_USER", "mindiff_user")
    password = os.getenv("POSTGRES_PASSWORD", "mindiff_password")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "mindiff_db")
    return f"postgresql://{user}:{password}@{host}:{port}/{db}"


def migrate(dry_run: bool = False) -> None:
    engine = create_engine(get_db_url())

    with engine.connect() as conn:
        rows = conn.execute(
            text("SELECT id, gif_url FROM exercises WHERE gif_url LIKE '%firebasestorage%'")
        ).fetchall()

        print(f"Exercices à migrer : {len(rows)}")

        updated = 0
        errors = 0
        for exercise_id, gif_url in rows:
            match = FIREBASE_PATTERN.search(gif_url)
            if not match:
                print(f"  ⚠️  Impossible d'extraire le nom du GIF pour {exercise_id} : {gif_url}")
                errors += 1
                continue

            filename = match.group(1)
            new_url = f"{BASE_URL}/{filename}"

            if dry_run:
                print(f"  [DRY] {exercise_id} : {gif_url[:60]}... → {new_url}")
            else:
                conn.execute(
                    text("UPDATE exercises SET gif_url = :url WHERE id = :id"),
                    {"url": new_url, "id": exercise_id},
                )
            updated += 1

        if not dry_run:
            conn.commit()

    print(f"\n{'[DRY RUN] ' if dry_run else ''}✅ {updated} URLs migrées, {errors} erreurs.")


if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv
    if dry_run:
        print("=== MODE DRY RUN (aucune écriture) ===\n")
    migrate(dry_run=dry_run)
