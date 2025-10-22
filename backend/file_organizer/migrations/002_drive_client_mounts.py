#!/usr/bin/env python3
"""
Migration 002: Drive Client Mounts

Adds per-client mount point tracking for drives.

CONTEXT:
- Multiple frontend clients (laptops) may report the same drive
- Same USB drive may have different mount points on different clients
- Same OneDrive may be mounted on 3 different laptops with different local paths

This migration:
1. Creates drive_client_mounts table to track mount points per client
2. Migrates existing mount_point data from drives table
3. Maintains backward compatibility
"""

import sqlite3
import logging
import uuid
from datetime import datetime

logger = logging.getLogger("Migration_002")


def get_migration_version() -> int:
    """Returns the version number of this migration"""
    return 2


def apply_migration(conn: sqlite3.Connection) -> None:
    """
    Apply migration to add per-client mount tracking
    
    Args:
        conn: Active SQLite connection
    """
    logger.info("📦 Applying migration 002: Drive Client Mounts")
    
    # Create drive_client_mounts table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS drive_client_mounts (
            id TEXT PRIMARY KEY,
            drive_id TEXT NOT NULL,
            client_id TEXT NOT NULL,
            mount_point TEXT NOT NULL,
            last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_available INTEGER DEFAULT 1,
            FOREIGN KEY (drive_id) REFERENCES drives(id) ON DELETE CASCADE,
            UNIQUE(drive_id, client_id)
        )
    """)
    logger.info("✅ Created drive_client_mounts table")
    
    # Create indexes
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_drive_mounts_drive 
        ON drive_client_mounts(drive_id)
    """)
    
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_drive_mounts_client 
        ON drive_client_mounts(client_id)
    """)
    logger.info("✅ Created indexes")
    
    # Migrate existing data from drives table
    logger.info("🔄 Migrating existing mount point data...")
    
    # Check if drives table has mount_point column
    cursor = conn.execute("PRAGMA table_info(drives)")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'mount_point' in columns:
        # Get all drives with mount points
        cursor = conn.execute("""
            SELECT id, mount_point, is_available, last_seen_at
            FROM drives
            WHERE mount_point IS NOT NULL AND mount_point != ''
        """)
        
        drives_to_migrate = cursor.fetchall()
        migrated_count = 0
        
        for drive_row in drives_to_migrate:
            drive_id = drive_row[0]
            mount_point = drive_row[1]
            is_available = drive_row[2]
            last_seen_at = drive_row[3]
            
            # Use 'unknown' as default client_id for existing data
            # In production, you might want to use a specific client_id if available
            client_id = 'legacy_client'
            
            # Create mount entry
            mount_id = str(uuid.uuid4())
            
            try:
                conn.execute("""
                    INSERT INTO drive_client_mounts 
                    (id, drive_id, client_id, mount_point, last_seen_at, is_available)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (mount_id, drive_id, client_id, mount_point, last_seen_at, is_available))
                migrated_count += 1
            except sqlite3.IntegrityError:
                # Already exists, skip
                logger.debug(f"Mount entry already exists for drive {drive_id}")
        
        logger.info(f"✅ Migrated {migrated_count} mount point(s)")
    else:
        logger.info("ℹ️  No mount_point column found in drives table (already migrated or fresh install)")
    
    conn.commit()
    logger.info("✅ Migration 002 applied successfully")


def rollback_migration(conn: sqlite3.Connection) -> None:
    """
    Rollback migration by dropping created table and indexes
    
    Args:
        conn: Active SQLite connection
    """
    logger.info("🔄 Rolling back migration 002")
    
    conn.execute("DROP INDEX IF EXISTS idx_drive_mounts_client")
    conn.execute("DROP INDEX IF EXISTS idx_drive_mounts_drive")
    conn.execute("DROP TABLE IF EXISTS drive_client_mounts")
    
    conn.commit()
    logger.info("✅ Migration 002 rolled back")


if __name__ == "__main__":
    # Test migration
    import tempfile
    import os
    
    logging.basicConfig(level=logging.INFO)
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
        test_db = tmp.name
    
    try:
        conn = sqlite3.connect(test_db)
        
        # First apply migration 001 to create drives table
        logger.info("Setting up test database with migration 001...")
        import sys
        from pathlib import Path
        migration_001_path = Path(__file__).parent / "001_destination_memory.py"
        
        # Load migration 001 dynamically
        import importlib.util
        spec = importlib.util.spec_from_file_location("migration_001", migration_001_path)
        m001 = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m001)
        m001.apply_migration(conn)
        
        # Add some test drives
        logger.info("Adding test drives...")
        conn.execute("""
            INSERT INTO drives (id, user_id, unique_identifier, mount_point, volume_label, drive_type, is_available, last_seen_at, created_at)
            VALUES 
                ('drive-1', 'user1', 'USB-123', '/media/usb', 'My USB', 'usb', 1, '2024-01-01 12:00:00', '2024-01-01 12:00:00'),
                ('drive-2', 'user1', 'ONEDRIVE-456', '/home/user/OneDrive', 'OneDrive', 'cloud', 1, '2024-01-01 12:00:00', '2024-01-01 12:00:00')
        """)
        conn.commit()
        
        # Apply migration 002
        logger.info("\nApplying migration 002...")
        apply_migration(conn)
        
        # Verify tables exist
        cursor = conn.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='drive_client_mounts'
        """)
        tables = [row[0] for row in cursor.fetchall()]
        assert 'drive_client_mounts' in tables, "drive_client_mounts table not created"
        logger.info("✅ Table exists")
        
        # Verify indexes exist
        cursor = conn.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='index' AND name LIKE 'idx_drive_mounts_%'
        """)
        indexes = [row[0] for row in cursor.fetchall()]
        assert len(indexes) == 2, f"Expected 2 indexes, found {len(indexes)}"
        logger.info("✅ Indexes exist")
        
        # Verify data migration
        cursor = conn.execute("SELECT COUNT(*) FROM drive_client_mounts")
        count = cursor.fetchone()[0]
        assert count == 2, f"Expected 2 migrated mounts, found {count}"
        logger.info(f"✅ Data migrated: {count} mount points")
        
        # Verify mount data
        cursor = conn.execute("""
            SELECT drive_id, client_id, mount_point 
            FROM drive_client_mounts 
            ORDER BY drive_id
        """)
        mounts = cursor.fetchall()
        assert mounts[0][1] == 'legacy_client', "Client ID should be 'legacy_client'"
        assert mounts[0][2] == '/media/usb', "Mount point should match"
        logger.info("✅ Mount data correct")
        
        logger.info("\n✅ Migration 002 test passed")
        
        # Test rollback
        logger.info("\nTesting rollback...")
        rollback_migration(conn)
        cursor = conn.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='drive_client_mounts'
        """)
        tables = [row[0] for row in cursor.fetchall()]
        assert len(tables) == 0, "Table should be dropped"
        logger.info("✅ Rollback test passed")
        
        conn.close()
    finally:
        os.unlink(test_db)
