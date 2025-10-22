#!/usr/bin/env python3
"""
Migration Runner for File Organizer Database

Manages database schema versioning and applies migrations in order.
"""

import sqlite3
import logging
import importlib
from pathlib import Path
from typing import List, Tuple

logger = logging.getLogger("MigrationRunner")


class MigrationRunner:
    """Handles database migrations for the File Organizer module"""
    
    def __init__(self, db_path: Path):
        """
        Initialize migration runner
        
        Args:
            db_path: Path to the SQLite database file
        """
        self.db_path = db_path
        self.migrations_dir = Path(__file__).parent / "migrations"
    
    def _get_db_connection(self) -> sqlite3.Connection:
        """Create database connection with row factory"""
        conn = sqlite3.connect(str(self.db_path), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn
    
    def _ensure_migration_table(self, conn: sqlite3.Connection) -> None:
        """Create migrations tracking table if it doesn't exist"""
        conn.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                migration_name TEXT NOT NULL
            )
        """)
        conn.commit()
    
    def _get_current_version(self, conn: sqlite3.Connection) -> int:
        """Get the current schema version"""
        cursor = conn.execute(
            "SELECT MAX(version) as version FROM schema_migrations"
        )
        row = cursor.fetchone()
        return row['version'] if row['version'] is not None else 0
    
    def _get_available_migrations(self) -> List[Tuple[int, str, object]]:
        """
        Discover available migration files
        
        Returns:
            List of tuples: (version, name, module)
        """
        migrations = []
        
        if not self.migrations_dir.exists():
            logger.warning(f"Migrations directory not found: {self.migrations_dir}")
            return migrations
        
        for migration_file in sorted(self.migrations_dir.glob("*.py")):
            if migration_file.name.startswith("__"):
                continue
            
            # Try multiple import strategies
            module = None
            module_name = f"backend.file_organizer.migrations.{migration_file.stem}"
            
            try:
                # Try standard import first
                module = importlib.import_module(module_name)
            except ModuleNotFoundError:
                # Try relative import
                try:
                    import sys
                    sys.path.insert(0, str(self.migrations_dir.parent.parent.parent))
                    module = importlib.import_module(module_name)
                except Exception as e2:
                    logger.error(f"Failed to load migration {migration_file}: {e2}")
                    continue
            except Exception as e:
                logger.error(f"Failed to load migration {migration_file}: {e}")
                continue
            
            if module:
                try:
                    version = module.get_migration_version()
                    migrations.append((version, migration_file.stem, module))
                except Exception as e:
                    logger.error(f"Failed to get version from {migration_file}: {e}")
        
        return sorted(migrations, key=lambda x: x[0])
    
    def apply_migrations(self) -> int:
        """
        Apply all pending migrations
        
        Returns:
            Number of migrations applied
        """
        conn = self._get_db_connection()
        
        try:
            self._ensure_migration_table(conn)
            current_version = self._get_current_version(conn)
            available_migrations = self._get_available_migrations()
            
            applied_count = 0
            
            for version, name, module in available_migrations:
                if version <= current_version:
                    continue
                
                logger.info(f"📦 Applying migration {version}: {name}")
                
                try:
                    # Apply migration
                    module.apply_migration(conn)
                    
                    # Record migration
                    conn.execute(
                        "INSERT INTO schema_migrations (version, migration_name) VALUES (?, ?)",
                        (version, name)
                    )
                    conn.commit()
                    
                    applied_count += 1
                    logger.info(f"✅ Migration {version} applied successfully")
                    
                except Exception as e:
                    logger.error(f"❌ Failed to apply migration {version}: {e}")
                    conn.rollback()
                    raise
            
            if applied_count == 0:
                logger.info("✅ Database schema is up to date")
            else:
                logger.info(f"✅ Applied {applied_count} migration(s)")
            
            return applied_count
            
        finally:
            conn.close()
    
    def get_migration_status(self) -> dict:
        """
        Get current migration status
        
        Returns:
            Dictionary with version info and pending migrations
        """
        conn = self._get_db_connection()
        
        try:
            self._ensure_migration_table(conn)
            current_version = self._get_current_version(conn)
            available_migrations = self._get_available_migrations()
            
            applied = []
            pending = []
            
            for version, name, _ in available_migrations:
                if version <= current_version:
                    applied.append({"version": version, "name": name})
                else:
                    pending.append({"version": version, "name": name})
            
            return {
                "current_version": current_version,
                "applied_migrations": applied,
                "pending_migrations": pending
            }
            
        finally:
            conn.close()


def run_migrations(db_path: Path) -> int:
    """
    Convenience function to run migrations
    
    Args:
        db_path: Path to database file
        
    Returns:
        Number of migrations applied
    """
    runner = MigrationRunner(db_path)
    return runner.apply_migrations()


if __name__ == "__main__":
    # Test migration runner
    import tempfile
    import os
    
    logging.basicConfig(level=logging.INFO)
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
        test_db = Path(tmp.name)
    
    try:
        logger.info(f"Testing migrations on {test_db}")
        
        runner = MigrationRunner(test_db)
        
        # Check status before
        status = runner.get_migration_status()
        logger.info(f"Initial status: {status}")
        
        # Apply migrations
        count = runner.apply_migrations()
        logger.info(f"Applied {count} migrations")
        
        # Check status after
        status = runner.get_migration_status()
        logger.info(f"Final status: {status}")
        
        # Try applying again (should be no-op)
        count = runner.apply_migrations()
        assert count == 0, "Expected no migrations on second run"
        
        logger.info("✅ Migration runner test passed")
        
    finally:
        if test_db.exists():
            os.unlink(test_db)
