"""Add exercice tables

Revision ID: 002
Revises: 001
Create Date: 2025-11-29

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Créer la table exercice
    op.create_table(
        'exercice',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('description', sa.String(), nullable=True),
        sa.Column('equipment', sa.String(), nullable=True),
        sa.Column('gif', sa.String(), nullable=True),
        sa.Column('body_part', sa.String(), nullable=False),
        sa.Column('target', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_exercice_id'), 'exercice', ['id'], unique=False)

    # Créer la table instruction
    op.create_table(
        'instruction',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('description', sa.String(), nullable=True),
        sa.Column('exercice_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['exercice_id'], ['exercice.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_instruction_id'), 'instruction', ['id'], unique=False)

    # Créer la table secondary_muscle
    op.create_table(
        'secondary_muscle',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column('exercice_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['exercice_id'], ['exercice.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_secondary_muscle_id'), 'secondary_muscle', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_secondary_muscle_id'), table_name='secondary_muscle')
    op.drop_table('secondary_muscle')
    op.drop_index(op.f('ix_instruction_id'), table_name='instruction')
    op.drop_table('instruction')
    op.drop_index(op.f('ix_exercice_id'), table_name='exercice')
    op.drop_table('exercice')

