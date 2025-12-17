#!/usr/bin/env python3
"""
Migration 005: Custom Template System

Adds custom template columns to the user_file_naming_settings table.
These columns store user-defined naming templates with variables.
"""

import logging
import sqlite3
from pathlib import Path

logger = logging.getLogger('Migration005')

def run_migration(db_path: str) -> bool:
    """
    Run migration 005: Add custom template columns
    
    Args:
        db_path: Path to the SQLite database file
        
    Returns:
        True if migration successful, False otherwise
    """
    try:
        logger.info("🔄 Running Migration 005: Custom Template System")
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Add custom template columns
        cursor.execute("ALTER TABLE user_file_naming_settings ADD COLUMN document_custom_template TEXT DEFAULT ''")
        cursor.execute("ALTER TABLE user_file_naming_settings ADD COLUMN image_custom_template TEXT DEFAULT ''")
        cursor.execute("ALTER TABLE user_file_naming_settings ADD COLUMN media_custom_template TEXT DEFAULT ''")
        cursor.execute("ALTER TABLE user_file_naming_settings ADD COLUMN code_custom_template TEXT DEFAULT ''")
        
        conn.commit()
        logger.info("✅ Migration 005 completed successfully")
        
        # Test the migration
        cursor.execute("PRAGMA table_info(user_file_naming_settings)")
        columns = [row[1] for row in cursor.fetchall()]
        
        required_columns = ['document_custom_template', 'image_custom_template', 'media_custom_template', 'code_custom_template']
        missing_columns = [col for col in required_columns if col not in columns]
        
        if missing_columns:
            logger.error(f"❌ Missing columns after migration: {missing_columns}")
            return False
        else:
            logger.info("✅ All custom template columns created successfully")
            
        conn.close()
        return True
        
    except Exception as e:
        logger.error(f"❌ Migration 005 failed: {e}")
        return False

def rollback_migration(db_path: str) -> bool:
    """
    Rollback migration 005: Remove custom template columns
    
    Args:
        db_path: Path to the SQLite database file
        
    Returns:
        True if rollback successful, False otherwise
    """
    try:
        logger.info("🔄 Rolling back Migration 005: Custom Template System")
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # SQLite doesn't support DROP COLUMN, so we need to recreate the table
        # First, get the current data
        cursor.execute("SELECT * FROM user_file_naming_settings")
        rows = cursor.fetchall()
        
        # Get column names (excluding the custom template columns)
        cursor.execute("PRAGMA table_info(user_file_naming_settings)")
        all_columns = cursor.fetchall()
        keep_columns = [col for col in all_columns if not col[1].endswith('_custom_template')]
        
        # Create new table without custom template columns
        cursor.execute("DROP TABLE IF EXISTS user_file_naming_settings_backup")
        
        create_sql = """
            CREATE TABLE user_file_naming_settings_backup (
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
        """
        cursor.execute(create_sql)
        
        # Copy data (excluding custom template columns)
        for row in rows:
            cursor.execute("""
                INSERT INTO user_file_naming_settings_backup 
                (id, user_id, enable_ai_renaming, document_naming, image_naming, media_naming, code_naming,
                 remove_special_chars, remove_spaces, lowercase_extensions, max_filename_length, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, row[:13])  # First 13 columns (before custom templates)
        
        # Replace original table
        cursor.execute("DROP TABLE user_file_naming_settings")
        cursor.execute("ALTER TABLE user_file_naming_settings_backup RENAME TO user_file_naming_settings")
        
        # Recreate index
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_file_naming_settings_user_id 
            ON user_file_naming_settings(user_id)
        """)
        
        conn.commit()
        conn.close()
        
        logger.info("✅ Migration 005 rollback completed")
        return True
        
    except Exception as e:
        logger.error(f"❌ Migration 005 rollback failed: {e}")
        return False

if __name__ == "__main__":
    # Test migration
    test_db = "test_migration_005.db"
    
    # Create base table first (simulate migration 004)
    conn = sqlite3.connect(test_db)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE user_file_naming_settings (
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
    conn.commit()
    conn.close()
    
    print("Testing Migration 005...")
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