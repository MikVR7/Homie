# Drive Client Mounts - Per-Client Mount Point Tracking

## Problem

The original schema stored only one `mount_point` per drive, but this doesn't work when:
- Multiple frontend clients (laptops) report the same drive
- Same USB drive has different mount points on different clients (e.g., `/media/usb` vs `/mnt/usb`)
- Same OneDrive is mounted on 3 different laptops with different local paths

## Solution

Migration 002 adds a `drive_client_mounts` table to track mount points per client.

## Schema Changes

### New Table: `drive_client_mounts`

```sql
CREATE TABLE drive_client_mounts (
    id TEXT PRIMARY KEY,
    drive_id TEXT NOT NULL,
    client_id TEXT NOT NULL,
    mount_point TEXT NOT NULL,
    last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_available INTEGER DEFAULT 1,
    FOREIGN KEY (drive_id) REFERENCES drives(id) ON DELETE CASCADE,
    UNIQUE(drive_id, client_id)
);

CREATE INDEX idx_drive_mounts_drive ON drive_client_mounts(drive_id);
CREATE INDEX idx_drive_mounts_client ON drive_client_mounts(client_id);
```

### Updated Drive Model

The `Drive` dataclass now includes an optional `client_mounts` field:

```python
@dataclass
class Drive:
    # ... existing fields ...
    client_mounts: Optional[List[DriveClientMount]] = None
```

### New Model: DriveClientMount

```python
@dataclass
class DriveClientMount:
    id: str
    drive_id: str
    client_id: str
    mount_point: str
    last_seen_at: datetime
    is_available: bool
```

## Use Cases

### Use Case 1: Same USB on Different Laptops

**Scenario**: User has a USB drive with unique identifier `USB-SERIAL-12345`

**Laptop 1** (client_id: `laptop-1`):
```python
# Drive record (shared)
drive_id = "drive-uuid-123"
unique_identifier = "USB-SERIAL-12345"

# Mount on laptop-1
mount_point = "/media/usb"
client_id = "laptop-1"
```

**Laptop 2** (client_id: `laptop-2`):
```python
# Same drive record
drive_id = "drive-uuid-123"
unique_identifier = "USB-SERIAL-12345"

# Different mount on laptop-2
mount_point = "/mnt/usb"
client_id = "laptop-2"
```

### Use Case 2: OneDrive on Multiple Laptops

**Scenario**: User has OneDrive synced on 3 laptops

```python
# Single drive record
drive_id = "onedrive-uuid"
unique_identifier = "ONEDRIVE-user@example.com"
drive_type = "cloud"
cloud_provider = "onedrive"

# Three different mounts
# Laptop 1
mount_point = "/home/user1/OneDrive"
client_id = "laptop-1"

# Laptop 2
mount_point = "/Users/user/OneDrive"
client_id = "laptop-2"

# Laptop 3
mount_point = "C:\\Users\\user\\OneDrive"
client_id = "laptop-3"
```

### Use Case 3: Path-to-Drive Matching

When determining which drive contains a path, check the mount for **that specific client**:

```python
# User on laptop-1 organizes file to:
destination_path = "/media/usb/Documents/file.pdf"
client_id = "laptop-1"

# Query: Find drive for this path on this client
SELECT d.*, m.mount_point
FROM drives d
JOIN drive_client_mounts m ON d.id = m.drive_id
WHERE m.client_id = 'laptop-1'
  AND '/media/usb/Documents/file.pdf' LIKE m.mount_point || '%'
ORDER BY LENGTH(m.mount_point) DESC
LIMIT 1

# Result: drive with USB-SERIAL-12345
```

## Data Migration

Migration 002 automatically migrates existing data:

1. For each drive with a `mount_point` in the `drives` table
2. Creates a `drive_client_mounts` entry
3. Uses `'legacy_client'` as the default `client_id`
4. Copies `mount_point`, `is_available`, and `last_seen_at`

**Example**:
```sql
-- Before migration
drives table:
  id: drive-1
  mount_point: /media/usb
  is_available: 1

-- After migration
drive_client_mounts table:
  id: mount-uuid-1
  drive_id: drive-1
  client_id: legacy_client
  mount_point: /media/usb
  is_available: 1
```

## API Usage

### Querying Drives with Mounts

```python
import sqlite3
from backend.file_organizer.models import Drive, DriveClientMount

conn = sqlite3.connect("backend/data/modules/homie_file_organizer.db")
conn.row_factory = sqlite3.Row

# Get drive with all its mounts
cursor = conn.execute("""
    SELECT d.*, m.id as mount_id, m.client_id, m.mount_point as client_mount_point,
           m.last_seen_at as mount_last_seen, m.is_available as mount_available
    FROM drives d
    LEFT JOIN drive_client_mounts m ON d.id = m.drive_id
    WHERE d.id = ?
""", (drive_id,))

rows = cursor.fetchall()
if rows:
    # Create drive from first row
    drive = Drive.from_db_row(rows[0])
    
    # Add client mounts
    drive.client_mounts = []
    for row in rows:
        if row['mount_id']:
            mount = DriveClientMount(
                id=row['mount_id'],
                drive_id=row['id'],
                client_id=row['client_id'],
                mount_point=row['client_mount_point'],
                last_seen_at=datetime.fromisoformat(row['mount_last_seen']),
                is_available=bool(row['mount_available'])
            )
            drive.client_mounts.append(mount)
```

### Registering a Mount

```python
import uuid
from datetime import datetime

# Client reports a drive
client_id = "laptop-1"
drive_id = "drive-uuid-123"
mount_point = "/media/usb"

# Insert or update mount
mount_id = str(uuid.uuid4())
conn.execute("""
    INSERT INTO drive_client_mounts (id, drive_id, client_id, mount_point, last_seen_at, is_available)
    VALUES (?, ?, ?, ?, ?, 1)
    ON CONFLICT(drive_id, client_id) DO UPDATE SET
        mount_point = excluded.mount_point,
        last_seen_at = excluded.last_seen_at,
        is_available = 1
""", (mount_id, drive_id, client_id, mount_point, datetime.now().isoformat()))

conn.commit()
```

### Finding Drive for Path (Per Client)

```python
def get_drive_for_path(user_id: str, client_id: str, path: str):
    """Find which drive contains the given path for this client"""
    cursor = conn.execute("""
        SELECT d.*, m.mount_point as client_mount_point
        FROM drives d
        JOIN drive_client_mounts m ON d.id = m.drive_id
        WHERE d.user_id = ?
          AND m.client_id = ?
          AND m.is_available = 1
          AND ? LIKE m.mount_point || '%'
        ORDER BY LENGTH(m.mount_point) DESC
        LIMIT 1
    """, (user_id, client_id, path))
    
    row = cursor.fetchone()
    return Drive.from_db_row(row) if row else None
```

## Benefits

1. **Multi-Client Support**: Same drive can be tracked across multiple devices
2. **Accurate Path Matching**: Paths are matched against the correct mount point for each client
3. **Drive Portability**: When a USB moves between laptops, we track it correctly
4. **Cloud Drive Support**: OneDrive/Dropbox can have different paths on each device
5. **Backward Compatible**: Existing data is migrated automatically

## Migration Status

- **Version**: 002
- **Status**: ✅ Complete and tested
- **Depends on**: Migration 001 (destination_memory)
- **Rollback**: Supported

## Testing

Run the migration test:
```bash
python3 backend/file_organizer/migrations/002_drive_client_mounts.py
```

Expected output:
```
✅ Table exists
✅ Indexes exist
✅ Data migrated: 2 mount points
✅ Mount data correct
✅ Migration 002 test passed
✅ Rollback test passed
```

## Future Enhancements

1. **Auto-Detection**: Automatically detect client_id from frontend
2. **Mount Conflict Resolution**: Handle cases where mount points change
3. **Offline Tracking**: Track when drives were last seen per client
4. **Mount History**: Keep history of mount point changes
5. **Drive Sync Status**: Track cloud drive sync status per client
