"""Rebuild exercise tables (VARCHAR id) + add workout tables

Revision ID: 008
Revises: 007
Create Date: 2026-04-03

"""

import sqlalchemy as sa
from alembic import op

revision = "008"
down_revision = "007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Supprimer les anciennes tables exercise/program (vides, schéma incorrect) ──
    op.drop_table("program_exercise")
    op.drop_index("ix_program_id", table_name="program")
    op.drop_table("program")
    op.drop_index("ix_secondary_muscle_id", table_name="secondary_muscle")
    op.drop_table("secondary_muscle")
    op.drop_index("ix_instruction_id", table_name="instruction")
    op.drop_table("instruction")
    op.drop_index("ix_exercise_id", table_name="exercise")
    op.drop_table("exercise")

    # ── Recréer exercise avec id VARCHAR ─────────────────────────────────────────
    op.create_table(
        "exercise",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("body_part", sa.String(), nullable=True),
        sa.Column("equipment", sa.String(), nullable=True),
        sa.Column("gif_url", sa.String(), nullable=True),
        sa.Column("target", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_exercise_target", "exercise", ["target"])
    op.create_index("ix_exercise_body_part", "exercise", ["body_part"])

    op.create_table(
        "instruction",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("exercise_id", sa.String(), nullable=False),
        sa.Column("step_order", sa.Integer(), nullable=False),
        sa.Column("text", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "secondary_muscle",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("exercise_id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_secondary_muscle_name", "secondary_muscle", ["name"])

    # ── Tables workout généré ─────────────────────────────────────────────────────
    op.create_table(
        "workout_week",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("week_number", sa.Integer(), nullable=False),
        sa.Column("goal", sa.String(), nullable=True),
        sa.Column("sessions_per_week", sa.Integer(), nullable=False),
        sa.Column("is_pinned", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "year", "week_number", name="uq_workout_week_user"),
    )

    op.create_table(
        "workout_session",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("workout_week_id", sa.Integer(), nullable=False),
        sa.Column("session_number", sa.Integer(), nullable=False),
        sa.Column("split_name", sa.String(), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["workout_week_id"], ["workout_week.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "workout_session_exercise",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("exercise_id", sa.String(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("sets", sa.Integer(), nullable=False),
        sa.Column("reps_min", sa.Integer(), nullable=False),
        sa.Column("reps_max", sa.Integer(), nullable=False),
        sa.Column("is_cardio", sa.Boolean(), nullable=False, server_default="false"),
        sa.ForeignKeyConstraint(["session_id"], ["workout_session.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── Tables workout custom ─────────────────────────────────────────────────────
    op.create_table(
        "custom_workout",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "custom_workout_exercise",
        sa.Column("id", sa.Integer(), nullable=False, autoincrement=True),
        sa.Column("custom_workout_id", sa.Integer(), nullable=False),
        sa.Column("exercise_id", sa.String(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("sets", sa.Integer(), nullable=False),
        sa.Column("reps_min", sa.Integer(), nullable=False),
        sa.Column("reps_max", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["custom_workout_id"], ["custom_workout.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"]),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("custom_workout_exercise")
    op.drop_table("custom_workout")
    op.drop_table("workout_session_exercise")
    op.drop_table("workout_session")
    op.drop_table("workout_week")
    op.drop_index("ix_secondary_muscle_name", table_name="secondary_muscle")
    op.drop_table("secondary_muscle")
    op.drop_table("instruction")
    op.drop_index("ix_exercise_body_part", table_name="exercise")
    op.drop_index("ix_exercise_target", table_name="exercise")
    op.drop_table("exercise")
