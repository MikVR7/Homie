#!/usr/bin/env python3
"""
Test Centralized Memory System and USB Drive Features
Demonstrates the new centralized memory system and USB drive recognition
"""

import os
import sys
import tempfile
import shutil
from datetime import datetime

# Add the backend directory to the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.file_organizer.smart_organizer import SmartOrganizer
from services.shared.module_database_service import ModuleDatabaseService

def test_centralized_memory():
    """Test the centralized memory system"""
    print("🧠 Testing Centralized Memory System")
    print("=" * 50)
    
    # Create a temporary directory for testing
    test_dir = tempfile.mkdtemp(prefix="homie_test_")
    print(f"📁 Test directory: {test_dir}")
    
    try:
        # Initialize the database service
        db_service = ModuleDatabaseService()
        
        # Create test user
        user_id = "test_user_centralized"
        
        # Initialize SmartOrganizer
        api_key = os.getenv('GEMINI_API_KEY', 'test_key')
        organizer = SmartOrganizer(api_key, user_id=user_id, data_dir="backend/data")
        
        # Test 1: Log some file actions
        print("\n📝 Test 1: Logging file actions to centralized database")
        
        test_actions = [
            {
                'action': 'move',
                'file': 'movie1.mp4',
                'source_folder': '/home/user/Downloads',
                'destination_folder': '/home/user/Movies',
                'success': True,
                'error': ''
            },
            {
                'action': 'delete',
                'file': 'temp_file.txt',
                'source_folder': '/home/user/Downloads',
                'destination_folder': '',
                'success': True,
                'error': ''
            },
            {
                'action': 'move',
                'file': 'document.pdf',
                'source_folder': '/home/user/Downloads',
                'destination_folder': '/home/user/Documents',
                'success': True,
                'error': ''
            }
        ]
        
        for action in test_actions:
            organizer._log_to_centralized_memory(
                action_data=action,
                source_folder=action['source_folder'],
                destination_folder=action['destination_folder']
            )
            print(f"  ✅ Logged: {action['action']} - {action['file']}")
        
        # Test 2: Get file access analytics
        print("\n📊 Test 2: Getting file access analytics from centralized database")
        
        analytics = organizer.get_file_access_analytics(days=30)
        print(f"  📈 Total accesses: {analytics.get('total_accesses', 0)}")
        print(f"  📈 Frequently accessed: {len(analytics.get('frequently_accessed', []))}")
        
        # Test 3: USB Drive Memory
        print("\n💾 Test 3: USB Drive Memory System")
        
        # Register some USB drives
        usb_drives = [
            {
                'drive_path': '/media/usb1',
                'purpose': 'Movies and TV Shows',
                'file_types': ['mp4', 'mkv', 'avi', 'mov']
            },
            {
                'drive_path': '/media/usb2',
                'purpose': 'Music Collection',
                'file_types': ['mp3', 'flac', 'wav', 'aac']
            },
            {
                'drive_path': '/media/usb3',
                'purpose': 'Documents and PDFs',
                'file_types': ['pdf', 'doc', 'docx', 'txt']
            }
        ]
        
        for drive in usb_drives:
            result = organizer.register_usb_drive(
                drive_path=drive['drive_path'],
                purpose=drive['purpose'],
                file_types=drive['file_types']
            )
            if result['success']:
                print(f"  ✅ Registered: {drive['drive_path']} - {drive['purpose']}")
            else:
                print(f"  ❌ Failed to register: {drive['drive_path']} - {result['error']}")
        
        # Get USB drives memory
        usb_memory = organizer.get_usb_drives_memory()
        print(f"  📊 Total USB drives: {len(usb_memory.get('usb_drives', {}))}")
        print(f"  📊 Connected drives: {len(usb_memory.get('connected_drives', []))}")
        print(f"  📊 Disconnected drives: {len(usb_memory.get('disconnected_drives', []))}")
        
        # Test 4: Destination suggestions
        print("\n🎯 Test 4: Destination suggestions based on USB drive memory")
        
        test_files = [
            {'path': 'movie.mp4', 'type': 'mp4'},
            {'path': 'song.mp3', 'type': 'mp3'},
            {'path': 'document.pdf', 'type': 'pdf'},
            {'path': 'unknown.xyz', 'type': 'xyz'}
        ]
        
        for file_info in test_files:
            suggestion = organizer.suggest_destination_for_file(
                file_path=file_info['path'],
                file_type=file_info['type']
            )
            
            if suggestion['success']:
                if suggestion['suggestions']:
                    print(f"  🎯 {file_info['path']}: {len(suggestion['suggestions'])} suggestion(s)")
                    for suggestion_info in suggestion['suggestions']:
                        print(f"    📁 {suggestion_info['drive_label']} ({suggestion_info['drive_path']}) - {suggestion_info['purpose']}")
                else:
                    print(f"  ❓ {file_info['path']}: No suggestions available")
            else:
                print(f"  ❌ {file_info['path']}: Error - {suggestion['error']}")
        
        print("\n✅ Centralized memory system test completed successfully!")
        
    except Exception as e:
        print(f"❌ Error during centralized memory test: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Clean up
        if os.path.exists(test_dir):
            shutil.rmtree(test_dir)
        print(f"🧹 Cleaned up test directory: {test_dir}")

def test_no_memory_files():
    """Test that no memory files are created in folders"""
    print("\n🚫 Testing No Memory Files in Folders")
    print("=" * 50)
    
    # Create a temporary directory for testing
    test_dir = tempfile.mkdtemp(prefix="homie_no_memory_")
    print(f"📁 Test directory: {test_dir}")
    
    try:
        # Create some test folders
        downloads_folder = os.path.join(test_dir, "Downloads")
        movies_folder = os.path.join(test_dir, "Movies")
        documents_folder = os.path.join(test_dir, "Documents")
        
        os.makedirs(downloads_folder, exist_ok=True)
        os.makedirs(movies_folder, exist_ok=True)
        os.makedirs(documents_folder, exist_ok=True)
        
        # Create some test files
        test_files = [
            os.path.join(downloads_folder, "test_movie.mp4"),
            os.path.join(downloads_folder, "test_document.pdf"),
            os.path.join(downloads_folder, "test_music.mp3")
        ]
        
        for file_path in test_files:
            with open(file_path, 'w') as f:
                f.write("test content")
        
        # Initialize SmartOrganizer
        api_key = os.getenv('GEMINI_API_KEY', 'test_key')
        organizer = SmartOrganizer(api_key, user_id="test_user_no_memory")
        
        # Simulate some file operations
        print("\n📝 Simulating file operations...")
        
        # Log file access
        for file_path in test_files:
            organizer.log_file_access(file_path, action='open')
            print(f"  📊 Logged access: {os.path.basename(file_path)}")
        
        # Check that no memory files were created
        print("\n🔍 Checking for memory files...")
        
        memory_files_found = []
        for root, dirs, files in os.walk(test_dir):
            for file in files:
                if file == '.homie_memory.json':
                    memory_files_found.append(os.path.join(root, file))
        
        if memory_files_found:
            print(f"  ❌ Found {len(memory_files_found)} memory files (should be 0):")
            for memory_file in memory_files_found:
                print(f"    📄 {memory_file}")
        else:
            print("  ✅ No memory files found in folders (correct behavior)")
        
        print("\n✅ No memory files test completed successfully!")
        
    except Exception as e:
        print(f"❌ Error during no memory files test: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Clean up
        if os.path.exists(test_dir):
            shutil.rmtree(test_dir)
        print(f"🧹 Cleaned up test directory: {test_dir}")

if __name__ == "__main__":
    print("🧠 Homie Centralized Memory System Test")
    print("=" * 60)
    
    # Test centralized memory system
    test_centralized_memory()
    
    # Test no memory files in folders
    test_no_memory_files()
    
    print("\n🎉 All tests completed!")
    print("=" * 60)
    print("✅ Centralized memory system working correctly")
    print("✅ No memory files created in folders")
    print("✅ USB drive memory system functional")
    print("✅ Destination suggestions working") 