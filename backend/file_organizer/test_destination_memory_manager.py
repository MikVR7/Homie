#!/usr/bin/env python3
"""
Tests for DestinationMemoryManager

Run with: python3 backend/file_organizer/test_destination_memory_manager.py
"""

import sys
import tempfile
import os
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from backend.file_organizer.migration_runner import run_migrations


def setup_test_db():
    """Create a temporary database with migrations applied"""
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".db")
    db_path = Path(tmp.name)
    tmp.close()
    
    # Apply migrations
    run_migrations(db_path)
    
    return db_path


def test_add_destination():
    """Test adding destinations"""
    print("\n=== Test: add_destination ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Add a destination
        dest = manager.add_destination(
            user_id="test_user",
            path="/home/user/Documents/Invoices",
            category="invoice"
        )
        
        assert dest is not None, "Destination should be created"
        assert dest.path == str(Path("/home/user/Documents/Invoices").resolve())
        assert dest.category == "invoice"
        assert dest.usage_count == 0
        assert dest.is_active == True
        print(f"✅ Created destination: {dest.path}")
        
        # Try adding duplicate
        dest2 = manager.add_destination(
            user_id="test_user",
            path="/home/user/Documents/Invoices",
            category="invoice"
        )
        
        assert dest2.id == dest.id, "Should return existing destination"
        print(f"✅ Duplicate handling works")
        
        print("✅ test_add_destination passed")
        
    finally:
        os.unlink(db_path)


def test_get_destinations():
    """Test retrieving destinations"""
    print("\n=== Test: get_destinations ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Add multiple destinations
        manager.add_destination("test_user", "/home/user/Documents/Invoices", "invoice")
        manager.add_destination("test_user", "/home/user/Documents/Receipts", "receipt")
        manager.add_destination("test_user", "/home/user/Videos/Movies", "movie")
        
        # Get all destinations
        destinations = manager.get_destinations("test_user")
        
        assert len(destinations) == 3, f"Expected 3 destinations, got {len(destinations)}"
        print(f"✅ Retrieved {len(destinations)} destinations")
        
        # Verify they're all active
        for dest in destinations:
            assert dest.is_active == True
            print(f"  - {dest.path} ({dest.category})")
        
        print("✅ test_get_destinations passed")
        
    finally:
        os.unlink(db_path)


def test_remove_destination():
    """Test removing (soft delete) destinations"""
    print("\n=== Test: remove_destination ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Add a destination
        dest = manager.add_destination("test_user", "/home/user/Documents/Test", "test")
        
        # Remove it
        result = manager.remove_destination("test_user", dest.id)
        assert result == True, "Remove should succeed"
        print(f"✅ Removed destination: {dest.id}")
        
        # Verify it's not in active list
        destinations = manager.get_destinations("test_user")
        assert len(destinations) == 0, "Should have no active destinations"
        print(f"✅ Destination is inactive")
        
        # Try removing non-existent
        result = manager.remove_destination("test_user", "fake-id")
        assert result == False, "Should return False for non-existent"
        print(f"✅ Non-existent handling works")
        
        print("✅ test_remove_destination passed")
        
    finally:
        os.unlink(db_path)


def test_get_destinations_by_category():
    """Test filtering destinations by category"""
    print("\n=== Test: get_destinations_by_category ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Add destinations with different categories
        manager.add_destination("test_user", "/home/user/Documents/Invoices", "invoice")
        manager.add_destination("test_user", "/home/user/Documents/Invoices/2024", "invoice")
        manager.add_destination("test_user", "/home/user/Documents/Receipts", "receipt")
        
        # Get invoices
        invoices = manager.get_destinations_by_category("test_user", "invoice")
        assert len(invoices) == 2, f"Expected 2 invoices, got {len(invoices)}"
        print(f"✅ Retrieved {len(invoices)} invoice destinations")
        
        # Test case-insensitive
        invoices2 = manager.get_destinations_by_category("test_user", "INVOICE")
        assert len(invoices2) == 2, "Case-insensitive should work"
        print(f"✅ Case-insensitive matching works")
        
        print("✅ test_get_destinations_by_category passed")
        
    finally:
        os.unlink(db_path)


def test_extract_category_from_path():
    """Test category extraction from paths"""
    print("\n=== Test: extract_category_from_path ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        test_cases = [
            ("/home/user/Videos/Movies", "Movies"),
            ("/home/user/Documents/Work/Projects", "Projects"),
            ("/home/user/Documents/", "Documents"),
            ("/home/user/my_folder", "My Folder"),
            ("/home/user/test-folder", "Test Folder"),
            ("", "Uncategorized"),
        ]
        
        for path, expected in test_cases:
            result = manager.extract_category_from_path(path)
            assert result == expected, f"Expected '{expected}', got '{result}' for path '{path}'"
            print(f"✅ {path} -> {result}")
        
        print("✅ test_extract_category_from_path passed")
        
    finally:
        os.unlink(db_path)


def test_auto_capture_destinations():
    """Test auto-capturing destinations from operations"""
    print("\n=== Test: auto_capture_destinations ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Simulate file operations
        operations = [
            {"type": "move", "src": "/tmp/file1.pdf", "dest": "/home/user/Documents/Invoices/file1.pdf"},
            {"type": "move", "src": "/tmp/file2.pdf", "dest": "/home/user/Documents/Invoices/file2.pdf"},
            {"type": "copy", "src": "/tmp/file3.jpg", "dest": "/home/user/Pictures/Vacation/file3.jpg"},
        ]
        
        # Auto-capture
        captured = manager.auto_capture_destinations("test_user", operations)
        
        assert len(captured) == 2, f"Expected 2 unique destinations, got {len(captured)}"
        print(f"✅ Captured {len(captured)} destinations")
        
        for dest in captured:
            print(f"  - {dest.path} ({dest.category})")
        
        # Verify they're in the database
        all_destinations = manager.get_destinations("test_user")
        assert len(all_destinations) == 2
        print(f"✅ Destinations saved to database")
        
        # Run again with same operations (should not create duplicates)
        captured2 = manager.auto_capture_destinations("test_user", operations)
        assert len(captured2) == 0, "Should not capture duplicates"
        print(f"✅ Duplicate prevention works")
        
        print("✅ test_auto_capture_destinations passed")
        
    finally:
        os.unlink(db_path)


def test_update_usage():
    """Test updating destination usage"""
    print("\n=== Test: update_usage ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Add a destination
        dest = manager.add_destination("test_user", "/home/user/Documents/Test", "test")
        assert dest.usage_count == 0
        print(f"✅ Initial usage_count: {dest.usage_count}")
        
        # Update usage
        result = manager.update_usage(dest.id, file_count=5, operation_type="move")
        assert result == True
        print(f"✅ Updated usage")
        
        # Verify update
        destinations = manager.get_destinations("test_user")
        assert len(destinations) == 1
        updated_dest = destinations[0]
        assert updated_dest.usage_count == 1, f"Expected usage_count=1, got {updated_dest.usage_count}"
        assert updated_dest.last_used_at is not None
        print(f"✅ Usage count incremented: {updated_dest.usage_count}")
        
        # Update again
        manager.update_usage(dest.id, file_count=3, operation_type="copy")
        destinations = manager.get_destinations("test_user")
        updated_dest = destinations[0]
        assert updated_dest.usage_count == 2
        print(f"✅ Usage count incremented again: {updated_dest.usage_count}")
        
        print("✅ test_update_usage passed")
        
    finally:
        os.unlink(db_path)


def test_get_usage_analytics():
    """Test usage analytics"""
    print("\n=== Test: get_usage_analytics ===")
    
    db_path = setup_test_db()
    manager = DestinationMemoryManager(db_path)
    
    try:
        # Add destinations and update usage
        dest1 = manager.add_destination("test_user", "/home/user/Documents/Invoices", "invoice")
        manager.update_usage(dest1.id, 5, "move")
        manager.update_usage(dest1.id, 3, "move")
        
        dest2 = manager.add_destination("test_user", "/home/user/Documents/Receipts", "receipt")
        manager.update_usage(dest2.id, 10, "copy")
        
        dest3 = manager.add_destination("test_user", "/home/user/Videos/Movies", "movie")
        manager.update_usage(dest3.id, 2, "move")
        
        # Get analytics
        analytics = manager.get_usage_analytics("test_user")
        
        assert 'overall' in analytics
        assert 'by_category' in analytics
        assert 'most_used' in analytics
        
        overall = analytics['overall']
        assert overall['total_destinations'] == 3
        assert overall['total_categories'] == 3
        assert overall['total_uses'] == 4  # 2 + 1 + 1
        print(f"✅ Overall stats: {overall}")
        
        by_category = analytics['by_category']
        assert len(by_category) == 3
        print(f"✅ By category: {len(by_category)} categories")
        
        most_used = analytics['most_used']
        assert len(most_used) == 3
        assert most_used[0]['usage_count'] == 2  # dest1 used twice
        print(f"✅ Most used: {most_used[0]['path']}")
        
        print("✅ test_get_usage_analytics passed")
        
    finally:
        os.unlink(db_path)


def run_all_tests():
    """Run all tests"""
    print("=" * 60)
    print("Running DestinationMemoryManager Tests")
    print("=" * 60)
    
    tests = [
        test_add_destination,
        test_get_destinations,
        test_remove_destination,
        test_get_destinations_by_category,
        test_extract_category_from_path,
        test_auto_capture_destinations,
        test_update_usage,
        test_get_usage_analytics,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"❌ {test.__name__} failed: {e}")
            failed += 1
        except Exception as e:
            print(f"❌ {test.__name__} error: {e}")
            import traceback
            traceback.print_exc()
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"Test Results: {passed} passed, {failed} failed")
    print("=" * 60)
    
    return failed == 0


if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.WARNING)
    
    success = run_all_tests()
    sys.exit(0 if success else 1)
