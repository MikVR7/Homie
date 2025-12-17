#!/usr/bin/env python3
"""
Migration 004: User File Naming Settings

Creates table for storing user-specific file naming preferences.
These settings control how AI renames files during organization.
"""

import logging
import sqlite3
from pathlib import Path

logger = logging.getLogger('Migration004')

def run_migration(db_path: str) -> bool:
    """
    Run migration 004: Create user_file_naming_settings table
    
    Args:
        db_path: Path to the SQLite database file
        
    Returns:
        True if migration successful, False otherwise
    """
    try:
        logger.info("🔄 Running Migration 004: User File Naming Settings")
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Create user_file_naming_settings table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_file_naming_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                enable_ai_renaming BOOLEAN DEFAULT TRUE,
                document_naming TEXT DEFAULT 'KeepOriginal',
                image_naming TEXT DEFAULT 'KeepOriginal',
                media_naming TEXT DEFAULT 'KeepOriginal',
                code_naming TEXT DEFAULT 'KeepOriginal',
                remove_special_chars BOOLEAN DEFAULT TRUE,
                remove_spaces BOOLEAN DEFAULT FALSE,
                lowercase_extensions BOOLEAN DEFAULT TRUE,
                max_filename_length INTEGER DEFAULT 100,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id)
            )
        """)
        
        # Create index for fast user lookups
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_file_naming_settings_user_id 
            ON user_file_naming_settings(user_id)
        """)
        
        conn.commit()
        logger.info("✅ Migration 004 completed successfully")
        
        # Test the migration
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='user_file_naming_settings'")
        if cursor.fetchone():
            logger.info("✅ Table user_file_naming_settings created successfully")
        else:
            logger.error("❌ Table creation failed")
            return False
            
        conn.close()
        return True
        
    except Exception as e:
        logger.error(f"❌ Migration 004 failed: {e}")
        return False

def rollback_migration(db_path: str) -> bool:
    """
    Rollback migration 004: Drop user_file_naming_settings table
    
    Args:
        db_path: Path to the SQLite database file
        
    Returns:
        True if rollback successful, False otherwise
    """
    try:
        logger.info("🔄 Rolling back Migration 004: User File Naming Settings")
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Drop the table
        cursor.execute("DROP TABLE IF EXISTS user_file_naming_settings")
        
        conn.commit()
        conn.close()
        
        logger.info("✅ Migration 004 rollback completed")
        return True
        
    except Exception as e:
        logger.error(f"❌ Migration 004 rollback failed: {e}")
        return False

if __name__ == "__main__":
    # Test migration
    test_db = "test_migration_004.db"
    
    print("Testing Migration 004...")
    success = run_migration(test_db)
    
    if success:
        print("✅ Migration test passed")
        
        # Test rollback
        print("Testing rollback...")
        rollback_success = rollback_migration(test_db)
        
        if rollback_success:
            print("✅ Rollback test passed")
        else:
            print("❌ Rollback test failed")
    else:
        print("❌ Migration test failed")
    
    # Cleanup
    Path(test_db).unlink(missing_ok=True)