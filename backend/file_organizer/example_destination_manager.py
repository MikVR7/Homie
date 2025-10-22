#!/usr/bin/env python3
"""
Example: Using DestinationMemoryManager

This script demonstrates the high-level API for managing destinations.
"""

import sys
from pathlib import Path
import tempfile
import os

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from backend.file_organizer.migration_runner import run_migrations


def main():
    print("🚀 DestinationMemoryManager Example\n")
    
    # Setup temporary database
    with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
        db_path = Path(tmp.name)
    
    try:
        # Run migrations
        print("📦 Setting up database...")
        run_migrations(db_path)
        
        # Create manager
        manager = DestinationMemoryManager(db_path)
        user_id = "demo_user"
        
        # Example 1: Manual destination management
        print("\n" + "=" * 60)
        print("Example 1: Manual Destination Management")
        print("=" * 60)
        
        print("\n📁 Adding destinations...")
        dest1 = manager.add_destination(user_id, "/home/user/Documents/Invoices", "invoice")
        print(f"✅ Added: {dest1.path}")
        
        dest2 = manager.add_destination(user_id, "/home/user/Documents/Receipts", "receipt")
        print(f"✅ Added: {dest2.path}")
        
        dest3 = manager.add_destination(user_id, "/home/user/Videos/Movies", "movie")
        print(f"✅ Added: {dest3.path}")
        
        print("\n📋 Getting all destinations...")
        all_destinations = manager.get_destinations(user_id)
        for dest in all_destinations:
            print(f"  - {dest.path} ({dest.category})")
        
        # Example 2: Auto-capture from operations
        print("\n" + "=" * 60)
        print("Example 2: Auto-Capture from Operations")
        print("=" * 60)
        
        operations = [
            {"type": "move", "src": "/tmp/file1.pdf", "dest": "/home/user/Documents/Tax/2024/file1.pdf"},
            {"type": "move", "src": "/tmp/file2.pdf", "dest": "/home/user/Documents/Tax/2024/file2.pdf"},
            {"type": "copy", "src": "/tmp/photo.jpg", "dest": "/home/user/Pictures/Vacation/photo.jpg"},
        ]
        
        print("\n🔍 Auto-capturing destinations from operations...")
        captured = manager.auto_capture_destinations(user_id, operations)
        print(f"✅ Captured {len(captured)} new destinations:")
        for dest in captured:
            print(f"  - {dest.path} (category: {dest.category})")
        
        # Example 3: Usage tracking
        print("\n" + "=" * 60)
        print("Example 3: Usage Tracking")
        print("=" * 60)
        
        print("\n📊 Updating usage statistics...")
        manager.update_usage(dest1.id, file_count=5, operation_type="move")
        manager.update_usage(dest1.id, file_count=3, operation_type="move")
        manager.update_usage(dest2.id, file_count=10, operation_type="copy")
        
        # Get updated destinations
        updated_destinations = manager.get_destinations(user_id)
        print("\n📈 Usage statistics:")
        for dest in updated_destinations[:3]:  # Top 3
            print(f"  - {dest.path}")
            print(f"    Used: {dest.usage_count} times")
            print(f"    Last used: {dest.last_used_at}")
        
        # Example 4: Category filtering
        print("\n" + "=" * 60)
        print("Example 4: Category Filtering")
        print("=" * 60)
        
        print("\n🔍 Getting invoice destinations...")
        invoices = manager.get_destinations_by_category(user_id, "invoice")
        print(f"Found {len(invoices)} invoice destination(s):")
        for dest in invoices:
            print(f"  - {dest.path} (used {dest.usage_count} times)")
        
        # Example 5: Analytics
        print("\n" + "=" * 60)
        print("Example 5: Usage Analytics")
        print("=" * 60)
        
        analytics = manager.get_usage_analytics(user_id)
        
        print("\n📊 Overall Statistics:")
        overall = analytics['overall']
        print(f"  Total destinations: {overall['total_destinations']}")
        print(f"  Total categories: {overall['total_categories']}")
        print(f"  Total uses: {overall['total_uses']}")
        
        print("\n📊 By Category:")
        for cat in analytics['by_category'][:5]:  # Top 5
            print(f"  {cat['category']}: {cat['total_uses']} uses across {cat['destination_count']} destination(s)")
        
        print("\n📊 Most Used Destinations:")
        for dest in analytics['most_used'][:5]:  # Top 5
            print(f"  {dest['path']}: {dest['usage_count']} uses")
        
        # Example 6: Category extraction
        print("\n" + "=" * 60)
        print("Example 6: Category Extraction")
        print("=" * 60)
        
        test_paths = [
            "/home/user/Documents/Work/Projects",
            "/home/user/Videos/Movies",
            "/home/user/my_important_files",
            "/home/user/test-folder",
        ]
        
        print("\n🏷️  Extracting categories from paths:")
        for path in test_paths:
            category = manager.extract_category_from_path(path)
            print(f"  {path}")
            print(f"    → Category: {category}")
        
        # Example 7: Removing destinations
        print("\n" + "=" * 60)
        print("Example 7: Removing Destinations")
        print("=" * 60)
        
        print(f"\n🗑️  Removing destination: {dest3.path}")
        success = manager.remove_destination(user_id, dest3.id)
        if success:
            print("✅ Destination removed (soft delete)")
        
        active_count = len(manager.get_destinations(user_id))
        print(f"📊 Active destinations remaining: {active_count}")
        
        print("\n" + "=" * 60)
        print("✅ Example completed successfully!")
        print("=" * 60)
        print(f"\n💡 Database created at: {db_path}")
        print(f"💡 Inspect with: sqlite3 {db_path}")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    finally:
        # Cleanup
        if db_path.exists():
            os.unlink(db_path)
            print(f"🧹 Cleaned up temporary database")


if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.WARNING)
    main()
