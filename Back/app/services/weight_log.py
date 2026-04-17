import datetime
from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import insert

from app.models.user import WeightLog


def add_weight_entry(
    db: Session,
    user_id: int,
    weight: float,
    source: str = "manual",
    date: datetime.date | None = None,
) -> WeightLog:
    """Insère ou met à jour l'entrée de poids pour un jour donné (upsert)."""
    entry_date = date or datetime.date.today()

    stmt = (
        insert(WeightLog)
        .values(user_id=user_id, date=entry_date, weight=weight, source=source)
        .on_conflict_do_update(
            constraint="uq_weight_log_user_date",
            set_={"weight": weight, "source": source},
        )
        .returning(WeightLog)
    )
    result = db.execute(stmt)
    db.commit()
    return result.scalar_one()


def get_weight_history(db: Session, user_id: int) -> list[dict]:
    """
    Retourne la série complète de poids depuis la première entrée jusqu'à aujourd'hui.
    Les jours sans entrée réelle sont comblés par carry-forward (valeur du jour précédent).
    Les jours AVANT la première entrée ne sont pas générés.
    """
    real_entries = (
        db.query(WeightLog)
        .filter(WeightLog.user_id == user_id)
        .order_by(WeightLog.date)
        .all()
    )

    if not real_entries:
        return []

    # Index des entrées réelles par date pour accès O(1)
    real_by_date = {e.date: e for e in real_entries}

    first_date = real_entries[0].date
    today = datetime.date.today()

    result = []
    last_weight = None

    current = first_date
    while current <= today:
        if current in real_by_date:
            entry = real_by_date[current]
            last_weight = entry.weight
            result.append({
                "date": current,
                "weight": last_weight,
                "source": entry.source,
            })
        else:
            # Carry-forward : on propage le dernier poids connu
            result.append({
                "date": current,
                "weight": last_weight,
                "source": "carried_forward",
            })
        current += datetime.timedelta(days=1)

    return result
