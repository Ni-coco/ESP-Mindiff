"""
Script de seed : charge les exercices depuis le JSON Firebase dans la DB.

Usage (depuis mindiff-backend/) :
    python -m scripts.seed_exercises

Le script est idempotent : il skipe les exercices déjà présents.
"""

import json
import sys
from pathlib import Path

# Ajoute le répertoire parent au path pour les imports app.*
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.database import SessionLocal
from app.models.exercise import Exercise, Instruction, SecondaryMuscle

JSON_PATH = Path(__file__).parent.parent.parent / "mindiff-95645-default-rtdb-Exercices-export.json"


def seed():
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    db = SessionLocal()
    inserted = 0
    skipped = 0

    try:
        for item in data:
            ex_id = item["id"]
            if db.query(Exercise).filter(Exercise.id == ex_id).first():
                skipped += 1
                continue

            ex = Exercise(
                id=ex_id,
                name=item["name"],
                body_part=item.get("bodyPart"),
                equipment=item.get("equipment"),
                gif_url=item.get("gifUrl"),
                target=item.get("target"),
            )

            for order, text in enumerate(item.get("instructions", []), start=1):
                ex.instructions.append(Instruction(step_order=order, text=text))

            for muscle in item.get("secondaryMuscles", []):
                ex.secondary_muscles.append(SecondaryMuscle(name=muscle))

            db.add(ex)
            inserted += 1

            # Commit par batch de 100 pour les perfs
            if inserted % 100 == 0:
                db.commit()
                print(f"  {inserted} exercices insérés...")

        db.commit()
        print(f"\nTerminé : {inserted} insérés, {skipped} déjà présents.")
    except Exception as e:
        db.rollback()
        print(f"Erreur : {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    print(f"Chargement depuis {JSON_PATH}")
    seed()
