#!/usr/bin/env python3
"""
Migration 003: Destination Colors

Adds color field to destinations table for visual identification in the frontend.
"""

import sqlite3
import logging
from pathlib import Path

logger = logging.getLogger("Migration_003")


def get_migration_version() -> int:
    """Returns the version number of this migration"""
    return 3


def apply_migration(conn: sqlite3.Connection) -> None:
    """
    Apply migration to add color column to destinations table
    
    Args:
        conn: Active SQLite connection
    """
    logger.info("📦 Applying migration 003: Destination Colors")
    
    # Add color column to destinations table
    try:
        conn.execute("""
            ALTER TABLE destinations 
            ADD COLUMN color TEXT
        """)
        logger.info("✅ Added color column to destinations table")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e).lower():
            logger.info("⚠️  Color column already exists, skipping")
        else:
            raise
    
    conn.commit()
    logger.info("✅ Migration 003 applied successfully")


def rollback_migration(conn: sqlite3.Connection) -> None:
    """
    Rollback migration by removing color column
    
    Note: SQLite doesn't support DROP COLUMN directly, so we need to:
    1. Create new table without color column
    2. Copy data
    3. Drop old table
    4. Rename new table
    
    Args:
        conn: Active SQLite connection
    """
    logger.info("🔄 Rolling back migration 003")
    
    # Check if color column exists
    cursor = conn.execute("PRAGMA table_info(destinations)")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'color' not in columns:
        logger.info("⚠️  Color column doesn't exist, nothing to rollback")
        return
    
    # Create new table without color column
    conn.execute("""
        CREATE TABLE destinations_new (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            path TEXT NOT NULL,
            category TEXT NOT NULL,
            drive_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_used_at TIMESTAMP,
            usage_count INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            UNIQUE(user_id, path),
            FOREIGN KEY (drive_id) REFERENCES drives(id) ON DELETE SET NULL
        )
    """)
    
    # Copy data (excluding color)
    conn.execute("""
        INSERT INTO destinations_new 
        (id, user_id, path, category, drive_id, created_at, last_used_at, usage_count, is_active)
        SELECT id, user_id, path, category, drive_id, created_at, last_used_at, usage_count, is_active
        FROM destinations
    """)
    
    # Drop old table
    conn.execute("DROP TABLE destinations")
    
    # Rename new table
    conn.execute("ALTER TABLE destinations_new RENAME TO destinations")
    
    # Recreate indexes
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_destinations_user_category 
        ON destinations(user_id, category)
    """)
    
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_destinations_user_active 
        ON destinations(user_id, is_active)
    """)
    
    conn.commit()
    logger.info("✅ Migration 003 rolled back")


if __name__ == "__main__":
    # Test migration
    import tempfile
    import os
    
    logging.basicConfig(level=logging.INFO)
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
        test_db = tmp.name
    
    try:
        conn = sqlite3.connect(test_db)
        
        # First apply migration 001 to create base tables
        from backend.file_organizer.migrations.migration_001_destination_memory import apply_migration as apply_001
        apply_001(conn)
        
        # Apply this migration
        apply_migration(conn)
        
        # Verify color column exists
        cursor = conn.execute("PRAGMA table_info(destinations)")
        columns = [row[1] for row in cursor.fetchall()]
        assert 'color' in columns, "Color column not found"
        logger.info("✅ Migration test passed")
        
        # Test rollback
        rollback_migration(conn)
        cursor = conn.execute("PRAGMA table_info(destinations)")
        columns = [row[1] for row in cursor.fetchall()]
        assert 'color' not in columns, "Color column still exists after rollback"
        logger.info("✅ Rollback test passed")
        
        conn.close()
    finally:
        os.unlink(test_db)
