#!/usr/bin/env python3
"""
Tests for DriveManager

Run with: python3 backend/file_organizer/test_drive_manager.py
"""

import sys
import tempfile
import os
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

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


def test_register_new_drive():
    """Test registering a new drive"""
    print("\n=== Test: register_new_drive ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # Register a USB drive from laptop1
        drive_info = {
            'unique_identifier': 'USB-SERIAL-12345',
            'mount_point': '/media/usb',
            'volume_label': 'My USB Drive',
            'drive_type': 'usb'
        }
        
        drive = manager.register_drive("test_user", drive_info, "laptop1")
        
        assert drive is not None, "Drive should be created"
        assert drive.unique_identifier == 'USB-SERIAL-12345'
        assert drive.drive_type == 'usb'
        assert drive.is_available == True
        assert len(drive.client_mounts) == 1
        assert drive.client_mounts[0].client_id == "laptop1"
        assert drive.client_mounts[0].mount_point == "/media/usb"
        
        print(f"✅ Created drive: {drive.volume_label} ({drive.unique_identifier})")
        print(f"✅ Mount on laptop1: {drive.client_mounts[0].mount_point}")
        print("✅ test_register_new_drive passed")
        
    finally:
        os.unlink(db_path)


def test_usb_mobility_between_laptops():
    """Test USB drive moving between laptops"""
    print("\n=== Test: usb_mobility_between_laptops ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # Step 1: USB plugged into laptop1
        drive_info = {
            'unique_identifier': 'USB-BACKUP-789',
            'mount_point': '/media/usb',
            'volume_label': 'Backup Drive',
            'drive_type': 'usb'
        }
        
        drive1 = manager.register_drive("test_user", drive_info, "laptop1")
        assert drive1 is not None
        print(f"✅ Step 1: USB registered on laptop1 at {drive1.mount_point}")
        
        # Step 2: USB unplugged from laptop1
        success = manager.update_drive_availability("test_user", 'USB-BACKUP-789', False, "laptop1")
        assert success == True
        print(f"✅ Step 2: USB marked unavailable on laptop1")
        
        # Step 3: USB plugged into laptop2 (different mount point)
        drive_info2 = {
            'unique_identifier': 'USB-BACKUP-789',  # Same identifier!
            'mount_point': '/mnt/usb',  # Different mount point
            'volume_label': 'Backup Drive',
            'drive_type': 'usb'
        }
        
        drive2 = manager.register_drive("test_user", drive_info2, "laptop2")
        assert drive2 is not None
        assert drive2.id == drive1.id, "Should be the SAME drive"
        assert len(drive2.client_mounts) == 2, "Should have 2 mounts (laptop1 and laptop2)"
        print(f"✅ Step 3: Same USB recognized on laptop2 at /mnt/usb")
        print(f"✅ Drive ID unchanged: {drive2.id}")
        
        # Verify mounts
        laptop1_mount = next((m for m in drive2.client_mounts if m.client_id == "laptop1"), None)
        laptop2_mount = next((m for m in drive2.client_mounts if m.client_id == "laptop2"), None)
        
        assert laptop1_mount is not None
        assert laptop2_mount is not None
        assert laptop1_mount.is_available == False
        assert laptop2_mount.is_available == True
        print(f"✅ laptop1 mount: {laptop1_mount.mount_point} (unavailable)")
        print(f"✅ laptop2 mount: {laptop2_mount.mount_point} (available)")
        
        print("✅ test_usb_mobility_between_laptops passed")
        
    finally:
        os.unlink(db_path)


def test_shared_cloud_storage():
    """Test shared cloud storage across multiple laptops"""
    print("\n=== Test: shared_cloud_storage ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # OneDrive account ID as unique identifier
        onedrive_id = 'ONEDRIVE-user@example.com'
        
        # Laptop1 reports OneDrive
        drive_info1 = {
            'unique_identifier': onedrive_id,
            'mount_point': '/home/user1/OneDrive',
            'volume_label': 'OneDrive',
            'drive_type': 'cloud',
            'cloud_provider': 'onedrive'
        }
        
        drive1 = manager.register_drive("test_user", drive_info1, "laptop1")
        assert drive1 is not None
        print(f"✅ OneDrive registered on laptop1: {drive_info1['mount_point']}")
        
        # Laptop2 reports same OneDrive (different mount point)
        drive_info2 = {
            'unique_identifier': onedrive_id,  # Same account!
            'mount_point': '/Users/user/OneDrive',  # Different path
            'volume_label': 'OneDrive',
            'drive_type': 'cloud',
            'cloud_provider': 'onedrive'
        }
        
        drive2 = manager.register_drive("test_user", drive_info2, "laptop2")
        assert drive2 is not None
        assert drive2.id == drive1.id, "Should be the SAME OneDrive"
        print(f"✅ Same OneDrive recognized on laptop2: {drive_info2['mount_point']}")
        
        # Laptop3 reports same OneDrive
        drive_info3 = {
            'unique_identifier': onedrive_id,
            'mount_point': 'C:\\Users\\user\\OneDrive',
            'volume_label': 'OneDrive',
            'drive_type': 'cloud',
            'cloud_provider': 'onedrive'
        }
        
        drive3 = manager.register_drive("test_user", drive_info3, "laptop3")
        assert drive3 is not None
        assert drive3.id == drive1.id, "Should be the SAME OneDrive"
        assert len(drive3.client_mounts) == 3, "Should have 3 mounts"
        print(f"✅ Same OneDrive recognized on laptop3: {drive_info3['mount_point']}")
        
        # Get shared cloud drives
        cloud_drives = manager.get_shared_cloud_drives("test_user", "onedrive")
        assert len(cloud_drives) == 1, "Should be 1 OneDrive (deduplicated)"
        assert len(cloud_drives[0].client_mounts) == 3, "With 3 client mounts"
        print(f"✅ get_shared_cloud_drives returned 1 OneDrive with 3 mounts")
        
        print("✅ test_shared_cloud_storage passed")
        
    finally:
        os.unlink(db_path)


def test_match_drive_by_identifier():
    """Test matching drives by unique identifier"""
    print("\n=== Test: match_drive_by_identifier ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # Register a drive
        drive_info = {
            'unique_identifier': 'USB-TEST-999',
            'mount_point': '/media/test',
            'volume_label': 'Test Drive',
            'drive_type': 'usb'
        }
        
        original_drive = manager.register_drive("test_user", drive_info, "laptop1")
        assert original_drive is not None
        
        # Match by identifier
        matched_drive = manager.match_drive_by_identifier("test_user", 'USB-TEST-999')
        assert matched_drive is not None
        assert matched_drive.id == original_drive.id
        print(f"✅ Matched drive by identifier: {matched_drive.unique_identifier}")
        
        # Try non-existent identifier
        no_match = manager.match_drive_by_identifier("test_user", 'NON-EXISTENT')
        assert no_match is None
        print(f"✅ Non-existent identifier returns None")
        
        print("✅ test_match_drive_by_identifier passed")
        
    finally:
        os.unlink(db_path)


def test_get_drive_for_path():
    """Test getting drive for a specific path"""
    print("\n=== Test: get_drive_for_path ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # Register USB drive on laptop1
        drive_info = {
            'unique_identifier': 'USB-PATH-TEST',
            'mount_point': '/media/usb',
            'volume_label': 'USB Drive',
            'drive_type': 'usb'
        }
        
        drive = manager.register_drive("test_user", drive_info, "laptop1")
        assert drive is not None
        
        # Test path matching
        matched = manager.get_drive_for_path("test_user", "/media/usb/Documents/file.pdf", "laptop1")
        assert matched is not None
        assert matched.id == drive.id
        print(f"✅ Path /media/usb/Documents/file.pdf matched to drive")
        
        # Test path not on drive
        no_match = manager.get_drive_for_path("test_user", "/home/user/Documents/file.pdf", "laptop1")
        assert no_match is None
        print(f"✅ Path /home/user/Documents/file.pdf not matched (correct)")
        
        # Test same drive on different client (should not match)
        no_match2 = manager.get_drive_for_path("test_user", "/media/usb/file.pdf", "laptop2")
        assert no_match2 is None
        print(f"✅ Path not matched on laptop2 (drive not mounted there)")
        
        print("✅ test_get_drive_for_path passed")
        
    finally:
        os.unlink(db_path)


def test_get_drives():
    """Test getting all drives for a user"""
    print("\n=== Test: get_drives ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # Register multiple drives
        drive1_info = {
            'unique_identifier': 'USB-1',
            'mount_point': '/media/usb1',
            'volume_label': 'USB 1',
            'drive_type': 'usb'
        }
        manager.register_drive("test_user", drive1_info, "laptop1")
        
        drive2_info = {
            'unique_identifier': 'USB-2',
            'mount_point': '/media/usb2',
            'volume_label': 'USB 2',
            'drive_type': 'usb'
        }
        manager.register_drive("test_user", drive2_info, "laptop1")
        
        drive3_info = {
            'unique_identifier': 'ONEDRIVE-1',
            'mount_point': '/home/user/OneDrive',
            'volume_label': 'OneDrive',
            'drive_type': 'cloud',
            'cloud_provider': 'onedrive'
        }
        manager.register_drive("test_user", drive3_info, "laptop1")
        
        # Get all drives
        drives = manager.get_drives("test_user")
        assert len(drives) == 3, f"Expected 3 drives, got {len(drives)}"
        print(f"✅ Retrieved {len(drives)} drives")
        
        for drive in drives:
            print(f"  - {drive.volume_label} ({drive.drive_type})")
        
        print("✅ test_get_drives passed")
        
    finally:
        os.unlink(db_path)


def test_get_client_drives():
    """Test getting drives for a specific client"""
    print("\n=== Test: get_client_drives ===")
    
    db_path = setup_test_db()
    manager = DriveManager(db_path)
    
    try:
        # Register drive on laptop1
        drive1_info = {
            'unique_identifier': 'USB-CLIENT-1',
            'mount_point': '/media/usb',
            'volume_label': 'USB Drive',
            'drive_type': 'usb'
        }
        manager.register_drive("test_user", drive1_info, "laptop1")
        
        # Register drive on laptop2
        drive2_info = {
            'unique_identifier': 'USB-CLIENT-2',
            'mount_point': '/mnt/usb',
            'volume_label': 'Another USB',
            'drive_type': 'usb'
        }
        manager.register_drive("test_user", drive2_info, "laptop2")
        
        # Get drives for laptop1
        laptop1_drives = manager.get_client_drives("test_user", "laptop1")
        assert len(laptop1_drives) == 1
        assert laptop1_drives[0].unique_identifier == 'USB-CLIENT-1'
        print(f"✅ laptop1 has {len(laptop1_drives)} drive(s)")
        
        # Get drives for laptop2
        laptop2_drives = manager.get_client_drives("test_user", "laptop2")
        assert len(laptop2_drives) == 1
        assert laptop2_drives[0].unique_identifier == 'USB-CLIENT-2'
        print(f"✅ laptop2 has {len(laptop2_drives)} drive(s)")
        
        print("✅ test_get_client_drives passed")
        
    finally:
        os.unlink(db_path)


def run_all_tests():
    """Run all tests"""
    print("=" * 60)
    print("Running DriveManager Tests")
    print("=" * 60)
    
    tests = [
        test_register_new_drive,
        test_usb_mobility_between_laptops,
        test_shared_cloud_storage,
        test_match_drive_by_identifier,
        test_get_drive_for_path,
        test_get_drives,
        test_get_client_drives,
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
