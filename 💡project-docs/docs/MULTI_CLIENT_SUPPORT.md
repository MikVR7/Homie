# Multi-Client Support in DestinationMemoryManager

## Overview

The DestinationMemoryManager now supports multiple clients (laptops/devices) accessing the same user account with proper drive and destination tracking per client.

## Key Changes

### 1. Updated Method Signatures

#### `add_destination()`
```python
def add_destination(
    self, 
    user_id: str, 
    path: str, 
    category: str, 
    client_id: str,  # NEW: which client is adding this
    drive_id: Optional[str] = None
) -> Optional[Destination]:
```

**Changes:**
- Added `client_id` parameter (required)
- Auto-detects `drive_id` using client-specific mount points
- Passes `client_id` to `get_drive_for_path()`

#### `auto_capture_destinations()`
```python
def auto_capture_destinations(
    self, 
    user_id: str, 
    operations: List[Dict[str, Any]],
    client_id: str  # NEW: which client is reporting
) -> List[Destination]:
```

**Changes:**
- Added `client_id` parameter (required)
- Uses client-specific mount points for drive detection
- Ensures paths are matched against correct client's drives

#### `get_drive_for_path()` (Updated)
```python
def get_drive_for_path(
    self, 
    user_id: str, 
    client_id: str,  # NEW: which client to check
    path: str
) -> Optional[str]:
```

**Changes:**
- Added `client_id` parameter (required)
- Queries `drive_client_mounts` table for client-specific mounts
- Returns drive with longest matching mount point for that client

### 2. New Method

#### `get_destinations_for_client()`
```python
def get_destinations_for_client(
    self, 
    user_id: str, 
    client_id: str
) -> List[Destination]:
```

**Purpose:**
- Get destinations accessible from a specific client
- Filters based on drive availability for that client
- Cloud storage destinations are accessible from all clients

**Logic:**
- Returns destinations where:
  - `drive_id` is NULL (local paths, no drive tracking)
  - Drive type is 'cloud' (accessible from all clients)
  - Drive has an available mount on this client

## Use Cases

### Use Case 1: Laptop1 Captures Destinations

```python
manager = DestinationMemoryManager(db_path)

# User on laptop1 organizes files
operations = [
    {"type": "move", "dest": "/media/usb/Documents/file.pdf"},
    {"type": "copy", "dest": "/home/user/OneDrive/Photos/pic.jpg"}
]

# Auto-capture with client_id
captured = manager.auto_capture_destinations(
    user_id="user123",
    operations=operations,
    client_id="laptop1"  # Important: identifies which laptop
)

# Result: Destinations are linked to drives based on laptop1's mount points
```

### Use Case 2: Laptop2 Requests Destinations

```python
# User switches to laptop2
# Get destinations accessible from laptop2
destinations = manager.get_destinations_for_client(
    user_id="user123",
    client_id="laptop2"
)

# Result: Only shows destinations that:
# - Are on drives mounted on laptop2
# - Are on cloud drives (accessible from all)
# - Have no drive (local paths)
```

### Use Case 3: USB Drive on Different Laptops

**Scenario**: USB drive with unique_identifier `USB-SERIAL-123`

**Laptop1** mounts at `/media/usb`:
```python
# User organizes file on laptop1
dest = manager.add_destination(
    user_id="user123",
    path="/media/usb/Documents",
    category="document",
    client_id="laptop1"
)
# drive_id detected based on laptop1's mount at /media/usb
```

**Laptop2** mounts same USB at `/mnt/usb`:
```python
# Same user on laptop2
# USB is now mounted at different path
destinations = manager.get_destinations_for_client(
    user_id="user123",
    client_id="laptop2"
)
# Result: Destination is shown if USB is mounted on laptop2
# Path remains /media/usb (original), but system knows it's the same drive
```

### Use Case 4: OneDrive Across Laptops

**Scenario**: OneDrive synced on 3 laptops

```python
# Laptop1: /home/user1/OneDrive
dest1 = manager.add_destination(
    user_id="user123",
    path="/home/user1/OneDrive/Documents",
    category="document",
    client_id="laptop1"
)

# Laptop2: /Users/user/OneDrive
# Same destination is accessible because drive_type='cloud'
destinations = manager.get_destinations_for_client(
    user_id="user123",
    client_id="laptop2"
)
# Result: OneDrive destinations are shown (cloud drives accessible from all)
```

## Database Queries

### Get Destinations for Client

```sql
SELECT DISTINCT
    d.id, d.user_id, d.path, d.category, d.drive_id,
    d.created_at, d.last_used_at, d.usage_count, d.is_active
FROM destinations d
LEFT JOIN drives dr ON d.drive_id = dr.id
LEFT JOIN drive_client_mounts m ON dr.id = m.drive_id AND m.client_id = ?
WHERE d.user_id = ? 
  AND d.is_active = 1
  AND (
      d.drive_id IS NULL  -- No drive (local paths)
      OR dr.drive_type = 'cloud'  -- Cloud drives accessible from all clients
      OR m.is_available = 1  -- Drive has mount on this client
  )
ORDER BY d.usage_count DESC, d.last_used_at DESC
```

### Get Drive for Path (Client-Specific)

```sql
SELECT d.id, m.mount_point
FROM drives d
JOIN drive_client_mounts m ON d.id = m.drive_id
WHERE d.user_id = ?
  AND m.client_id = ?
  AND m.is_available = 1
  AND ? LIKE m.mount_point || '%'
ORDER BY LENGTH(m.mount_point) DESC
LIMIT 1
```

## API Integration

### Frontend Must Provide client_id

All API calls that interact with destinations must include `client_id`:

```python
# Example API endpoint
@app.route('/api/destinations/capture', methods=['POST'])
def capture_destinations():
    data = request.json
    user_id = get_current_user_id()
    client_id = data.get('client_id')  # From frontend
    operations = data.get('operations')
    
    if not client_id:
        return {"error": "client_id required"}, 400
    
    manager = get_destination_manager()
    captured = manager.auto_capture_destinations(user_id, operations, client_id)
    
    return {"captured": [dest.__dict__ for dest in captured]}
```

### Generating client_id

Frontend should generate a stable `client_id`:

```javascript
// Generate once and store in localStorage
function getClientId() {
    let clientId = localStorage.getItem('client_id');
    if (!clientId) {
        clientId = `client-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        localStorage.setItem('client_id', clientId);
    }
    return clientId;
}

// Include in all API calls
const clientId = getClientId();
fetch('/api/destinations/capture', {
    method: 'POST',
    body: JSON.stringify({
        client_id: clientId,
        operations: [...]
    })
});
```

## Migration Path

### Existing Code

Old code without `client_id`:
```python
# Old
dest = manager.add_destination(user_id, path, category)
captured = manager.auto_capture_destinations(user_id, operations)
```

### Updated Code

New code with `client_id`:
```python
# New
dest = manager.add_destination(user_id, path, category, client_id)
captured = manager.auto_capture_destinations(user_id, operations, client_id)
```

### Backward Compatibility

For legacy data:
- Existing destinations without drive tracking continue to work
- Migration 002 creates mounts with `client_id='legacy_client'`
- New clients can still access legacy destinations (no drive filter)

## Benefits

1. **Accurate Drive Detection**: Paths matched against correct client's mount points
2. **Multi-Device Support**: Same user can work from multiple laptops
3. **USB Portability**: USB drives tracked correctly across devices
4. **Cloud Integration**: Cloud drives accessible from all clients
5. **Offline Awareness**: Know which destinations are accessible per client

## Testing

Run the test suite:
```bash
python3 backend/file_organizer/test_destination_memory_manager.py
```

New test: `test_get_destinations_for_client()`
- Creates drive mounted on client1
- Adds destinations on USB and local
- Verifies client1 sees both
- Verifies client2 only sees local

## See Also

- [DRIVE_CLIENT_MOUNTS.md](DRIVE_CLIENT_MOUNTS.md) - Per-client mount tracking
- [DESTINATION_MEMORY_MANAGER.md](DESTINATION_MEMORY_MANAGER.md) - API documentation
- [Migration 002](../migrations/002_drive_client_mounts.py) - Database changes
