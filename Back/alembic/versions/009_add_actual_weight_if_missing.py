"""Ensure user_metrics.actual_weight exists on legacy databases.

Revision ID: 009
Revises: 008
Create Date: 2026-04-23
"""

import sqlalchemy as sa
from alembic import op

revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())
    if "user_metrics" not in tables:
        return

    columns = {column["name"] for column in inspector.get_columns("user_metrics")}
    if "actual_weight" not in columns:
        op.add_column("user_metrics", sa.Column("actual_weight", sa.Float(), nullable=True))
        op.execute("UPDATE user_metrics SET actual_weight = weight WHERE actual_weight IS NULL")


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())
    if "user_metrics" not in tables:
        return

    columns = {column["name"] for column in inspector.get_columns("user_metrics")}
    if "actual_weight" in columns:
        op.drop_column("user_metrics", "actual_weight")
