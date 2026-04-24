"""
Script pour importer les exercices depuis le fichier JSON Firebase
"""

import json
import os
import sys

from sqlalchemy.orm import Session

from app.db.database import Base, SessionLocal, engine
from app.models.exercise import Exercise, Instruction, SecondaryMuscle


def _resolve_gif_url(raw_url: str | None) -> str | None:
    """
    Remplace le placeholder {API_BASE_URL} par la base API.
    Si le JSON pointe vers .../api/static/gifs/..., on corrige vers .../static/gifs/...
    """
    if not raw_url:
        return raw_url
    api_base = os.getenv("API_BASE_URL", "http://localhost:8000/api").rstrip("/")
    resolved = raw_url.replace("{API_BASE_URL}", api_base)
    return resolved.replace("/api/static/gifs/", "/static/gifs/")


def create_tables():
    """Create tables if they don't exist yet."""
    Base.metadata.create_all(bind=engine)


def import_exercices(json_file_path: str):
    """
    Import exercices from a JSON file

    Args:
        json_file_path: Path to the JSON file
    """
    # Load JSON file
    print(f"Chargement du fichier JSON: {json_file_path}")
    with open(json_file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, dict):
        exercices_data = data.get("Exercises", [])
    elif isinstance(data, list):
        exercices_data = data
    else:
        raise ValueError("Format JSON invalide: attendu objet ou liste")
    print(f"Nombre d'exercices à importer: {len(exercices_data)}")

    # Create DB session
    db: Session = SessionLocal()

    try:
        imported_count = 0
        skipped_count = 0

        for exercice_data in exercices_data:
            try:
                # Check if exercice already exists
                exercise_id = exercice_data.get("id")
                existing = db.query(Exercise).filter(Exercise.id == exercise_id).first()

                if existing:
                    print(f"Exercise {exercise_id} déjà existant, ignoré")
                    skipped_count += 1
                    continue

                # Create exercise object
                exercice = Exercise(
                    id=exercice_data.get("id"),
                    name=exercice_data.get("name"),
                    equipment=exercice_data.get("equipment"),
                    gif_url=_resolve_gif_url(exercice_data.get("gifUrl")),
                    body_part=exercice_data.get("bodyPart"),
                    target=exercice_data.get("target"),
                )

                # Ajouter les instructions
                instructions = exercice_data.get("instructions", [])
                for order, instruction_text in enumerate(instructions, start=1):
                    instruction = Instruction(
                        step_order=order, text=instruction_text, exercise_id=exercice.id
                    )
                    exercice.instructions.append(instruction)

                # Ajouter les muscles secondaires
                secondary_muscles = exercice_data.get("secondaryMuscles", [])
                for muscle_name in secondary_muscles:
                    muscle = SecondaryMuscle(name=muscle_name, exercise_id=exercice.id)
                    exercice.secondary_muscles.append(muscle)

                # Ajouter à la session
                db.add(exercice)
                imported_count += 1

                if imported_count % 100 == 0:
                    print(f"Importés: {imported_count} exercices...")
                    db.commit()

            except Exception as e:
                print(
                    f"Erreur lors de l'import de l'exercice {exercice_data.get('id', 'unknown')}: {e}"
                )
                db.rollback()
                continue

        # Commit final
        db.commit()
        print(f"\n✅ Import terminé!")
        print(f"   - Exercices importés: {imported_count}")
        print(f"   - Exercices ignorés (déjà existants): {skipped_count}")

    except Exception as e:
        print(f"Erreur lors de l'import: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        json_path = (
            "/home/crocolle/Téléchargements/mindiff-95645-default-rtdb-export.json"
        )
        print(f"Aucun fichier spécifié, utilisation du chemin par défaut: {json_path}")
    else:
        json_path = sys.argv[1]

    print("Création des tables si nécessaire...")
    create_tables()

    print("\nDémarrage de l'import...")
    import_exercices(json_path)
