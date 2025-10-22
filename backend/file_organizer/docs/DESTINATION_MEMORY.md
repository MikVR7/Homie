# Destination Memory System

The Destination Memory System learns and remembers where users organize their files, making file organization smarter and more personalized over time.

## Overview

This system tracks:
- **Destinations**: Folders where files are organized, categorized by file type
- **Drives**: Physical and cloud drives to handle path portability
- **Usage History**: Detailed analytics on how destinations are used

## Database Schema

### Tables

#### `drives`
Tracks physical and cloud drives for path portability.

```sql
CREATE TABLE drives (
    id TEXT PRIMARY KEY,                    -- UUID
    user_id TEXT NOT NULL,                  -- User identifier
    unique_identifier TEXT NOT NULL,        -- Hardware UUID or cloud ID
    mount_point TEXT NOT NULL,              -- Current mount path
    volume_label TEXT,                      -- Human-readable label
    drive_type TEXT NOT NULL,               -- 'internal', 'usb', 'cloud'
    cloud_provider TEXT,                    -- 'onedrive', 'dropbox', 'google_drive', null
    is_available INTEGER DEFAULT 1,         -- Currently accessible
    last_seen_at TIMESTAMP,                 -- Last detection time
    created_at TIMESTAMP,                   -- First registration
    UNIQUE(user_id, unique_identifier)
)
```

#### `destinations`
Stores learned destination folders with usage tracking.

```sql
CREATE TABLE destinations (
    id TEXT PRIMARY KEY,                    -- UUID
    user_id TEXT NOT NULL,                  -- User identifier
    path TEXT NOT NULL,                     -- Full destination path
    category TEXT NOT NULL,                 -- File category (e.g., 'invoices')
    drive_id TEXT,                          -- Reference to drives table
    created_at TIMESTAMP,                   -- First learned
    last_used_at TIMESTAMP,                 -- Last usage
    usage_count INTEGER DEFAULT 0,          -- Total usage count
    is_active INTEGER DEFAULT 1,            -- Still valid/preferred
    UNIQUE(user_id, path),
    FOREIGN KEY (drive_id) REFERENCES drives(id)
)
```

#### `destination_usage`
Detailed usage history for analytics.

```sql
CREATE TABLE destination_usage (
    id TEXT PRIMARY KEY,                    -- UUID
    destination_id TEXT NOT NULL,           -- Reference to destinations
    used_at TIMESTAMP,                      -- Usage timestamp
    file_count INTEGER DEFAULT 1,           -- Files in this operation
    operation_type TEXT,                    -- 'move', 'copy'
    FOREIGN KEY (destination_id) REFERENCES destinations(id)
)
```

### Indexes

```sql
CREATE INDEX idx_destinations_user_category ON destinations(user_id, category);
CREATE INDEX idx_destinations_user_active ON destinations(user_id, is_active);
CREATE INDEX idx_drives_user_available ON drives(user_id, is_available);
CREATE INDEX idx_usage_destination ON destination_usage(destination_id);
```

## Python Models

### Drive

```python
from backend.file_organizer.models import Drive
from datetime import datetime

drive = Drive(
    id="550e8400-e29b-41d4-a716-446655440000",
    user_id="user123",
    unique_identifier="USB-12345-ABCDE",
    mount_point="/media/usb",
    volume_label="My USB Drive",
    drive_type="usb",
    cloud_provider=None,
    is_available=True,
    last_seen_at=datetime.now(),
    created_at=datetime.now()
)
```

### Destination

```python
from backend.file_organizer.models import Destination
from datetime import datetime

destination = Destination(
    id="660e8400-e29b-41d4-a716-446655440000",
    user_id="user123",
    path="/home/user/Documents/Invoices/2024",
    category="invoice",
    drive_id="550e8400-e29b-41d4-a716-446655440000",
    created_at=datetime.now(),
    last_used_at=datetime.now(),
    usage_count=15,
    is_active=True
)
```

### DestinationUsage

```python
from backend.file_organizer.models import DestinationUsage
from datetime import datetime

usage = DestinationUsage(
    id="770e8400-e29b-41d4-a716-446655440000",
    destination_id="660e8400-e29b-41d4-a716-446655440000",
    used_at=datetime.now(),
    file_count=5,
    operation_type="move"
)
```

## Usage Examples

### Recording a Destination

```python
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path

# Connect to database
db_path = Path("backend/data/modules/homie_file_organizer.db")
conn = sqlite3.connect(str(db_path))

# Record a new destination
destination_id = str(uuid.uuid4())
conn.execute("""
    INSERT INTO destinations (id, user_id, path, category, usage_count, last_used_at)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, path) DO UPDATE SET
        usage_count = usage_count + 1,
        last_used_at = excluded.last_used_at
""", (
    destination_id,
    "user123",
    "/home/user/Documents/Invoices/2024",
    "invoice",
    1,
    datetime.now().isoformat()
))

# Record usage event
usage_id = str(uuid.uuid4())
conn.execute("""
    INSERT INTO destination_usage (id, destination_id, file_count, operation_type)
    VALUES (?, ?, ?, ?)
""", (usage_id, destination_id, 3, "move"))

conn.commit()
conn.close()
```

### Querying Popular Destinations

```python
import sqlite3
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
conn = sqlite3.connect(str(db_path))
conn.row_factory = sqlite3.Row

# Get top destinations for a category
cursor = conn.execute("""
    SELECT path, usage_count, last_used_at
    FROM destinations
    WHERE user_id = ? AND category = ? AND is_active = 1
    ORDER BY usage_count DESC, last_used_at DESC
    LIMIT 5
""", ("user123", "invoice"))

for row in cursor.fetchall():
    print(f"{row['path']}: {row['usage_count']} uses")

conn.close()
```

### Tracking Drive Availability

```python
import sqlite3
from datetime import datetime
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
conn = sqlite3.connect(str(db_path))

# Update drive availability
conn.execute("""
    UPDATE drives
    SET is_available = ?, last_seen_at = ?
    WHERE unique_identifier = ?
""", (True, datetime.now().isoformat(), "USB-12345-ABCDE"))

# Get all available drives for user
cursor = conn.execute("""
    SELECT mount_point, volume_label, drive_type
    FROM drives
    WHERE user_id = ? AND is_available = 1
""", ("user123",))

for row in cursor.fetchall():
    print(f"{row[1]}: {row[0]} ({row[2]})")

conn.close()
```

## Integration with PathMemoryManager

The migration runs automatically when PathMemoryManager starts:

```python
from backend.file_organizer.path_memory_manager import PathMemoryManager

# Migrations run automatically on start
manager = PathMemoryManager(event_bus, shared_services)
await manager.start()  # Migrations applied here
```

## Future Enhancements

1. **Smart Suggestions**: Use ML to predict best destinations based on file content
2. **Path Portability**: Automatically remap paths when drives are reconnected
3. **Cloud Sync**: Track cloud drive sync status and conflicts
4. **Usage Analytics**: Dashboard showing organization patterns
5. **Destination Cleanup**: Archive or suggest removing unused destinations
6. **Multi-Device Sync**: Share learned destinations across devices

## Migration Management

See [migrations/README.md](migrations/README.md) for details on:
- Creating new migrations
- Rolling back changes
- Checking migration status
- Troubleshooting

## Testing

Run the migration test:
```bash
python3 backend/file_organizer/migrations/001_destination_memory.py
```

Run the migration runner test:
```bash
python3 backend/file_organizer/migration_runner.py
```

Test the models:
```bash
python3 -c "from backend.file_organizer.models import Drive, Destination, DestinationUsage; print('Models loaded successfully')"
```
