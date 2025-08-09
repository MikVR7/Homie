#!/usr/bin/env python3
"""
PathMemoryManager

Central memory and analytics for the File Organizer module.

Responsibilities:
- Owns DrivesManager (composition) because every path lives on a drive
- Provides simple APIs for recording and retrieving folder usage history
- Persists data to the module-specific SQLite database
- Emits and listens to events via EventBus
"""

from __future__ import annotations

import asyncio
import logging
import os
import sqlite3
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


logger = logging.getLogger("PathMemoryManager")


@dataclass
class FolderUsageRecord:
    folder_path: str
    action_type: str
    file_name: Optional[str]
    destination_path: Optional[str]
    success: Optional[bool]
    error_message: Optional[str]
    timestamp: datetime


class PathMemoryManager:
    """Centralized path memory and analytics with drive ownership."""

    def __init__(self, event_bus, shared_services):
        self.event_bus = event_bus
        self.shared_services = shared_services
        self._db_connection: Optional[sqlite3.Connection] = None
        self._db_path: Optional[Path] = None
        self._drives_manager = None  # Lazy import to avoid circulars
        self._started = False

    async def start(self) -> None:
        if self._started:
            return

        logger.info("🧠 Starting PathMemoryManager…")
        self._setup_database()

        from .drives_manager import DrivesManager

        self._drives_manager = DrivesManager(event_bus=self.event_bus)
        await self._drives_manager.start()

        self._started = True
        logger.info("✅ PathMemoryManager started")

    async def shutdown(self) -> None:
        if not self._started:
            return

        logger.info("🛑 Shutting down PathMemoryManager…")

        if self._drives_manager:
            await self._drives_manager.shutdown()

        if self._db_connection:
            try:
                self._db_connection.close()
            except Exception as e:
                logger.warning(f"Database close warning: {e}")
            self._db_connection = None

        self._started = False
        logger.info("✅ PathMemoryManager shut down")

    def _setup_database(self) -> None:
        data_dir = os.getenv("HOMIE_DATA_DIR", str(Path(__file__).resolve().parents[1] / "data"))
        modules_dir = Path(data_dir) / "modules"
        modules_dir.mkdir(parents=True, exist_ok=True)
        self._db_path = modules_dir / "homie_file_organizer.db"

        conn = sqlite3.connect(str(self._db_path))
        conn.row_factory = sqlite3.Row

        with conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS file_actions (
                    id INTEGER PRIMARY KEY,
                    user_id TEXT,
                    action_type TEXT NOT NULL,
                    file_name TEXT,
                    source_path TEXT,
                    destination_path TEXT,
                    success INTEGER,
                    error_message TEXT,
                    timestamp TEXT DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS destination_mappings (
                    id INTEGER PRIMARY KEY,
                    user_id TEXT,
                    file_category TEXT NOT NULL,
                    destination_path TEXT NOT NULL,
                    drive_info TEXT,
                    confidence_score REAL DEFAULT 0.5,
                    usage_count INTEGER DEFAULT 1,
                    last_used TEXT DEFAULT CURRENT_TIMESTAMP,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        self._db_connection = conn
        logger.info(f"📦 PathMemoryManager DB ready at {self._db_path}")

    def record_folder_usage(
        self,
        folder_path: str,
        action_type: str,
        file_name: Optional[str] = None,
        destination_path: Optional[str] = None,
        success: Optional[bool] = None,
        error_message: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> None:
        if not self._db_connection:
            raise RuntimeError("PathMemoryManager database not initialized")

        timestamp = datetime.now().isoformat()
        with self._db_connection:
            self._db_connection.execute(
                """
                INSERT INTO file_actions (user_id, action_type, file_name, source_path, destination_path, success, error_message, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    user_id,
                    action_type,
                    file_name,
                    folder_path,
                    destination_path,
                    1 if success else (0 if success is not None else None),
                    error_message,
                    timestamp,
                ),
            )

    def get_folder_history(self, folder_path: str, limit: int = 50) -> List[FolderUsageRecord]:
        if not self._db_connection:
            raise RuntimeError("PathMemoryManager database not initialized")

        cursor = self._db_connection.execute(
            """
            SELECT file_name, action_type, destination_path, success, error_message, timestamp
            FROM file_actions
            WHERE source_path = ?
            ORDER BY timestamp DESC
            LIMIT ?
            """,
            (folder_path, limit),
        )

        rows = cursor.fetchall()
        history: List[FolderUsageRecord] = []
        for row in rows:
            history.append(
                FolderUsageRecord(
                    folder_path=folder_path,
                    action_type=row["action_type"],
                    file_name=row["file_name"],
                    destination_path=row["destination_path"],
                    success=bool(row["success"]) if row["success"] is not None else None,
                    error_message=row["error_message"],
                    timestamp=datetime.fromisoformat(row["timestamp"]),
                )
            )
        return history

    async def get_drive_status(self) -> Dict:
        if not self._drives_manager:
            return {"drives": []}
        return await self._drives_manager.get_status()

    async def health_check(self) -> Dict[str, str]:
        return {
            "status": "healthy" if self._started else "stopped",
            "db_path": str(self._db_path) if self._db_path else "",
        }


