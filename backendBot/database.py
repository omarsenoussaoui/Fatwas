import sqlite3
import os
from datetime import datetime
from config import DB_PATH


def _get_connection() -> sqlite3.Connection:
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Create the transcriptions table if it doesn't exist."""
    conn = _get_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS transcriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            username TEXT,
            first_name TEXT,
            file_name TEXT,
            duration INTEGER DEFAULT 0,
            transcription TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()


def save_transcription(
    user_id: int,
    username: str | None,
    first_name: str | None,
    file_name: str | None,
    duration: int,
    transcription: str,
):
    """Save a completed transcription to the database."""
    conn = _get_connection()
    conn.execute(
        """
        INSERT INTO transcriptions (user_id, username, first_name, file_name, duration, transcription, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (user_id, username, first_name, file_name, duration, transcription, datetime.now().isoformat()),
    )
    conn.commit()
    conn.close()


def get_history(user_id: int, limit: int = 10) -> list[dict]:
    """Get the last N transcriptions for a user."""
    conn = _get_connection()
    rows = conn.execute(
        """
        SELECT file_name, duration, transcription, created_at
        FROM transcriptions
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT ?
        """,
        (user_id, limit),
    ).fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_user_stats(user_id: int) -> dict:
    """Get transcription statistics for a user."""
    conn = _get_connection()
    row = conn.execute(
        """
        SELECT
            COUNT(*) as total_count,
            COALESCE(SUM(duration), 0) as total_duration,
            COALESCE(SUM(LENGTH(transcription)), 0) as total_chars
        FROM transcriptions
        WHERE user_id = ?
        """,
        (user_id,),
    ).fetchone()
    conn.close()
    return dict(row) if row else {"total_count": 0, "total_duration": 0, "total_chars": 0}


def get_global_stats() -> dict:
    """Get global bot statistics."""
    conn = _get_connection()
    row = conn.execute(
        """
        SELECT
            COUNT(*) as total_count,
            COUNT(DISTINCT user_id) as total_users,
            COALESCE(SUM(duration), 0) as total_duration
        FROM transcriptions
        """
    ).fetchone()
    conn.close()
    return dict(row) if row else {"total_count": 0, "total_users": 0, "total_duration": 0}
