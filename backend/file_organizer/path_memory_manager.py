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
import threading # Import threading
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import uuid
import json


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
        self._db_path: Optional[Path] = None
        self._drives_manager = None  # Lazy import to avoid circulars
        self._destination_manager = None  # DestinationMemoryManager
        self._drive_manager = None  # DriveManager (new multi-client version)
        self._started = False
        self._subscriptions: List[str] = []
        self._db_lock = threading.Lock() # Add a lock for thread safety

    async def start(self) -> None:
        if self._started:
            return

        logger.info("🧠 Starting PathMemoryManager…")
        self._setup_database_path() # Renamed to avoid creating connection
        self._create_tables_if_not_exist() # Ensure tables are created on start
        self._run_migrations() # Apply any pending migrations

        # Initialize new managers
        from .destination_memory_manager import DestinationMemoryManager
        from .drive_manager import DriveManager
        
        self._destination_manager = DestinationMemoryManager(self._db_path)
        self._drive_manager = DriveManager(self._db_path)
        logger.info("✅ DestinationMemoryManager and DriveManager initialized")

        # Legacy DrivesManager (for backward compatibility)
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

        self._started = False
        logger.info("✅ PathMemoryManager shut down")

    def _get_db_connection(self):
        """Creates and returns a new database connection."""
        if not self._db_path:
            raise RuntimeError("Database path not configured.")
        # check_same_thread=False is a pragmatic solution for gevent/asyncio
        conn = sqlite3.connect(str(self._db_path), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn

    def _setup_database_path(self) -> None:
        """Sets up the database path without creating a connection."""
        data_dir = os.getenv("HOMIE_DATA_DIR", str(Path(__file__).resolve().parents[1] / "data"))
        modules_dir = Path(data_dir) / "modules"
        modules_dir.mkdir(parents=True, exist_ok=True)
        self._db_path = modules_dir / "homie_file_organizer.db"
        logger.info(f"📦 PathMemoryManager DB path set to {self._db_path}")

    def _run_migrations(self) -> None:
        """Run database migrations"""
        try:
            from .migration_runner import run_migrations
            applied = run_migrations(self._db_path)
            if applied > 0:
                logger.info(f"✅ Applied {applied} database migration(s)")
        except Exception as e:
            logger.error(f"❌ Migration error: {e}")
            # Don't fail startup on migration errors for now
    
    def _create_tables_if_not_exist(self) -> None:
        """Connects to the database and creates tables if they don't exist."""
        with self._get_db_connection() as conn:
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
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS analysis_sessions (
                    analysis_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    source_path TEXT NOT NULL,
                    destination_path TEXT,
                    organization_style TEXT,
                    file_count INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status TEXT DEFAULT 'active',
                    metadata TEXT
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS analysis_operations (
                    operation_id TEXT PRIMARY KEY,
                    analysis_id TEXT NOT NULL,
                    operation_type TEXT NOT NULL,
                    source_path TEXT,
                    destination_path TEXT,
                    file_name TEXT NOT NULL,
                    operation_status TEXT DEFAULT 'pending',
                    applied_at TIMESTAMP NULL,
                    reverted_at TIMESTAMP NULL,
                    metadata TEXT,
                    FOREIGN KEY (analysis_id) REFERENCES analysis_sessions (analysis_id)
                )
                """
            )
            conn.execute("CREATE INDEX IF NOT EXISTS idx_analysis_sessions_user_id ON analysis_sessions(user_id)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_analysis_operations_analysis_id ON analysis_operations(analysis_id)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_analysis_operations_status ON analysis_operations(operation_status)")
            
            # Phase 5: User history tracking for smart suggestions
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS file_organization_history (
                    id INTEGER PRIMARY KEY,
                    user_id TEXT,
                    source_file_path TEXT,
                    destination_path TEXT,
                    content_type TEXT,
                    company TEXT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    file_extension TEXT
                )
                """
            )
            conn.execute("CREATE INDEX IF NOT EXISTS idx_file_org_history_user_id ON file_organization_history(user_id)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_file_org_history_content_type ON file_organization_history(content_type)")
        
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
        timestamp = datetime.now().isoformat()
        with self._get_db_connection() as conn:
            conn.execute(
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
        with self._get_db_connection() as conn:
            cursor = conn.execute(
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
        summary: Dict[str, Any] = {
            "folder_path": folder_path,
            "total_actions": 0,
            "success_count": 0,
            "failure_count": 0,
            "last_activity": None,
            "actions_by_type": {},
            "top_destinations": [],
        }

        with self._get_db_connection() as conn:
            # Totals and last activity
            row = conn.execute(
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
            cur = conn.execute(
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
            cur = conn.execute(
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

    def create_analysis_session(self, user_id: str, source_path: str, destination_path: str, organization_style: str, file_count: int, operations: List[Dict]) -> Dict:
        analysis_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        session_data = {
            "analysis_id": analysis_id,
            "user_id": user_id,
            "source_path": source_path,
            "destination_path": destination_path,
            "organization_style": organization_style,
            "file_count": file_count,
            "created_at": now,
            "updated_at": now,
            "status": "active",
            "metadata": "{}"
        }

        with self._get_db_connection() as conn:
            conn.execute(
                """
                INSERT INTO analysis_sessions (analysis_id, user_id, source_path, destination_path, organization_style, file_count, created_at, updated_at, status, metadata)
                VALUES (:analysis_id, :user_id, :source_path, :destination_path, :organization_style, :file_count, :created_at, :updated_at, :status, :metadata)
                """,
                session_data
            )

            ops_to_insert = []
            for op in operations:
                ops_to_insert.append({
                    "operation_id": str(uuid.uuid4()),
                    "analysis_id": analysis_id,
                    "operation_type": op.get("type"),
                    "source_path": op.get("source"),
                    "destination_path": op.get("destination"),
                    "file_name": Path(op.get("source", "")).name,
                    "operation_status": "pending",
                    "metadata": json.dumps({"reason": op.get("reason")})
                })
            
            conn.executemany(
                """
                INSERT INTO analysis_operations (operation_id, analysis_id, operation_type, source_path, destination_path, file_name, operation_status, metadata)
                VALUES (:operation_id, :analysis_id, :operation_type, :source_path, :destination_path, :file_name, :operation_status, :metadata)
                """,
                ops_to_insert
            )
            
            # Fetch the created operations to return them with their new IDs
            cursor = conn.execute(
                "SELECT * FROM analysis_operations WHERE analysis_id = ?", (analysis_id,)
            )
            created_ops = [dict(row) for row in cursor.fetchall()]

        return {"analysis": session_data, "operations": created_ops}

    def get_analysis_sessions_for_user(self, user_id: str, limit: int = 50) -> List[Dict]:
        with self._get_db_connection() as conn:
            cursor = conn.execute(
                """
                SELECT
                s.analysis_id, s.source_path, s.destination_path, s.organization_style,
                s.file_count, s.created_at, s.status,
                COUNT(CASE WHEN o.operation_status = 'pending' THEN 1 END) AS pending_operations,
                COUNT(CASE WHEN o.operation_status = 'applied' THEN 1 END) AS applied_operations,
                COUNT(CASE WHEN o.operation_status = 'ignored' THEN 1 END) AS ignored_operations
            FROM analysis_sessions s
            LEFT JOIN analysis_operations o ON s.analysis_id = o.analysis_id
            WHERE s.user_id = ?
            GROUP BY s.analysis_id
            ORDER BY s.created_at DESC
            LIMIT ?
            """,
                (user_id, limit)
            )
            return [dict(row) for row in cursor.fetchall()]

    def get_analysis_with_operations(self, user_id: str, analysis_id: str) -> Optional[Dict]:
        with self._get_db_connection() as conn:
            cursor = conn.execute(
                "SELECT * FROM analysis_sessions WHERE analysis_id = ? AND user_id = ?",
                (analysis_id, user_id)
            )
            session = cursor.fetchone()
            if not session:
                return None

            cursor = conn.execute(
                "SELECT * FROM analysis_operations WHERE analysis_id = ?",
                (analysis_id,)
            )
            operations = [dict(row) for row in cursor.fetchall()]
        
        return {"analysis": dict(session), "operations": operations}

    def update_operation_status(self, user_id: str, operation_id: str, status: str, timestamp: str) -> Optional[Dict]:
        status_field_map = {
            "applied": "applied_at",
            "reverted": "reverted_at"
        }
        time_field = status_field_map.get(status)

        with self._get_db_connection() as conn:
            # Check if operation exists and belongs to the user
            cursor = conn.execute(
                """
                SELECT o.operation_id FROM analysis_operations o
                JOIN analysis_sessions s ON o.analysis_id = s.analysis_id
                WHERE o.operation_id = ? AND s.user_id = ?
                """,
                (operation_id, user_id)
            )
            if not cursor.fetchone():
                return None

            sql = "UPDATE analysis_operations SET operation_status = ?"
            params = [status]
            if time_field:
                sql += f", {time_field} = ?"
                params.append(timestamp)
            
            sql += " WHERE operation_id = ?"
            params.append(operation_id)

            conn.execute(sql, tuple(params))

            cursor = conn.execute("SELECT * FROM analysis_operations WHERE operation_id = ?", (operation_id,))
            return dict(cursor.fetchone())

    def batch_update_operation_status(self, user_id: str, operation_ids: List[str], status: str, timestamp: str) -> List[Dict]:
        updated_ops = []
        with self._get_db_connection() as conn: # This can be optimized, but let's keep it simple for now
            for op_id in operation_ids:
                # This is inefficient but ensures user ownership for each op.
                # A better way would be a single query with a sub-select.
                
                # We need to pass the connection to the single update function
                updated_op = self._update_operation_status_with_conn(conn, user_id, op_id, status, timestamp)
                if updated_op:
                    updated_ops.append(updated_op)
        return updated_ops

    def _update_operation_status_with_conn(self, conn: sqlite3.Connection, user_id: str, operation_id: str, status: str, timestamp: str) -> Optional[Dict]:
        """Helper for batch updates that reuses a connection."""
        status_field_map = {
            "applied": "applied_at",
            "reverted": "reverted_at"
        }
        time_field = status_field_map.get(status)

        # Check if operation exists and belongs to the user
        cursor = conn.execute(
            """
            SELECT o.operation_id FROM analysis_operations o
            JOIN analysis_sessions s ON o.analysis_id = s.analysis_id
            WHERE o.operation_id = ? AND s.user_id = ?
            """,
            (operation_id, user_id)
        )
        if not cursor.fetchone():
            return None

        sql = "UPDATE analysis_operations SET operation_status = ?"
        params = [status]
        if time_field:
            sql += f", {time_field} = ?"
            params.append(timestamp)
        
        sql += " WHERE operation_id = ?"
        params.append(operation_id)

        conn.execute(sql, tuple(params))

        cursor = conn.execute("SELECT * FROM analysis_operations WHERE operation_id = ?", (operation_id,))
        return dict(cursor.fetchone())

    def get_all_destination_paths(self):
        with self._get_db_connection() as conn:
            cursor = conn.execute("SELECT DISTINCT destination_path FROM destination_mappings ORDER BY last_used DESC")
            return [row[0] for row in cursor.fetchall()]

    def remove_destination_path(self, path: str) -> bool:
        """Removes a destination path mapping from the database."""
        with self._get_db_connection() as conn:
            cursor = conn.execute(
                "DELETE FROM destination_mappings WHERE destination_path = ?",
                (path,)
            )
            return cursor.rowcount > 0
    
    def record_organization_history(self, user_id: str, source_file_path: str, destination_path: str, 
                                   content_type: Optional[str] = None, company: Optional[str] = None) -> None:
        """Record a file organization action for smart suggestions."""
        from pathlib import Path
        file_extension = Path(source_file_path).suffix.lower()
        
        with self._get_db_connection() as conn:
            conn.execute(
                """
                INSERT INTO file_organization_history 
                (user_id, source_file_path, destination_path, content_type, company, file_extension)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (user_id, source_file_path, destination_path, content_type, company, file_extension)
            )
    
    def get_destination_suggestions(self, user_id: str, content_type: Optional[str] = None, 
                                   company: Optional[str] = None, file_extension: Optional[str] = None) -> List[Dict]:
        """Get destination suggestions based on user history."""
        with self._get_db_connection() as conn:
            suggestions = []
            
            # Query 1: Exact match on content_type and company
            if content_type and company:
                cursor = conn.execute(
                    """
                    SELECT destination_path, COUNT(*) as usage_count
                    FROM file_organization_history
                    WHERE user_id = ? AND content_type = ? AND company = ?
                    GROUP BY destination_path
                    ORDER BY usage_count DESC
                    LIMIT 3
                    """,
                    (user_id, content_type, company)
                )
                for row in cursor.fetchall():
                    suggestions.append({
                        'destination_path': row[0],
                        'confidence_score': 0.95,
                        'reason': f'{content_type} from {company} - you previously organized similar files here',
                        'is_based_on_history': True,
                        'usage_count': row[1]
                    })
            
            # Query 2: Match on content_type only
            if content_type and len(suggestions) < 3:
                cursor = conn.execute(
                    """
                    SELECT destination_path, COUNT(*) as usage_count
                    FROM file_organization_history
                    WHERE user_id = ? AND content_type = ?
                    GROUP BY destination_path
                    ORDER BY usage_count DESC
                    LIMIT 3
                    """,
                    (user_id, content_type)
                )
                for row in cursor.fetchall():
                    if row[0] not in [s['destination_path'] for s in suggestions]:
                        suggestions.append({
                            'destination_path': row[0],
                            'confidence_score': 0.80,
                            'reason': f'{content_type} files - based on your history',
                            'is_based_on_history': True,
                            'usage_count': row[1]
                        })
            
            # Query 3: Match on file extension
            if file_extension and len(suggestions) < 3:
                cursor = conn.execute(
                    """
                    SELECT destination_path, COUNT(*) as usage_count
                    FROM file_organization_history
                    WHERE user_id = ? AND file_extension = ?
                    GROUP BY destination_path
                    ORDER BY usage_count DESC
                    LIMIT 2
                    """,
                    (user_id, file_extension)
                )
                for row in cursor.fetchall():
                    if row[0] not in [s['destination_path'] for s in suggestions]:
                        suggestions.append({
                            'destination_path': row[0],
                            'confidence_score': 0.70,
                            'reason': f'{file_extension} files - based on your history',
                            'is_based_on_history': True,
                            'usage_count': row[1]
                        })
            
            return suggestions[:3]  # Return top 3 suggestions


