"""
Comprehensive unit tests for app.services.program module.

Tests cover all program service functions with 100% coverage:
- list_programs: get all programs
- get_program: get program by ID
- create_program: create new program
- update_program: update existing program
- delete_program: delete program
"""

import pytest
from sqlalchemy.orm import Session

from app.models.program import Program
from app.schemas.program import ProgramCreate, ProgramUpdate
from app.services import program as program_service


class TestListPrograms:
    """Tests for list_programs function."""

    def test_list_programs_empty(self, db: Session):
        """Test listing programs with empty database."""
        programs = program_service.list_programs(db)
        assert programs == []

    def test_list_programs_single(self, db: Session, test_program: Program):
        """Test listing programs with single program."""
        programs = program_service.list_programs(db)
        assert len(programs) == 1
        assert programs[0].id == test_program.id

    def test_list_programs_multiple(self, db: Session):
        """Test listing multiple programs."""
        for i in range(3):
            program = Program(
                name=f"Program {i}",
                description=f"Description {i}",
                difficulty="easy",
                calorie_burn=200 + i * 50,
                duration=30 + i * 5,
            )
            db.add(program)
        db.commit()

        programs = program_service.list_programs(db)
        assert len(programs) == 3

    def test_list_programs_returns_program_objects(
        self, db: Session, test_program: Program
    ):
        """Test that list returns Program objects."""
        programs = program_service.list_programs(db)
        assert len(programs) > 0
        assert isinstance(programs[0], Program)


class TestGetProgram:
    """Tests for get_program function."""

    def test_get_program_exists(self, db: Session, test_program: Program):
        """Test getting existing program."""
        program = program_service.get_program(db, test_program.id)
        assert program is not None
        assert program.id == test_program.id
        assert program.name == test_program.name

    def test_get_program_not_exists(self, db: Session):
        """Test getting non-existent program."""
        program = program_service.get_program(db, 99999)
        assert program is None

    def test_get_program_invalid_id(self, db: Session):
        """Test getting program with invalid ID."""
        program = program_service.get_program(db, 0)
        assert program is None

    def test_get_program_returns_all_fields(self, db: Session, test_program: Program):
        """Test that get returns all program fields."""
        program = program_service.get_program(db, test_program.id)
        assert program.name is not None
        assert program.description is not None
        assert program.difficulty is not None
        assert program.calorie_burn is not None
        assert program.duration is not None


class TestCreateProgram:
    """Tests for create_program function."""

    def test_create_program_basic(self, db: Session):
        """Test creating a basic program."""
        program_data = ProgramCreate(
            name="New Program",
            description="A new training program",
            difficulty="medium",
            calorie_burn=300,
            duration=45,
        )
        program = program_service.create_program(db, program_data)

        assert program.id is not None
        assert program.name == "New Program"
        assert program.description == "A new training program"
        assert program.difficulty == "medium"
        assert program.calorie_burn == 300
        assert program.duration == 45

    def test_create_program_persisted(self, db: Session):
        """Test that created program is persisted."""
        program_data = ProgramCreate(
            name="Persisted Program",
            description="Test",
            difficulty="easy",
            calorie_burn=200,
            duration=30,
        )
        program = program_service.create_program(db, program_data)

        retrieved = db.query(Program).filter(Program.id == program.id).first()
        assert retrieved is not None
        assert retrieved.name == "Persisted Program"

    def test_create_program_multiple(self, db: Session):
        """Test creating multiple programs."""
        for i in range(3):
            program_data = ProgramCreate(
                name=f"Program {i}",
                description=f"Description {i}",
                difficulty="easy",
                calorie_burn=200 + i * 50,
                duration=30 + i * 5,
            )
            program_service.create_program(db, program_data)

        all_programs = db.query(Program).all()
        assert len(all_programs) == 3

    def test_create_program_different_difficulties(self, db: Session):
        """Test creating programs with different difficulties."""
        difficulties = ["easy", "medium", "hard"]

        for difficulty in difficulties:
            program_data = ProgramCreate(
                name=f"{difficulty} program",
                description="Test",
                difficulty=difficulty,
                calorie_burn=200,
                duration=30,
            )
            program = program_service.create_program(db, program_data)
            assert program.difficulty == difficulty

    def test_create_program_different_durations(self, db: Session):
        """Test creating programs with different durations."""
        durations = [15, 30, 45, 60, 90]

        for duration in durations:
            program_data = ProgramCreate(
                name=f"Program {duration}min",
                description="Test",
                difficulty="easy",
                calorie_burn=200,
                duration=duration,
            )
            program = program_service.create_program(db, program_data)
            assert program.duration == duration


class TestUpdateProgram:
    """Tests for update_program function."""

    def test_update_program_basic(self, db: Session, test_program: Program):
        """Test updating a program."""
        update_data = ProgramUpdate(
            name="Updated Name",
            description="Updated Description",
            difficulty="hard",
            calorie_burn=400,
            duration=60,
        )
        updated = program_service.update_program(db, test_program.id, update_data)

        assert updated is not None
        assert updated.name == "Updated Name"
        assert updated.description == "Updated Description"
        assert updated.difficulty == "hard"
        assert updated.calorie_burn == 400
        assert updated.duration == 60

    def test_update_program_persisted(self, db: Session, test_program: Program):
        """Test that updates are persisted."""
        update_data = ProgramUpdate(
            name="Persisted Update",
            description="Updated",
            difficulty="easy",
            calorie_burn=200,
            duration=30,
        )
        program_service.update_program(db, test_program.id, update_data)

        retrieved = db.query(Program).filter(Program.id == test_program.id).first()
        assert retrieved.name == "Persisted Update"

    def test_update_program_not_exists(self, db: Session):
        """Test updating non-existent program."""
        update_data = ProgramUpdate(
            name="New",
            description="Desc",
            difficulty="easy",
            calorie_burn=200,
            duration=30,
        )
        result = program_service.update_program(db, 99999, update_data)
        assert result is None

    def test_update_program_all_fields(self, db: Session, test_program: Program):
        """Test updating all fields."""
        update_data = ProgramUpdate(
            name="New Name",
            description="New Description",
            difficulty="medium",
            calorie_burn=300,
            duration=45,
        )
        updated = program_service.update_program(db, test_program.id, update_data)

        assert updated.name == "New Name"
        assert updated.description == "New Description"
        assert updated.difficulty == "medium"
        assert updated.calorie_burn == 300
        assert updated.duration == 45


class TestDeleteProgram:
    """Tests for delete_program function."""

    def test_delete_program_exists(self, db: Session):
        """Test deleting existing program."""
        program = Program(
            name="To Delete",
            description="Test",
            difficulty="easy",
            calorie_burn=200,
            duration=30,
        )
        db.add(program)
        db.commit()
        program_id = program.id

        result = program_service.delete_program(db, program_id)
        assert result is True

        # Verify deletion
        retrieved = db.query(Program).filter(Program.id == program_id).first()
        assert retrieved is None

    def test_delete_program_not_exists(self, db: Session):
        """Test deleting non-existent program."""
        result = program_service.delete_program(db, 99999)
        assert result is False

    def test_delete_program_invalid_id(self, db: Session):
        """Test deleting with invalid ID."""
        result = program_service.delete_program(db, 0)
        assert result is False

    def test_delete_program_persisted(self, db: Session):
        """Test that deletion is persisted."""
        program = Program(
            name="To Delete",
            description="Test",
            difficulty="easy",
            calorie_burn=200,
            duration=30,
        )
        db.add(program)
        db.commit()
        program_id = program.id

        program_service.delete_program(db, program_id)

        count = db.query(Program).filter(Program.id == program_id).count()
        assert count == 0

    def test_delete_program_multiple(self, db: Session):
        """Test deleting multiple programs sequentially."""
        programs = []
        for i in range(3):
            program = Program(
                name=f"Program {i}",
                description="Test",
                difficulty="easy",
                calorie_burn=200,
                duration=30,
            )
            db.add(program)
            db.commit()
            programs.append(program)

        for program in programs:
            result = program_service.delete_program(db, program.id)
            assert result is True

        remaining = db.query(Program).all()
        assert len(remaining) == 0
