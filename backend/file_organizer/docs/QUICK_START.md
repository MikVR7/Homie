# Destination Memory System - Quick Start

## What is it?

A system that learns where you organize files and suggests destinations based on your history.

## Files Created

```
backend/file_organizer/
├── migrations/
│   ├── __init__.py
│   ├── 001_destination_memory.py    # Database schema migration
│   └── README.md                     # Migration documentation
├── models.py                         # Python dataclasses (Drive, Destination, DestinationUsage)
├── migration_runner.py               # Automatic migration system
├── DESTINATION_MEMORY.md             # Full documentation
└── QUICK_START.md                    # This file
```

## Quick Test

### 1. Test the migration standalone
```bash
python3 backend/file_organizer/migrations/001_destination_memory.py
```

Expected output:
```
✅ Created drives table
✅ Created destinations table
✅ Created destination_usage table
✅ Created indexes
✅ Migration 001 applied successfully
```

### 2. Test the migration runner
```bash
python3 backend/file_organizer/migration_runner.py
```

Expected output:
```
📦 Applying migration 1: 001_destination_memory
✅ Migration 1 applied successfully
✅ Applied 1 migration(s)
```

### 3. Test the models
```bash
python3 -c "from backend.file_organizer.models import Drive, Destination, DestinationUsage; print('✅ Models imported successfully')"
```

### 4. Start the backend (migrations run automatically)
```bash
./start_backend.sh
```

Look for this in the logs:
```
🧠 Starting PathMemoryManager…
✅ Applied 1 database migration(s)
```

## Database Location

The database is created at:
```
backend/data/modules/homie_file_organizer.db
```

## Inspect the Database

```bash
sqlite3 backend/data/modules/homie_file_organizer.db

# Check tables
.tables

# Check schema
.schema destinations
.schema drives
.schema destination_usage

# Check migrations
SELECT * FROM schema_migrations;

# Exit
.quit
```

## Using the Models

### Create a Drive record
```python
from backend.file_organizer.models import Drive
from datetime import datetime
import uuid

drive = Drive(
    id=str(uuid.uuid4()),
    user_id="user123",
    unique_identifier="USB-SERIAL-12345",
    mount_point="/media/usb",
    volume_label="My USB",
    drive_type="usb",
    cloud_provider=None,
    is_available=True,
    last_seen_at=datetime.now(),
    created_at=datetime.now()
)
```

### Create a Destination record
```python
from backend.file_organizer.models import Destination
from datetime import datetime
import uuid

destination = Destination(
    id=str(uuid.uuid4()),
    user_id="user123",
    path="/home/user/Documents/Invoices",
    category="invoice",
    drive_id=None,  # Optional: link to a drive
    created_at=datetime.now(),
    last_used_at=datetime.now(),
    usage_count=1,
    is_active=True
)
```

### Record Usage
```python
from backend.file_organizer.models import DestinationUsage
from datetime import datetime
import uuid

usage = DestinationUsage(
    id=str(uuid.uuid4()),
    destination_id="<destination-id>",
    used_at=datetime.now(),
    file_count=5,
    operation_type="move"
)
```

## Common Queries

### Get popular destinations for a category
```sql
SELECT path, usage_count, last_used_at
FROM destinations
WHERE user_id = 'user123' 
  AND category = 'invoice' 
  AND is_active = 1
ORDER BY usage_count DESC, last_used_at DESC
LIMIT 5;
```

### Get all available drives
```sql
SELECT mount_point, volume_label, drive_type
FROM drives
WHERE user_id = 'user123' 
  AND is_available = 1;
```

### Get usage analytics for a destination
```sql
SELECT 
    d.path,
    d.usage_count,
    COUNT(du.id) as detailed_usage_count,
    SUM(du.file_count) as total_files_organized
FROM destinations d
LEFT JOIN destination_usage du ON d.id = du.destination_id
WHERE d.user_id = 'user123'
GROUP BY d.id;
```

## Next Steps

1. **Read the full documentation**: [DESTINATION_MEMORY.md](DESTINATION_MEMORY.md)
2. **Learn about migrations**: [migrations/README.md](migrations/README.md)
3. **Implement destination learning**: Add code to record destinations when files are organized
4. **Build suggestion engine**: Query popular destinations to suggest to users
5. **Add drive tracking**: Detect and track USB/cloud drives

## Troubleshooting

### Migration not running?
Check the logs when starting PathMemoryManager. If you see errors, check:
- Database file permissions
- Migration file syntax
- Import paths

### Tables not created?
Manually run the migration:
```python
from backend.file_organizer.migration_runner import run_migrations
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
run_migrations(db_path)
```

### Need to reset?
⚠️ **Warning**: This deletes all data!
```bash
rm backend/data/modules/homie_file_organizer.db
# Restart backend to recreate
```

## Support

For issues or questions:
1. Check the logs in `backend/homie_backend.log`
2. Review [DESTINATION_MEMORY.md](DESTINATION_MEMORY.md)
3. Check migration status with the runner
