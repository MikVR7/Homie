#!/usr/bin/env python3
"""
Test: Destination Reactivation

Verifies that destinations are properly reactivated when re-added after soft deletion.
This test addresses the regression where POST returned is_active=false and GET returned empty list.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from pathlib import Path
import tempfile
import sqlite3
from backend.file_organizer.destination_memory_manager import DestinationMemoryManager


def test_destination_reactivation():
    """Test that soft-deleted destinations are reactivated when re-added"""
    
    # Create temporary database
    with tempfile.NamedTemporaryFile(delete=False, suffix='.db') as tmp:
        test_db = Path(tmp.name)
    
    try:
        # Create tables
        conn = sqlite3.connect(str(test_db))
        conn.execute("""
            CREATE TABLE destinations (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                path TEXT NOT NULL,
                category TEXT NOT NULL,
                drive_id TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_used_at TIMESTAMP,
                usage_count INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1,
                UNIQUE(user_id, path)
            )
        """)
        conn.execute("""
            CREATE TABLE drives (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                unique_identifier TEXT NOT NULL,
                mount_point TEXT NOT NULL,
                volume_label TEXT,
                drive_type TEXT NOT NULL,
                cloud_provider TEXT,
                is_available INTEGER DEFAULT 1,
                last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.execute("""
            CREATE TABLE drive_client_mounts (
                id TEXT PRIMARY KEY,
                drive_id TEXT NOT NULL,
                client_id TEXT NOT NULL,
                mount_point TEXT NOT NULL,
                last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_available INTEGER DEFAULT 1
            )
        """)
        conn.commit()
        conn.close()
        
        # Initialize manager
        manager = DestinationMemoryManager(test_db)
        
        # Test 1: Add new destination
        print("Test 1: Add new destination")
        dest1 = manager.add_destination(
            user_id='test_user',
            path='/test/path',
            category='TestCategory',
            client_id='test_client',
            drive_id=None
        )
        assert dest1 is not None, "Failed to create destination"
        assert dest1.is_active == True, f"Expected is_active=True, got {dest1.is_active}"
        assert dest1.path == '/test/path', f"Expected path='/test/path', got {dest1.path}"
        assert dest1.category == 'TestCategory', f"Expected category='TestCategory', got {dest1.category}"
        print(f"  ✓ Created destination: id={dest1.id}, is_active={dest1.is_active}")
        
        # Test 2: Verify it shows in get_destinations
        print("\nTest 2: Verify destination appears in get_destinations")
        destinations = manager.get_destinations('test_user')
        assert len(destinations) == 1, f"Expected 1 destination, got {len(destinations)}"
        assert destinations[0].id == dest1.id, "Destination ID mismatch"
        print(f"  ✓ Found {len(destinations)} destination(s)")
        
        # Test 3: Soft delete the destination
        print("\nTest 3: Soft delete destination")
        success = manager.remove_destination('test_user', dest1.id)
        assert success == True, "Failed to remove destination"
        print(f"  ✓ Removed destination {dest1.id}")
        
        # Test 4: Verify it doesn't show in get_destinations
        print("\nTest 4: Verify destination doesn't appear after deletion")
        destinations = manager.get_destinations('test_user')
        assert len(destinations) == 0, f"Expected 0 destinations, got {len(destinations)}"
        print(f"  ✓ Found {len(destinations)} destination(s) (correctly filtered out inactive)")
        
        # Test 5: Re-add the same destination (should reactivate)
        print("\nTest 5: Re-add deleted destination (should reactivate)")
        dest2 = manager.add_destination(
            user_id='test_user',
            path='/test/path',
            category='TestCategory',
            client_id='test_client',
            drive_id=None
        )
        assert dest2 is not None, "Failed to reactivate destination"
        assert dest2.id == dest1.id, f"Expected same ID {dest1.id}, got {dest2.id}"
        assert dest2.is_active == True, f"Expected is_active=True after reactivation, got {dest2.is_active}"
        assert dest2.path == '/test/path', f"Expected path='/test/path', got {dest2.path}"
        assert dest2.category == 'TestCategory', f"Expected category='TestCategory', got {dest2.category}"
        print(f"  ✓ Reactivated destination: id={dest2.id}, is_active={dest2.is_active}")
        
        # Test 6: Verify it shows in get_destinations again
        print("\nTest 6: Verify reactivated destination appears in get_destinations")
        destinations = manager.get_destinations('test_user')
        assert len(destinations) == 1, f"Expected 1 destination, got {len(destinations)}"
        assert destinations[0].id == dest1.id, "Destination ID mismatch"
        assert destinations[0].is_active == True, "Destination should be active"
        print(f"  ✓ Found {len(destinations)} destination(s)")
        
        print("\n✅ All tests passed!")
        return True
        
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        if test_db.exists():
            os.unlink(test_db)


if __name__ == '__main__':
    success = test_destination_reactivation()
    sys.exit(0 if success else 1)
