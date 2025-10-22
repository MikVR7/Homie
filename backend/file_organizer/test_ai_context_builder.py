#!/usr/bin/env python3
"""
Tests for AIContextBuilder

Run with: python3 backend/file_organizer/test_ai_context_builder.py
"""

import sys
import tempfile
import os
import sqlite3
import uuid
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from backend.file_organizer.ai_context_builder import AIContextBuilder
from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from backend.file_organizer.drive_manager import DriveManager
from backend.file_organizer.migration_runner import run_migrations


def setup_test_db():
    """Create a temporary database with migrations applied"""
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".db")
    db_path = Path(tmp.name)
    tmp.close()
    
    # Apply migrations
    run_migrations(db_path)
    
    return db_path


def setup_test_data(db_path, user_id="test_user", client_id="laptop1"):
    """Setup test data with drives and destinations"""
    dest_manager = DestinationMemoryManager(db_path)
    drive_manager = DriveManager(db_path)
    
    # Register internal drive
    internal_drive_info = {
        'unique_identifier': 'INTERNAL-ROOT',
        'mount_point': '/',
        'volume_label': 'System',
        'drive_type': 'internal'
    }
    internal_drive = drive_manager.register_drive(user_id, internal_drive_info, client_id)
    
    # Register USB drive
    usb_drive_info = {
        'unique_identifier': 'USB-BACKUP-123',
        'mount_point': '/media/usb',
        'volume_label': 'Backup Drive',
        'drive_type': 'usb'
    }
    usb_drive = drive_manager.register_drive(user_id, usb_drive_info, client_id)
    
    # Register OneDrive
    onedrive_info = {
        'unique_identifier': 'ONEDRIVE-user@example.com',
        'mount_point': '/home/user/OneDrive',
        'volume_label': 'OneDrive',
        'drive_type': 'cloud',
        'cloud_provider': 'onedrive'
    }
    onedrive_drive = drive_manager.register_drive(user_id, onedrive_info, client_id)
    
    # Add destinations
    dest1 = dest_manager.add_destination(
        user_id, "/home/user/Videos/Movies", "Movies", client_id, internal_drive.id
    )
    dest_manager.update_usage(dest1.id, 5, "move")
    dest_manager.update_usage(dest1.id, 3, "move")
    
    dest2 = dest_manager.add_destination(
        user_id, "/media/usb/Movies", "Movies", client_id, usb_drive.id
    )
    dest_manager.update_usage(dest2.id, 2, "copy")
    
    dest3 = dest_manager.add_destination(
        user_id, "/home/user/OneDrive/Documents", "Documents", client_id, onedrive_drive.id
    )
    dest_manager.update_usage(dest3.id, 10, "move")
    
    return dest_manager, drive_manager


def test_build_context():
    """Test building context"""
    print("\n=== Test: build_context ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager, drive_manager = setup_test_data(db_path)
        builder = AIContextBuilder(dest_manager, drive_manager)
        
        context = builder.build_context("test_user", "laptop1")
        
        assert 'known_destinations' in context
        assert 'drives' in context
        
        known_destinations = context['known_destinations']
        assert len(known_destinations) > 0, "Should have destinations"
        
        # Check Movies category
        movies_cat = next((c for c in known_destinations if c['category'] == 'Movies'), None)
        assert movies_cat is not None, "Should have Movies category"
        assert len(movies_cat['paths']) == 2, "Should have 2 movie destinations"
        
        # Check paths are sorted by usage
        paths = movies_cat['paths']
        assert paths[0]['usage_count'] >= paths[1]['usage_count'], "Should be sorted by usage"
        
        print(f"✅ Built context with {len(known_destinations)} categories")
        print(f"✅ Movies category has {len(movies_cat['paths'])} destinations")
        
        # Check drives
        drives = context['drives']
        assert len(drives) == 3, f"Should have 3 drives, got {len(drives)}"
        print(f"✅ Context includes {len(drives)} drives")
        
        print("✅ test_build_context passed")
        
    finally:
        os.unlink(db_path)


def test_format_for_ai_prompt():
    """Test formatting context for AI prompt"""
    print("\n=== Test: format_for_ai_prompt ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager, drive_manager = setup_test_data(db_path)
        builder = AIContextBuilder(dest_manager, drive_manager)
        
        context = builder.build_context("test_user", "laptop1")
        formatted = builder.format_for_ai_prompt(context)
        
        assert isinstance(formatted, str), "Should return string"
        assert len(formatted) > 0, "Should not be empty"
        
        # Check for key sections
        assert "KNOWN DESTINATIONS" in formatted
        assert "AVAILABLE DRIVES" in formatted
        assert "INSTRUCTIONS" in formatted
        
        # Check for categories
        assert "Category: Movies" in formatted
        assert "Category: Documents" in formatted
        
        # Check for paths
        assert "/home/user/Videos/Movies" in formatted
        assert "/media/usb/Movies" in formatted
        assert "/home/user/OneDrive/Documents" in formatted
        
        # Check for usage info
        assert "used" in formatted
        assert "time" in formatted
        
        # Check for instructions
        assert "prefer using these known destinations" in formatted
        assert "Drive availability" in formatted
        
        print("✅ Formatted prompt contains all required sections")
        print(f"✅ Prompt length: {len(formatted)} characters")
        
        # Print sample
        print("\n--- Sample Output (first 500 chars) ---")
        print(formatted[:500])
        print("...")
        
        print("\n✅ test_format_for_ai_prompt passed")
        
    finally:
        os.unlink(db_path)


def test_context_with_unavailable_drive():
    """Test context when a drive is unavailable"""
    print("\n=== Test: context_with_unavailable_drive ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager, drive_manager = setup_test_data(db_path)
        
        # Mark USB drive as unavailable
        drive_manager.update_drive_availability(
            "test_user", "USB-BACKUP-123", False, "laptop1"
        )
        
        builder = AIContextBuilder(dest_manager, drive_manager)
        context = builder.build_context("test_user", "laptop1")
        formatted = builder.format_for_ai_prompt(context)
        
        # Check that unavailable drive is marked
        assert "UNAVAILABLE" in formatted or "unavailable" in formatted.lower()
        print("✅ Unavailable drive is marked in context")
        
        print("✅ test_context_with_unavailable_drive passed")
        
    finally:
        os.unlink(db_path)


def test_context_summary():
    """Test building context summary"""
    print("\n=== Test: context_summary ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager, drive_manager = setup_test_data(db_path)
        builder = AIContextBuilder(dest_manager, drive_manager)
        
        summary = builder.build_context_summary("test_user", "laptop1")
        
        assert isinstance(summary, str), "Should return string"
        assert "destination" in summary.lower()
        assert "drive" in summary.lower()
        
        print(f"✅ Summary: {summary}")
        print("✅ test_context_summary passed")
        
    finally:
        os.unlink(db_path)


def test_empty_context():
    """Test context with no destinations or drives"""
    print("\n=== Test: empty_context ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager = DestinationMemoryManager(db_path)
        drive_manager = DriveManager(db_path)
        builder = AIContextBuilder(dest_manager, drive_manager)
        
        context = builder.build_context("empty_user", "laptop1")
        
        assert context['known_destinations'] == []
        assert context['drives'] == []
        
        formatted = builder.format_for_ai_prompt(context)
        assert "No known destinations yet" in formatted
        
        print("✅ Empty context handled correctly")
        print("✅ test_empty_context passed")
        
    finally:
        os.unlink(db_path)


def test_cloud_drive_formatting():
    """Test that cloud drives are formatted correctly"""
    print("\n=== Test: cloud_drive_formatting ===")
    
    db_path = setup_test_db()
    
    try:
        dest_manager, drive_manager = setup_test_data(db_path)
        builder = AIContextBuilder(dest_manager, drive_manager)
        
        context = builder.build_context("test_user", "laptop1")
        formatted = builder.format_for_ai_prompt(context)
        
        # Check OneDrive is mentioned
        assert "OneDrive" in formatted or "onedrive" in formatted.lower()
        assert "Cloud" in formatted
        
        print("✅ Cloud drives formatted correctly")
        print("✅ test_cloud_drive_formatting passed")
        
    finally:
        os.unlink(db_path)


def run_all_tests():
    """Run all tests"""
    print("=" * 60)
    print("Running AIContextBuilder Tests")
    print("=" * 60)
    
    tests = [
        test_build_context,
        test_format_for_ai_prompt,
        test_context_with_unavailable_drive,
        test_context_summary,
        test_empty_context,
        test_cloud_drive_formatting,
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
