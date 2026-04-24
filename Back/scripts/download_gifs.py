"""
Script de téléchargement des GIFs depuis Firebase Storage.

Usage (depuis mindiff-backend/) :
    python -m scripts.download_gifs

- Télécharge les GIFs dans static/gifs/
- Met à jour gif_url en DB pour pointer vers http://localhost:8082/static/gifs/<filename>
- Idempotent : skipe les GIFs déjà téléchargés
- Affiche une barre de progression
"""

import json
import sys
import time
from pathlib import Path
from urllib.parse import urlparse

import httpx

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.database import SessionLocal
from app.models.exercise import Exercise

JSON_PATH = Path(__file__).parent.parent.parent / "mindiff-95645-default-rtdb-Exercices-export.json"
GIF_DIR = Path(__file__).parent.parent / "static" / "gifs"
BASE_URL = "http://localhost:8082/static/gifs"


def filename_from_url(url: str) -> str:
    """Extrait le nom de fichier depuis l'URL Firebase (ex: gif_0.gif)."""
    path = urlparse(url).path          # /v0/b/.../o/gif_0.gif
    name = path.split("/o/")[-1]       # gif_0.gif
    return name.split("?")[0]          # au cas où


def download_gifs():
    GIF_DIR.mkdir(parents=True, exist_ok=True)

    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    total = len(data)
    downloaded = 0
    skipped = 0
    failed = []

    print(f"{total} exercices trouvés. Téléchargement dans {GIF_DIR}\n")

    with httpx.Client(timeout=30, follow_redirects=True) as client:
        for i, item in enumerate(data, start=1):
            url = item.get("gifUrl", "")
            if not url:
                continue

            fname = filename_from_url(url)
            dest = GIF_DIR / fname

            # Progress
            bar = int((i / total) * 30)
            print(f"\r[{'█' * bar}{'░' * (30 - bar)}] {i}/{total}  ", end="", flush=True)

            if dest.exists():
                skipped += 1
                continue

            try:
                resp = client.get(url)
                resp.raise_for_status()
                dest.write_bytes(resp.content)
                downloaded += 1
                # Petite pause pour ne pas spam Firebase
                time.sleep(0.05)
            except Exception as e:
                failed.append((item["id"], fname, str(e)))

    print(f"\n\nTéléchargement terminé : {downloaded} nouveaux, {skipped} déjà présents, {len(failed)} échecs.")

    if failed:
        print("\nÉchecs :")
        for ex_id, fname, err in failed[:10]:
            print(f"  [{ex_id}] {fname} → {err}")
        if len(failed) > 10:
            print(f"  ... et {len(failed) - 10} autres")

    return len(failed) == 0


def update_db_urls():
    """Met à jour gif_url dans la DB pour pointer vers le backend local."""
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    db = SessionLocal()
    updated = 0

    try:
        for item in data:
            url = item.get("gifUrl", "")
            if not url:
                continue
            fname = filename_from_url(url)
            local_url = f"{BASE_URL}/{fname}"

            ex = db.query(Exercise).filter(Exercise.id == item["id"]).first()
            if ex and ex.gif_url != local_url:
                ex.gif_url = local_url
                updated += 1

        db.commit()
        print(f"{updated} URLs mises à jour en DB.")
    except Exception as e:
        db.rollback()
        print(f"Erreur DB : {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    success = download_gifs()
    if success:
        print("\nMise à jour des URLs en base de données...")
        update_db_urls()
    else:
        print("\nDes GIFs ont échoué. Lance update_db uniquement pour les réussis ?")
        print("Relance le script — il skipera les GIFs déjà téléchargés.")
