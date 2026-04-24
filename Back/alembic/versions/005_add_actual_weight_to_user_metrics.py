"""Add actual_weight column to user_metrics.

Revision ID: 005
Revises: 004
Create Date: 2026-03-26

This migration is intentionally resilient:
- On a fresh database, `user_metrics` may not exist yet in older chains.
- On an existing database, `actual_weight` may already be present.
"""

from alembic import op
import sqlalchemy as sa

revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    tables = set(inspector.get_table_names())
    if "user_metrics" not in tables:
        op.create_table(
            "user_metrics",
            sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
            sa.Column(
                "user_id",
                sa.Integer(),
                sa.ForeignKey("users.id"),
                nullable=False,
            ),
            sa.Column("weight", sa.Float(), nullable=False),
            sa.Column("height", sa.Integer(), nullable=False),
            sa.Column("age", sa.Integer(), nullable=False),
        )
        op.create_index("ix_user_metrics_id", "user_metrics", ["id"], unique=False)
        return

    columns = {column["name"] for column in inspector.get_columns("user_metrics")}
    if "actual_weight" not in columns:
        op.add_column(
            "user_metrics",
            sa.Column("actual_weight", sa.Float(), nullable=True),
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())
    if "user_metrics" not in tables:
        return

    columns = {column["name"] for column in inspector.get_columns("user_metrics")}
    if "actual_weight" in columns:
        op.drop_column("user_metrics", "actual_weight")
