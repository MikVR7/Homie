# Destination Memory System

> **A smart system that learns and remembers where you organize your files**

## 🎯 What It Does

The Destination Memory System tracks where users organize their files over time, learning patterns and preferences to make future file organization smarter and faster.

## 📦 What's Included

### Database Tables
- **`drives`** - Tracks physical and cloud drives for path portability
- **`destinations`** - Stores learned destination folders with usage tracking
- **`destination_usage`** - Detailed usage history for analytics

### Python Components
- **`models.py`** - Dataclasses: `Drive`, `Destination`, `DestinationUsage`
- **`migration_runner.py`** - Automatic database migration system
- **`migrations/001_destination_memory.py`** - Initial schema migration

### Documentation
- **`QUICK_START.md`** - Get started in 5 minutes
- **`DESTINATION_MEMORY.md`** - Complete technical documentation
- **`IMPLEMENTATION_SUMMARY.md`** - Implementation details
- **`VERIFICATION_CHECKLIST.md`** - Verify the implementation
- **`migrations/README.md`** - Migration system guide

### Examples
- **`example_destination_memory.py`** - Working example with sample data

## 🚀 Quick Start

### 1. Automatic Setup (Recommended)
Migrations run automatically when the backend starts:
```bash
./start_backend.sh
```

Look for this in the logs:
```
🧠 Starting PathMemoryManager…
✅ Applied 1 database migration(s)
```

### 2. Manual Testing
```bash
# Test the migration
python3 backend/file_organizer/migrations/001_destination_memory.py

# Test the migration runner
python3 backend/file_organizer/migration_runner.py

# Run the example
python3 backend/file_organizer/example_destination_memory.py
```

### 3. Verify Installation
```bash
# Check database exists
ls -lh backend/data/modules/homie_file_organizer.db

# Check tables created
sqlite3 backend/data/modules/homie_file_organizer.db ".tables"

# Check migration applied
sqlite3 backend/data/modules/homie_file_organizer.db "SELECT * FROM schema_migrations;"
```

## 💡 Usage Examples

### Record a Destination
```python
import sqlite3
import uuid
from datetime import datetime

conn = sqlite3.connect("backend/data/modules/homie_file_organizer.db")

# Record or update destination
destination_id = str(uuid.uuid4())
conn.execute("""
    INSERT INTO destinations (id, user_id, path, category, usage_count, last_used_at)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, path) DO UPDATE SET
        usage_count = usage_count + 1,
        last_used_at = excluded.last_used_at
""", (destination_id, "user123", "/home/user/Documents/Invoices", "invoice", 1, datetime.now().isoformat()))

conn.commit()
```

### Query Popular Destinations
```python
cursor = conn.execute("""
    SELECT path, usage_count, last_used_at
    FROM destinations
    WHERE user_id = ? AND category = ? AND is_active = 1
    ORDER BY usage_count DESC, last_used_at DESC
    LIMIT 5
""", ("user123", "invoice"))

for row in cursor.fetchall():
    print(f"{row[0]}: {row[1]} uses")
```

### Track a Drive
```python
drive_id = str(uuid.uuid4())
conn.execute("""
    INSERT INTO drives (id, user_id, unique_identifier, mount_point, volume_label, drive_type, is_available, last_seen_at, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
""", (drive_id, "user123", "USB-12345", "/media/usb", "My USB", "usb", 1, datetime.now().isoformat(), datetime.now().isoformat()))

conn.commit()
```

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [QUICK_START.md](QUICK_START.md) | Get started quickly |
| [DESTINATION_MEMORY.md](DESTINATION_MEMORY.md) | Complete technical docs |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Implementation details |
| [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) | Verify installation |
| [migrations/README.md](migrations/README.md) | Migration system guide |

## 🧪 Testing

All tests pass successfully:

```bash
# Run all tests
python3 backend/file_organizer/migrations/001_destination_memory.py
python3 backend/file_organizer/migration_runner.py
python3 backend/file_organizer/example_destination_memory.py
```

Expected: All tests show ✅ success indicators

## 🗂️ Database Schema

### Tables
- `drives` - Physical/cloud drive tracking
- `destinations` - Learned destination folders
- `destination_usage` - Usage history
- `schema_migrations` - Migration tracking

### Indexes
- `idx_destinations_user_category` - Fast category lookups
- `idx_destinations_user_active` - Filter active destinations
- `idx_drives_user_available` - Find available drives
- `idx_usage_destination` - Usage analytics

## 🔧 Integration

The system integrates seamlessly with `PathMemoryManager`:

```python
from backend.file_organizer.path_memory_manager import PathMemoryManager

# Migrations run automatically on start
manager = PathMemoryManager(event_bus, shared_services)
await manager.start()  # ← Migrations applied here
```

## 🎨 Models & Manager

### Models
Three dataclasses with full type hints:

```python
from backend.file_organizer.models import Drive, Destination, DestinationUsage
from datetime import datetime
import uuid

# Create a drive
drive = Drive(
    id=str(uuid.uuid4()),
    user_id="user123",
    unique_identifier="USB-12345",
    mount_point="/media/usb",
    volume_label="My USB",
    drive_type="usb",
    cloud_provider=None,
    is_available=True,
    last_seen_at=datetime.now(),
    created_at=datetime.now()
)

# Create a destination
destination = Destination(
    id=str(uuid.uuid4()),
    user_id="user123",
    path="/home/user/Documents/Invoices",
    category="invoice",
    drive_id=drive.id,
    created_at=datetime.now(),
    last_used_at=datetime.now(),
    usage_count=1,
    is_active=True
)
```

### DestinationMemoryManager
High-level API for managing destinations:

```python
from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from pathlib import Path

manager = DestinationMemoryManager(Path("backend/data/modules/homie_file_organizer.db"))

# Add a destination
dest = manager.add_destination("user123", "/home/user/Documents/Invoices", "invoice")

# Get all destinations
destinations = manager.get_destinations("user123")

# Auto-capture from operations
operations = [{"type": "move", "dest": "/home/user/Documents/file.pdf"}]
captured = manager.auto_capture_destinations("user123", operations)

# Update usage
manager.update_usage(dest.id, file_count=5, operation_type="move")

# Get analytics
analytics = manager.get_usage_analytics("user123")
```

See [DESTINATION_MEMORY_MANAGER.md](DESTINATION_MEMORY_MANAGER.md) for complete API documentation.

## 🔄 Migration System

Automatic migration discovery and execution:

```python
from backend.file_organizer.migration_runner import run_migrations
from pathlib import Path

# Run migrations
db_path = Path("backend/data/modules/homie_file_organizer.db")
applied = run_migrations(db_path)
print(f"Applied {applied} migrations")
```

## 🎯 Next Steps

1. **Implement Learning**: Add code to record destinations when organizing files
2. **Build Suggestions**: Query popular destinations to suggest to users
3. **Track Drives**: Detect and track USB/cloud drives
4. **Path Portability**: Remap paths when drives reconnect
5. **Analytics**: Build dashboard showing organization patterns

## 🐛 Troubleshooting

### Migration Not Running?
Check logs when starting PathMemoryManager. If errors occur:
```python
from backend.file_organizer.migration_runner import run_migrations
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
run_migrations(db_path)
```

### Tables Not Created?
Verify migration status:
```python
from backend.file_organizer.migration_runner import MigrationRunner
from pathlib import Path

runner = MigrationRunner(Path("backend/data/modules/homie_file_organizer.db"))
status = runner.get_migration_status()
print(status)
```

### Need to Reset?
⚠️ **Warning**: Deletes all data!
```bash
rm backend/data/modules/homie_file_organizer.db
./start_backend.sh  # Recreates with migrations
```

## 📊 Performance

- All critical queries are indexed
- UPSERT operations for efficient updates
- Foreign key relationships for data integrity
- Optimized for common query patterns

## 🔒 Security

- User isolation via `user_id` filtering
- Parameterized queries prevent SQL injection
- Path validation recommended before storage
- Access control at application layer

## 📈 Status

✅ **Complete and Tested**
- All tables created
- All indexes in place
- All models working
- All tests passing
- Full documentation
- Example code included

## 📞 Support

For questions or issues:
1. Check the logs: `backend/homie_backend.log`
2. Review documentation in this directory
3. Run example: `python3 backend/file_organizer/example_destination_memory.py`
4. Check migration status with the runner

---

**Version**: 1.0  
**Migration**: 001_destination_memory  
**Status**: ✅ Production Ready
