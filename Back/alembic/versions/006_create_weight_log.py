"""Create weight_log table

Revision ID: 006
Revises: 005
Create Date: 2026-03-26

"""
from alembic import op
import sqlalchemy as sa

revision = '006'
down_revision = '005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'weight_log',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('weight', sa.Float(), nullable=False),
        sa.Column('source', sa.String(), nullable=False, server_default='manual'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'date', name='uq_weight_log_user_date'),
    )
    op.create_index('ix_weight_log_user_date', 'weight_log', ['user_id', 'date'])


def downgrade() -> None:
    op.drop_index('ix_weight_log_user_date', table_name='weight_log')
    op.drop_table('weight_log')
