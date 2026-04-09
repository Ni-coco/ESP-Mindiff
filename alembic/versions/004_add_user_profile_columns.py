"""Add profile columns to users table

Revision ID: 004
Revises: 003
Create Date: 2026-03-26

"""
from alembic import op
import sqlalchemy as sa


revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('gender', sa.String(), nullable=True))
    op.add_column('users', sa.Column('sport_objective', sa.String(), nullable=True))
    op.add_column('users', sa.Column('target_weight', sa.Float(), nullable=True))
    op.add_column('users', sa.Column('sessions_per_week', sa.Integer(), nullable=True))
    op.add_column('users', sa.Column('health_considerations', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'health_considerations')
    op.drop_column('users', 'sessions_per_week')
    op.drop_column('users', 'target_weight')
    op.drop_column('users', 'sport_objective')
    op.drop_column('users', 'gender')
