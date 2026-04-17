"""Create meal_log table

Revision ID: 007
Revises: 006
Create Date: 2026-03-27

"""
from alembic import op
import sqlalchemy as sa

revision = '007'
down_revision = '006'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'meal_log',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('meal_type', sa.String(), nullable=False),  # breakfast, lunch, dinner, snack
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('calories', sa.Float(), nullable=False, server_default='0'),
        sa.Column('protein_g', sa.Float(), nullable=False, server_default='0'),
        sa.Column('fat_g', sa.Float(), nullable=False, server_default='0'),
        sa.Column('carbs_g', sa.Float(), nullable=False, server_default='0'),
        sa.Column('fiber_g', sa.Float(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_meal_log_user_date', 'meal_log', ['user_id', 'date'])


def downgrade() -> None:
    op.drop_index('ix_meal_log_user_date', table_name='meal_log')
    op.drop_table('meal_log')
