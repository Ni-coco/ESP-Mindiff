"""
Seed script using Faker to populate the PostgreSQL database with test data.

Usage:
    python scripts/seed_db.py [--users N] [--exercises N] [--programs N] [--clean]

Options:
    --users N       Number of users to create (default: 20)
    --exercises N   Number of exercises to create (default: 50)
    --programs N    Number of programs to create (default: 10)
    --clean         Drop all existing data before seeding
"""

import argparse
import random
import sys
from pathlib import Path

# Allow running from the project root
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from faker import Faker
from sqlalchemy import text

from app.core.enum import DifficultyLevel
from app.core.security import get_password_hash
from app.db.database import Base, SessionLocal, engine
from app.models.exercise import Exercise, Instruction, SecondaryMuscle
from app.models.program import Program
from app.models.user import User, UserMetrics

fake = Faker("fr_FR")
Faker.seed(42)
random.seed(42)

# ── Domain data ────────────────────────────────────────────────────────────────

BODY_PARTS = [
    "Pectoraux",
    "Dos",
    "Épaules",
    "Biceps",
    "Triceps",
    "Abdominaux",
    "Quadriceps",
    "Ischio-jambiers",
    "Fessiers",
    "Mollets",
    "Avant-bras",
    "Trapèzes",
]

SECONDARY_MUSCLES = [
    "Deltoïde antérieur",
    "Deltoïde postérieur",
    "Grand dorsal",
    "Rhomboïdes",
    "Dentelé antérieur",
    "Grand fessier",
    "Moyen fessier",
    "Soléaire",
    "Gastrocnémien",
    "Transverse de l'abdomen",
    "Obliques internes",
    "Obliques externes",
    "Érecteurs du rachis",
    "Coiffe des rotateurs",
    "Adducteurs",
    "Tenseur du fascia lata",
]

EQUIPMENT_LIST = [
    "Haltères",
    "Barre olympique",
    "Machine à câbles",
    "Poulie haute",
    "Poulie basse",
    "Barre de traction",
    "Banc plat",
    "Banc incliné",
    "Smith machine",
    "Kettlebell",
    "TRX",
    "Poids du corps",
    "Élastiques",
]

EXERCISE_TITLES = [
    "Développé couché",
    "Squat barre",
    "Soulevé de terre",
    "Tractions",
    "Dips",
    "Curl biceps",
    "Extension triceps poulie",
    "Presse à cuisses",
    "Leg curl allongé",
    "Mollets debout",
    "Écarté incliné",
    "Rowing barre",
    "Tirage vertical prise large",
    "Élévations latérales",
    "Shrugs",
    "Crunch abdominaux",
    "Gainage planche",
    "Hip thrust",
    "Fentes marchées",
    "Bulgarian split squat",
    "Hack squat",
    "Leg extension",
    "Curl marteau",
    "Face pull",
    "Arnold press",
    "Développé militaire",
    "Rowing unilatéral",
    "Curl incliné",
    "Kickback triceps",
    "Farmer's walk",
    "Deadlift roumain",
    "Good morning",
    "Hyperextension",
    "Pullover haltère",
    "Fly pec deck",
    "Chest supported row",
    "Pendlay row",
    "Zercher squat",
    "Box jump",
    "Battle rope",
    "Kettlebell swing",
    "Turkish get-up",
    "Snatch haltère",
    "Clean & press",
    "Renegade row",
    "Bear crawl",
    "Dragon flag",
    "L-sit",
    "Pistol squat",
    "Nordic curl",
]


# ── Helpers ────────────────────────────────────────────────────────────────────


def _print_section(title: str) -> None:
    print(f"\n{'─' * 50}")
    print(f"  {title}")
    print(f"{'─' * 50}")


def _print_ok(msg: str) -> None:
    print(f"  ✓  {msg}")


def _print_skip(msg: str) -> None:
    print(f"  ~  {msg}")


# ── Seeders ────────────────────────────────────────────────────────────────────


def seed_exercises(session, n: int) -> list[Exercise]:
    existing = session.query(Exercise).count()
    if existing:
        _print_skip(f"Exercises déjà présents ({existing}), on passe.")
        return session.query(Exercise).all()

    titles = random.sample(EXERCISE_TITLES, min(n, len(EXERCISE_TITLES)))
    if n > len(EXERCISE_TITLES):
        extras = [
            f"{fake.word().capitalize()} {fake.word()}"
            for _ in range(n - len(EXERCISE_TITLES))
        ]
        titles += extras

    exercises = []
    for title in titles:
        ex = Exercise(
            title=title,
            description=fake.paragraph(nb_sentences=3),
            equipment=random.choice(EQUIPMENT_LIST),
            gif=f"https://cdn.mindiff.io/exercises/{fake.uuid4()}.gif",
            body_part=random.choice(BODY_PARTS),
            target=random.choice(BODY_PARTS),
        )
        exercises.append(ex)

    session.add_all(exercises)
    session.flush()

    # Attach instructions and secondary muscles via FK on child side
    for ex in exercises:
        num_instructions = random.randint(3, 6)
        for step in range(1, num_instructions + 1):
            instruction = Instruction(
                description=f"Étape {step} : {fake.sentence(nb_words=10)}",
                exercise_id=ex.id,
            )
            session.add(instruction)

        num_muscles = random.randint(1, 3)
        for muscle_name in random.sample(SECONDARY_MUSCLES, num_muscles):
            muscle = SecondaryMuscle(name=muscle_name, exercise_id=ex.id)
            session.add(muscle)

    session.flush()
    _print_ok(f"{len(exercises)} exercices créés.")
    return exercises


def seed_programs(session, exercises: list[Exercise], n: int) -> list[Program]:
    existing = session.query(Program).count()
    if existing:
        _print_skip(f"Programs déjà présents ({existing}), on passe.")
        return session.query(Program).all()

    programs = []
    difficulty_choices = list(DifficultyLevel)

    for _ in range(n):
        difficulty = random.choice(difficulty_choices)

        # Calories burn varies by difficulty
        calorie_range = {
            DifficultyLevel.EASY: (150, 300),
            DifficultyLevel.MEDIUM: (300, 500),
            DifficultyLevel.HARD: (500, 900),
        }
        cal_min, cal_max = calorie_range[difficulty]

        program = Program(
            name=f"Programme {fake.word().capitalize()} {fake.word().capitalize()}",
            description=fake.paragraph(nb_sentences=2),
            difficulty=difficulty,
            calorie_burn=random.randint(cal_min, cal_max),
            duration=random.choice([20, 30, 45, 60, 75, 90]),
        )
        programs.append(program)

    session.add_all(programs)
    session.flush()

    # Assign a random subset of exercises to each program
    for program in programs:
        num_exercises = random.randint(3, min(8, len(exercises)))
        program.exercises = random.sample(exercises, num_exercises)

    session.flush()
    _print_ok(f"{len(programs)} programmes créés.")
    return programs


def seed_users(session, n: int) -> list[User]:
    existing = session.query(User).count()
    if existing:
        _print_skip(f"Users déjà présents ({existing}), on passe.")
        return session.query(User).all()

    users = []
    # Always create one known admin account for easy testing
    admin = User(
        email="admin@mindiff.io",
        username="admin",
        hashed_password=get_password_hash("Admin1234!"),
        is_active=True,
        is_superuser=True,
    )
    session.add(admin)
    session.flush()

    admin_metrics = UserMetrics(
        user_id=admin.id,
        weight=80.0,
        height=180,
        age=30,
    )
    session.add(admin_metrics)
    users.append(admin)

    # Random users
    seen_emails: set[str] = {"admin@mindiff.io"}
    seen_usernames: set[str] = {"admin"}

    for _ in range(n - 1):
        email = fake.unique.email()
        while email in seen_emails:
            email = fake.email()
        seen_emails.add(email)

        username = fake.user_name()
        while username in seen_usernames:
            username = fake.user_name()
        seen_usernames.add(username)

        user = User(
            email=email,
            username=username,
            hashed_password=get_password_hash("Password1234!"),
            is_active=random.random() > 0.1,  # 90 % actifs
            is_superuser=False,
        )
        session.add(user)
        session.flush()

        metrics = UserMetrics(
            user_id=user.id,
            weight=round(random.uniform(50.0, 120.0), 1),
            height=random.randint(155, 200),
            age=random.randint(16, 65),
        )
        session.add(metrics)
        users.append(user)

    session.flush()
    _print_ok(
        f"{len(users)} utilisateurs créés (dont 1 admin : admin@mindiff.io / Admin1234!)."
    )
    return users


# ── Clean ──────────────────────────────────────────────────────────────────────


def clean_database(session) -> None:
    _print_section("Nettoyage de la base de données")
    tables = [
        "user_metrics",
        "users",
        "program_exercise",
        "instruction",
        "secondary_muscle",
        "exercise",
        "program",
    ]
    for table in tables:
        session.execute(text(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE"))
    session.commit()
    _print_ok("Toutes les tables ont été vidées.")


# ── Main ───────────────────────────────────────────────────────────────────────


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Seed the MindDiff PostgreSQL database with Faker data."
    )
    parser.add_argument(
        "--users", type=int, default=20, help="Nombre d'utilisateurs à créer"
    )
    parser.add_argument(
        "--exercises", type=int, default=50, help="Nombre d'exercices à créer"
    )
    parser.add_argument(
        "--programs", type=int, default=10, help="Nombre de programmes à créer"
    )
    parser.add_argument(
        "--clean", action="store_true", help="Vider la DB avant de seeder"
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    print("\n🌱  MindDiff — Seed DB")
    print(
        f"    users={args.users}  exercises={args.exercises}  programs={args.programs}  clean={args.clean}"
    )

    # Create all tables (no-op if already exist)
    Base.metadata.create_all(bind=engine)

    session = SessionLocal()
    try:
        if args.clean:
            clean_database(session)

        _print_section(f"Exercices ({args.exercises})")
        exercises = seed_exercises(session, args.exercises)

        _print_section(f"Programmes ({args.programs})")
        seed_programs(session, exercises, args.programs)

        _print_section(f"Utilisateurs ({args.users})")
        seed_users(session, args.users)

        session.commit()
        print("\n✅  Seed terminé avec succès !\n")

    except Exception as exc:
        session.rollback()
        print(f"\n❌  Erreur durant le seed : {exc}")
        raise
    finally:
        session.close()


if __name__ == "__main__":
    main()
