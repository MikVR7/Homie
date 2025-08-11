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
from typing import Dict, List, Optional, Tuple, Any


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
        self._subscriptions: List[str] = []

    async def start(self) -> None:
        if self._started:
            return

        logger.info("🧠 Starting PathMemoryManager…")
        self._setup_database()

        from .drives_manager import DrivesManager

        self._drives_manager = DrivesManager(event_bus=self.event_bus)
        await self._drives_manager.start()

        # Subscribe to operation results to persist history
        try:
            self._subscriptions.append(
                self.event_bus.subscribe(
                    "operation_done", self._on_operation_done, "PathMemoryManager"
                )
            )
            self._subscriptions.append(
                self.event_bus.subscribe(
                    "operation_failed", self._on_operation_failed, "PathMemoryManager"
                )
            )
        except Exception as e:
            logger.warning(f"Subscription warning: {e}")

        self._started = True
        logger.info("✅ PathMemoryManager started")

    async def shutdown(self) -> None:
        if not self._started:
            return

        logger.info("🛑 Shutting down PathMemoryManager…")

        if self._drives_manager:
            await self._drives_manager.shutdown()

        # Unsubscribe
        try:
            self.event_bus.unsubscribe_component("PathMemoryManager")
        except Exception:
            pass

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

    async def _on_operation_done(self, data: Dict[str, Any]):
        """Persist results from executed operations."""
        try:
            results = (data or {}).get("results", [])
            for item in results:
                op = item.get("operation", {})
                success = bool(item.get("success", False))
                error_message = item.get("error")
                op_type = op.get("type", "unknown")

                # Derive paths
                source_path = None
                destination_path = None
                file_name = None

                if op_type in ("move", "copy", "rename"):
                    src = op.get("src")
                    dest = op.get("dest")
                    source_path = src
                    destination_path = dest
                    try:
                        file_name = Path(src).name if src else None
                    except Exception:
                        file_name = src
                elif op_type == "delete":
                    path = op.get("path")
                    source_path = path
                    try:
                        file_name = Path(path).name if path else None
                    except Exception:
                        file_name = path
                elif op_type in ("mkdir", "check_exists", "list_dir"):
                    path = op.get("path")
                    source_path = path
                    try:
                        file_name = Path(path).name if path else None
                    except Exception:
                        file_name = path

                # Record
                try:
                    self.record_folder_usage(
                        folder_path=source_path or "",
                        action_type=op_type,
                        file_name=file_name,
                        destination_path=destination_path,
                        success=success,
                        error_message=error_message,
                    )
                except Exception as e:
                    logger.warning(f"Failed to record operation history: {e}")
        except Exception as e:
            logger.warning(f"operation_done handler error: {e}")

    async def _on_operation_failed(self, data: Dict[str, Any]):
        try:
            op = (data or {}).get("operation", {})
            await self._on_operation_done({
                "results": [{"operation": op, "success": False, "error": (data or {}).get("error")}] 
            })
        except Exception:
            pass

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

    def get_folder_summary(self, folder_path: str) -> Dict[str, Any]:
        if not self._db_connection:
            raise RuntimeError("PathMemoryManager database not initialized")

        summary: Dict[str, Any] = {
            "folder_path": folder_path,
            "total_actions": 0,
            "success_count": 0,
            "failure_count": 0,
            "last_activity": None,
            "actions_by_type": {},
            "top_destinations": [],
        }

        # Totals and last activity
        row = self._db_connection.execute(
            """
            SELECT COUNT(*) AS total,
                   SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) AS success_count,
                   SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS failure_count,
                   MAX(timestamp) AS last_ts
            FROM file_actions
            WHERE source_path = ?
            """,
            (folder_path,),
        ).fetchone()

        if row:
            summary["total_actions"] = int(row["total"] or 0)
            summary["success_count"] = int(row["success_count"] or 0)
            summary["failure_count"] = int(row["failure_count"] or 0)
            summary["last_activity"] = row["last_ts"]

        # Actions by type
        cur = self._db_connection.execute(
            """
            SELECT action_type, COUNT(*) AS cnt
            FROM file_actions
            WHERE source_path = ?
            GROUP BY action_type
            ORDER BY cnt DESC
            """,
            (folder_path,),
        )
        summary["actions_by_type"] = {r["action_type"]: int(r["cnt"]) for r in cur.fetchall()}

        # Top destinations
        cur = self._db_connection.execute(
            """
            SELECT destination_path, COUNT(*) AS cnt
            FROM file_actions
            WHERE source_path = ? AND destination_path IS NOT NULL AND destination_path <> ''
            GROUP BY destination_path
            ORDER BY cnt DESC
            LIMIT 10
            """,
            (folder_path,),
        )
        summary["top_destinations"] = [
            {"destination_path": r["destination_path"], "count": int(r["cnt"])} for r in cur.fetchall()
        ]

        return summary

    async def get_drive_status(self) -> Dict:
        if not self._drives_manager:
            return {"drives": []}
        return await self._drives_manager.get_status()

    async def health_check(self) -> Dict[str, str]:
        return {
            "status": "healthy" if self._started else "stopped",
            "db_path": str(self._db_path) if self._db_path else "",
        }


