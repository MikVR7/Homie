#!/usr/bin/env python3
"""
Example: Using the Destination Memory System

This script demonstrates how to:
1. Run migrations
2. Create drive records
3. Record destinations
4. Track usage
5. Query popular destinations
"""

import sqlite3
import uuid
from datetime import datetime, timedelta
from pathlib import Path
import sys

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from backend.file_organizer.models import Drive, Destination, DestinationUsage
from backend.file_organizer.migration_runner import run_migrations


def setup_database(db_path: Path) -> sqlite3.Connection:
    """Setup database and run migrations"""
    print(f"📦 Setting up database at {db_path}")
    
    # Run migrations
    applied = run_migrations(db_path)
    print(f"✅ Applied {applied} migration(s)")
    
    # Connect to database
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    return conn


def create_sample_drive(conn: sqlite3.Connection, user_id: str) -> str:
    """Create a sample USB drive"""
    drive_id = str(uuid.uuid4())
    
    conn.execute("""
        INSERT INTO drives (id, user_id, unique_identifier, mount_point, volume_label, drive_type, is_available, last_seen_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        drive_id,
        user_id,
        "USB-SERIAL-ABC123",
        "/media/usb",
        "My USB Drive",
        "usb",
        1,
        datetime.now().isoformat(),
        datetime.now().isoformat()
    ))
    
    conn.commit()
    print(f"✅ Created drive: {drive_id}")
    return drive_id


def record_destination(conn: sqlite3.Connection, user_id: str, path: str, category: str, drive_id: str = None) -> str:
    """Record a destination or update usage if it exists"""
    destination_id = str(uuid.uuid4())
    now = datetime.now().isoformat()
    
    # Try to insert, or update if exists
    cursor = conn.execute("""
        INSERT INTO destinations (id, user_id, path, category, drive_id, created_at, last_used_at, usage_count, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1)
        ON CONFLICT(user_id, path) DO UPDATE SET
            usage_count = usage_count + 1,
            last_used_at = excluded.last_used_at,
            is_active = 1
        RETURNING id
    """, (destination_id, user_id, path, category, drive_id, now, now))
    
    result = cursor.fetchone()
    actual_id = result[0] if result else destination_id
    
    conn.commit()
    print(f"✅ Recorded destination: {path} (category: {category})")
    return actual_id


def record_usage(conn: sqlite3.Connection, destination_id: str, file_count: int, operation_type: str):
    """Record a usage event"""
    usage_id = str(uuid.uuid4())
    
    conn.execute("""
        INSERT INTO destination_usage (id, destination_id, used_at, file_count, operation_type)
        VALUES (?, ?, ?, ?, ?)
    """, (usage_id, destination_id, datetime.now().isoformat(), file_count, operation_type))
    
    conn.commit()
    print(f"✅ Recorded usage: {file_count} files ({operation_type})")


def query_popular_destinations(conn: sqlite3.Connection, user_id: str, category: str = None):
    """Query popular destinations"""
    print(f"\n📊 Popular destinations for user {user_id}")
    if category:
        print(f"   Category: {category}")
    
    query = """
        SELECT path, category, usage_count, last_used_at
        FROM destinations
        WHERE user_id = ? AND is_active = 1
    """
    params = [user_id]
    
    if category:
        query += " AND category = ?"
        params.append(category)
    
    query += " ORDER BY usage_count DESC, last_used_at DESC LIMIT 10"
    
    cursor = conn.execute(query, params)
    
    print("\n  Path                                    Category      Uses  Last Used")
    print("  " + "-" * 80)
    
    for row in cursor.fetchall():
        path = row['path'][:40].ljust(40)
        category = row['category'][:12].ljust(12)
        usage = str(row['usage_count']).rjust(4)
        last_used = row['last_used_at'][:19] if row['last_used_at'] else "Never"
        print(f"  {path} {category} {usage}  {last_used}")


def query_usage_analytics(conn: sqlite3.Connection, user_id: str):
    """Query usage analytics"""
    print(f"\n📈 Usage Analytics for user {user_id}")
    
    cursor = conn.execute("""
        SELECT 
            d.category,
            COUNT(DISTINCT d.id) as destination_count,
            SUM(d.usage_count) as total_uses,
            SUM(du.file_count) as total_files
        FROM destinations d
        LEFT JOIN destination_usage du ON d.id = du.destination_id
        WHERE d.user_id = ? AND d.is_active = 1
        GROUP BY d.category
        ORDER BY total_uses DESC
    """, (user_id,))
    
    print("\n  Category      Destinations  Total Uses  Total Files")
    print("  " + "-" * 60)
    
    for row in cursor.fetchall():
        category = row['category'][:12].ljust(12)
        dest_count = str(row['destination_count']).rjust(12)
        uses = str(row['total_uses'] or 0).rjust(10)
        files = str(row['total_files'] or 0).rjust(12)
        print(f"  {category} {dest_count} {uses} {files}")


def main():
    """Run the example"""
    print("🚀 Destination Memory System Example\n")
    
    # Use a temporary database for the example
    import tempfile
    with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
        db_path = Path(tmp.name)
    
    try:
        # Setup
        conn = setup_database(db_path)
        user_id = "demo_user"
        
        # Create a drive
        print("\n📀 Creating sample drive...")
        drive_id = create_sample_drive(conn, user_id)
        
        # Record some destinations
        print("\n📁 Recording destinations...")
        
        # Invoices
        invoice_dest = record_destination(conn, user_id, "/home/user/Documents/Invoices/2024", "invoice", drive_id)
        record_usage(conn, invoice_dest, 5, "move")
        
        # More invoices (simulating repeated use)
        invoice_dest = record_destination(conn, user_id, "/home/user/Documents/Invoices/2024", "invoice", drive_id)
        record_usage(conn, invoice_dest, 3, "move")
        
        # Receipts
        receipt_dest = record_destination(conn, user_id, "/home/user/Documents/Receipts", "receipt")
        record_usage(conn, receipt_dest, 10, "copy")
        
        # Bank statements
        bank_dest = record_destination(conn, user_id, "/home/user/Documents/Banking/Statements", "bank_statement")
        record_usage(conn, bank_dest, 2, "move")
        
        # More receipts
        receipt_dest = record_destination(conn, user_id, "/home/user/Documents/Receipts", "receipt")
        record_usage(conn, receipt_dest, 7, "move")
        
        # Tax documents
        tax_dest = record_destination(conn, user_id, "/home/user/Documents/Tax/2024", "tax")
        record_usage(conn, tax_dest, 15, "copy")
        
        # Query results
        query_popular_destinations(conn, user_id)
        query_popular_destinations(conn, user_id, "invoice")
        query_usage_analytics(conn, user_id)
        
        print(f"\n✅ Example completed successfully!")
        print(f"📦 Database created at: {db_path}")
        print(f"💡 You can inspect it with: sqlite3 {db_path}")
        
        conn.close()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
