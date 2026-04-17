"""Add actual_weight column to user_metrics

Revision ID: 005
Revises: 004
Create Date: 2026-03-26

"""
from alembic import op
import sqlalchemy as sa

revision = '005'
down_revision = '004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('user_metrics', sa.Column('actual_weight', sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column('user_metrics', 'actual_weight')
