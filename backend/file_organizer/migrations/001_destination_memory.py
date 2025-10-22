#!/usr/bin/env python3
"""
Migration 001: Destination Memory System

Creates tables for learning and remembering destination folders:
- destinations: Stores learned destination paths with usage tracking
- drives: Tracks physical/cloud drives for path portability
- destination_usage: Detailed usage history for analytics
"""

import sqlite3
import logging
from pathlib import Path

logger = logging.getLogger("Migration_001")


def get_migration_version() -> int:
    """Returns the version number of this migration"""
    return 1


def apply_migration(conn: sqlite3.Connection) -> None:
    """
    Apply migration to create destination memory tables
    
    Args:
        conn: Active SQLite connection
    """
    logger.info("📦 Applying migration 001: Destination Memory System")
    
    # Create drives table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS drives (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            unique_identifier TEXT NOT NULL,
            mount_point TEXT NOT NULL,
            volume_label TEXT,
            drive_type TEXT NOT NULL,
            cloud_provider TEXT,
            is_available INTEGER DEFAULT 1,
            last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, unique_identifier)
        )
    """)
    logger.info("✅ Created drives table")
    
    # Create destinations table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS destinations (
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
    logger.info("✅ Created destinations table")
    
    # Create destination_usage table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS destination_usage (
            id TEXT PRIMARY KEY,
            destination_id TEXT NOT NULL,
            used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            file_count INTEGER DEFAULT 1,
            operation_type TEXT,
            FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE
        )
    """)
    logger.info("✅ Created destination_usage table")
    
    # Create indexes for performance
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_destinations_user_category 
        ON destinations(user_id, category)
    """)
    
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_destinations_user_active 
        ON destinations(user_id, is_active)
    """)
    
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_drives_user_available 
        ON drives(user_id, is_available)
    """)
    
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_usage_destination 
        ON destination_usage(destination_id)
    """)
    logger.info("✅ Created indexes")
    
    conn.commit()
    logger.info("✅ Migration 001 applied successfully")


def rollback_migration(conn: sqlite3.Connection) -> None:
    """
    Rollback migration by dropping created tables
    
    Args:
        conn: Active SQLite connection
    """
    logger.info("🔄 Rolling back migration 001")
    
    conn.execute("DROP INDEX IF EXISTS idx_usage_destination")
    conn.execute("DROP INDEX IF EXISTS idx_drives_user_available")
    conn.execute("DROP INDEX IF EXISTS idx_destinations_user_active")
    conn.execute("DROP INDEX IF EXISTS idx_destinations_user_category")
    
    conn.execute("DROP TABLE IF EXISTS destination_usage")
    conn.execute("DROP TABLE IF EXISTS destinations")
    conn.execute("DROP TABLE IF EXISTS drives")
    
    conn.commit()
    logger.info("✅ Migration 001 rolled back")


if __name__ == "__main__":
    # Test migration
    import tempfile
    import os
    
    logging.basicConfig(level=logging.INFO)
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
        test_db = tmp.name
    
    try:
        conn = sqlite3.connect(test_db)
        apply_migration(conn)
        
        # Verify tables exist
        cursor = conn.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name IN ('drives', 'destinations', 'destination_usage')
        """)
        tables = [row[0] for row in cursor.fetchall()]
        assert len(tables) == 3, f"Expected 3 tables, found {len(tables)}"
        
        logger.info("✅ Migration test passed")
        
        # Test rollback
        rollback_migration(conn)
        cursor = conn.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name IN ('drives', 'destinations', 'destination_usage')
        """)
        tables = [row[0] for row in cursor.fetchall()]
        assert len(tables) == 0, f"Expected 0 tables after rollback, found {len(tables)}"
        
        logger.info("✅ Rollback test passed")
        
        conn.close()
    finally:
        os.unlink(test_db)
