"""Add exercise tables

Revision ID: 002
Revises: 001
Create Date: 2025-11-29

"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Créer la table exercise
    op.create_table(
        "exercise",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(), nullable=False),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("equipment", sa.String(), nullable=True),
        sa.Column("gif", sa.String(), nullable=True),
        sa.Column("body_part", sa.String(), nullable=True),
        sa.Column("target", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_exercise_id"), "exercise", ["id"], unique=False)

    # Créer la table instruction
    op.create_table(
        "instruction",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("exercise_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_instruction_id"), "instruction", ["id"], unique=False)

    # Créer la table secondary_muscle
    op.create_table(
        "secondary_muscle",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.Column("exercise_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_secondary_muscle_id"), "secondary_muscle", ["id"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_secondary_muscle_id"), table_name="secondary_muscle")
    op.drop_table("secondary_muscle")
    op.drop_index(op.f("ix_instruction_id"), table_name="instruction")
    op.drop_table("instruction")
    op.drop_index(op.f("ix_exercise_id"), table_name="exercise")
    op.drop_table("exercise")
