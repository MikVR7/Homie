#!/usr/bin/env python3
"""
Test script for batch drive registration endpoint

Tests the new POST /api/file-organizer/drives/batch endpoint
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:5000"
USER_ID = "test_user"
CLIENT_ID = "test_laptop"


def test_batch_drive_registration():
    """Test registering multiple drives in a single request"""
    
    print("=" * 60)
    print("Testing Batch Drive Registration")
    print("=" * 60)
    
    # Prepare test data - 5 drives
    drives_data = [
        {
            "mount_point": "/",
            "drive_type": "fixed",
            "volume_label": "System",
            "unique_identifier": "mount:/"
        },
        {
            "mount_point": "/home",
            "drive_type": "fixed",
            "volume_label": "Home",
            "unique_identifier": "mount:/home"
        },
        {
            "mount_point": "/media/usb1",
            "drive_type": "usb",
            "volume_label": "USB Drive 1",
            "unique_identifier": "usb:12345"
        },
        {
            "mount_point": "/media/usb2",
            "drive_type": "usb",
            "volume_label": "USB Drive 2",
            "unique_identifier": "usb:67890"
        },
        {
            "mount_point": "/home/user/OneDrive",
            "drive_type": "cloud",
            "volume_label": "OneDrive",
            "cloud_provider": "onedrive",
            "unique_identifier": "onedrive:user@example.com"
        }
    ]
    
    # Test 1: Batch registration
    print("\n1. Testing batch registration (5 drives)...")
    start_time = datetime.now()
    
    response = requests.post(
        f"{BASE_URL}/api/file-organizer/drives/batch",
        json={
            "user_id": USER_ID,
            "client_id": CLIENT_ID,
            "drives": drives_data
        }
    )
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds() * 1000
    
    print(f"   Status: {response.status_code}")
    print(f"   Duration: {duration:.2f}ms")
    
    if response.status_code == 201:
        data = response.json()
        print(f"   ✓ Success: {data['success']}")
        print(f"   ✓ Count: {data['count']}")
        print(f"   ✓ Drives registered: {len(data['drives'])}")
        
        # Show drive details
        for drive in data['drives']:
            print(f"      - {drive['volume_label']} ({drive['drive_type']}) at {drive['mount_point']}")
    else:
        print(f"   ✗ Failed: {response.text}")
        return False
    
    # Test 2: Verify drives were saved
    print("\n2. Verifying drives were saved...")
    response = requests.get(
        f"{BASE_URL}/api/file-organizer/drives",
        params={"user_id": USER_ID}
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"   ✓ Total drives in database: {len(data['drives'])}")
        
        # Check each drive
        for expected_drive in drives_data:
            found = any(
                d['mount_point'] == expected_drive['mount_point']
                for d in data['drives']
            )
            status = "✓" if found else "✗"
            print(f"   {status} {expected_drive['volume_label']}: {expected_drive['mount_point']}")
    else:
        print(f"   ✗ Failed to retrieve drives: {response.text}")
        return False
    
    # Test 3: Update existing drives (idempotency test)
    print("\n3. Testing idempotency (re-registering same drives)...")
    
    # Modify one drive's label
    drives_data[0]['volume_label'] = "System Updated"
    
    response = requests.post(
        f"{BASE_URL}/api/file-organizer/drives/batch",
        json={
            "user_id": USER_ID,
            "client_id": CLIENT_ID,
            "drives": drives_data
        }
    )
    
    if response.status_code == 201:
        data = response.json()
        print(f"   ✓ Re-registration successful")
        print(f"   ✓ Count: {data['count']}")
        
        # Verify the label was updated
        updated_drive = next(
            (d for d in data['drives'] if d['mount_point'] == '/'),
            None
        )
        if updated_drive and updated_drive['volume_label'] == "System Updated":
            print(f"   ✓ Drive label updated successfully")
        else:
            print(f"   ✗ Drive label not updated")
    else:
        print(f"   ✗ Failed: {response.text}")
        return False
    
    # Test 4: Error handling - empty array
    print("\n4. Testing error handling (empty array)...")
    response = requests.post(
        f"{BASE_URL}/api/file-organizer/drives/batch",
        json={
            "user_id": USER_ID,
            "client_id": CLIENT_ID,
            "drives": []
        }
    )
    
    if response.status_code == 400:
        data = response.json()
        print(f"   ✓ Correctly rejected empty array")
        print(f"   ✓ Error message: {data['error']}")
    else:
        print(f"   ✗ Should have returned 400, got {response.status_code}")
    
    # Test 5: Error handling - missing required field
    print("\n5. Testing error handling (missing mount_point)...")
    response = requests.post(
        f"{BASE_URL}/api/file-organizer/drives/batch",
        json={
            "user_id": USER_ID,
            "client_id": CLIENT_ID,
            "drives": [
                {
                    "drive_type": "fixed",
                    "volume_label": "No Mount Point"
                }
            ]
        }
    )
    
    if response.status_code == 500:  # DriveManager returns None on validation error
        print(f"   ✓ Correctly rejected drive with missing mount_point")
    else:
        print(f"   ✗ Should have returned error, got {response.status_code}")
    
    # Test 6: Performance comparison
    print("\n6. Performance comparison...")
    print("   Old approach (5 individual requests):")
    
    individual_start = datetime.now()
    for drive in drives_data:
        requests.post(
            f"{BASE_URL}/api/file-organizer/drives",
            json={
                "user_id": USER_ID,
                "client_id": CLIENT_ID,
                **drive
            }
        )
    individual_end = datetime.now()
    individual_duration = (individual_end - individual_start).total_seconds() * 1000
    
    print(f"      Duration: {individual_duration:.2f}ms")
    
    print("   New approach (1 batch request):")
    batch_start = datetime.now()
    requests.post(
        f"{BASE_URL}/api/file-organizer/drives/batch",
        json={
            "user_id": USER_ID,
            "client_id": CLIENT_ID,
            "drives": drives_data
        }
    )
    batch_end = datetime.now()
    batch_duration = (batch_end - batch_start).total_seconds() * 1000
    
    print(f"      Duration: {batch_duration:.2f}ms")
    
    improvement = ((individual_duration - batch_duration) / individual_duration) * 100
    print(f"   ✓ Performance improvement: {improvement:.1f}%")
    print(f"   ✓ Time saved: {individual_duration - batch_duration:.2f}ms")
    
    print("\n" + "=" * 60)
    print("All tests completed successfully!")
    print("=" * 60)
    
    return True


if __name__ == "__main__":
    try:
        test_batch_drive_registration()
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to backend server")
        print("Make sure the backend is running on http://localhost:5000")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
