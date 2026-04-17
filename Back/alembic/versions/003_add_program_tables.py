"""Add program tables

Revision ID: 003
Revises: 002
Create Date: 2025-11-29

"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Créer la table program
    op.create_table(
        "program",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("difficulty", sa.String(), nullable=True),
        sa.Column("calorie_burn", sa.Integer(), nullable=True),
        sa.Column("duration", sa.Integer(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_program_id"), "program", ["id"], unique=False)

    # Créer la table d'association program_exercise (many-to-many)
    op.create_table(
        "program_exercise",
        sa.Column("program_id", sa.Integer(), nullable=False),
        sa.Column("exercise_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercise.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["program_id"], ["program.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("program_id", "exercise_id"),
    )


def downgrade() -> None:
    op.drop_table("program_exercise")
    op.drop_index(op.f("ix_program_id"), table_name="program")
    op.drop_table("program")
