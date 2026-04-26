"""Add analyzer_key column to exercise for ML Kit auto-validation.

Revision ID: 010
Revises: 009
Create Date: 2026-04-24
"""

import sqlalchemy as sa
from alembic import op

revision = "010"
down_revision = "009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())
    if "exercise" not in tables:
        return

    columns = {column["name"] for column in inspector.get_columns("exercise")}
    if "analyzer_key" not in columns:
        op.add_column("exercise", sa.Column("analyzer_key", sa.String(length=32), nullable=True))

    op.execute("UPDATE exercise SET analyzer_key = 'pullup' WHERE id = '0651'")


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())
    if "exercise" not in tables:
        return

    columns = {column["name"] for column in inspector.get_columns("exercise")}
    if "analyzer_key" in columns:
        op.drop_column("exercise", "analyzer_key")
