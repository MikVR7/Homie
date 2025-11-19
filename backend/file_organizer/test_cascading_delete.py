#!/usr/bin/env python3
"""
Test script for cascading delete functionality in DestinationMemoryManager
"""

import os
import sys
import tempfile
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from file_organizer.destination_memory_manager import DestinationMemoryManager
from file_organizer.migration_runner import run_migrations


def setup_test_db():
    """Create a temporary database with migrations applied"""
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".db")
    db_path = Path(tmp.name)
    tmp.close()
    
    # Apply migrations
    run_migrations(db_path)
    
    return db_path


def test_cascading_delete():
    """Test that deleting a parent destination also deactivates child destinations"""
    print("\n=== Test: Cascading Delete ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager = DestinationMemoryManager(db_path)
        user_id = "test_user"
        client_id = "laptop1"
        
        # Create a parent destination
        parent = dest_manager.add_destination(
            user_id=user_id,
            path="/home/user/Videos",
            category="Videos",
            client_id=client_id
        )
        print(f"✓ Created parent destination: {parent.path}")
        
        # Create child destinations
        child1 = dest_manager.add_destination(
            user_id=user_id,
            path="/home/user/Videos/Movies",
            category="Movies",
            client_id=client_id
        )
        print(f"✓ Created child destination 1: {child1.path}")
        
        child2 = dest_manager.add_destination(
            user_id=user_id,
            path="/home/user/Videos/TV Shows",
            category="TV Shows",
            client_id=client_id
        )
        print(f"✓ Created child destination 2: {child2.path}")
        
        child3 = dest_manager.add_destination(
            user_id=user_id,
            path="/home/user/Videos/Movies/Action",
            category="Action",
            client_id=client_id
        )
        print(f"✓ Created nested child destination: {child3.path}")
        
        # Create an unrelated destination
        unrelated = dest_manager.add_destination(
            user_id=user_id,
            path="/home/user/Documents",
            category="Documents",
            client_id=client_id
        )
        print(f"✓ Created unrelated destination: {unrelated.path}")
        
        # Verify all are active
        all_destinations = dest_manager.get_destinations(user_id)
        active_count = len([d for d in all_destinations if d.is_active])
        print(f"\n✓ Total active destinations before delete: {active_count}")
        assert active_count == 5, f"Expected 5 active destinations, got {active_count}"
        
        # Delete the parent destination
        print(f"\n🗑️  Deleting parent destination: {parent.path}")
        success = dest_manager.remove_destination(user_id, parent.id)
        assert success, "Failed to delete parent destination"
        print("✓ Parent destination deleted successfully")
        
        # Verify cascading delete
        active_destinations = dest_manager.get_destinations(user_id)
        active_count = len(active_destinations)
        print(f"\n✓ Total active destinations after delete: {active_count}")
        
        # Should only have the unrelated destination active
        assert active_count == 1, f"Expected 1 active destination, got {active_count}"
        
        active_paths = [d.path for d in active_destinations]
        print(f"✓ Active destinations: {active_paths}")
        assert unrelated.path in active_paths, "Unrelated destination should still be active"
        
        # Verify parent and children are inactive by querying the database directly
        with dest_manager._get_db_connection() as conn:
            cursor = conn.execute("""
                SELECT path FROM destinations 
                WHERE user_id = ? AND is_active = 0
                ORDER BY path
            """, (user_id,))
            inactive_paths = [row['path'] for row in cursor.fetchall()]
        
        print(f"✓ Inactive destinations: {inactive_paths}")
        
        expected_inactive = [parent.path, child1.path, child2.path, child3.path]
        for path in expected_inactive:
            assert path in inactive_paths, f"Expected {path} to be inactive"
        
        print("\n✅ Cascading delete test PASSED!")
        
    finally:
        os.unlink(db_path)


def test_cascading_delete_with_tmp():
    """Test cascading delete with /tmp paths (similar to the user's issue)"""
    print("\n=== Test: Cascading Delete with /tmp paths ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager = DestinationMemoryManager(db_path)
        user_id = "dev_user"
        client_id = "default_client"
        
        # Create destinations similar to the user's issue
        parent = dest_manager.add_destination(
            user_id=user_id,
            path="/tmp/Videos",
            category="Videos",
            client_id=client_id
        )
        
        child1 = dest_manager.add_destination(
            user_id=user_id,
            path="/tmp/Videos/Images",
            category="Images",
            client_id=client_id
        )
        
        child2 = dest_manager.add_destination(
            user_id=user_id,
            path="/tmp/Videos/Documents",
            category="Documents",
            client_id=client_id
        )
        
        child3 = dest_manager.add_destination(
            user_id=user_id,
            path="/tmp/Videos/Software",
            category="Software",
            client_id=client_id
        )
        
        print(f"✓ Created parent: {parent.path}")
        print(f"✓ Created children: {child1.path}, {child2.path}, {child3.path}")
        
        # Verify all are active
        all_destinations = dest_manager.get_destinations(user_id)
        active_count = len([d for d in all_destinations if d.is_active])
        print(f"\n✓ Total active destinations: {active_count}")
        assert active_count == 4
        
        # Delete the parent
        print(f"\n🗑️  Deleting parent: {parent.path}")
        success = dest_manager.remove_destination(user_id, parent.id)
        assert success
        
        # Verify all are now inactive
        active_destinations = dest_manager.get_destinations(user_id)
        active_count = len(active_destinations)
        print(f"✓ Active destinations after delete: {active_count}")
        assert active_count == 0, f"Expected 0 active destinations, got {active_count}"
        
        print("\n✅ /tmp cascading delete test PASSED!")
        
    finally:
        os.unlink(db_path)


if __name__ == "__main__":
    test_cascading_delete()
    test_cascading_delete_with_tmp()
    print("\n🎉 All tests passed!")
