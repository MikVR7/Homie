# DriveManager - Multi-Client Drive Tracking

## Architecture Overview

**CRITICAL**: The backend does NOT detect drives itself (it's on a server). Multiple frontend clients detect drives locally and report to the backend.

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Laptop 1   │         │  Laptop 2   │         │  Laptop 3   │
│  (Frontend) │         │  (Frontend) │         │  (Frontend) │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │ POST /drives          │ POST /drives          │ POST /drives
       │ {USB-123, /media/usb} │ {USB-123, /mnt/usb}   │ {ONEDRIVE-1}
       │                       │                       │
       └───────────────────────┴───────────────────────┘
                               │
                               ▼
                      ┌────────────────┐
                      │    Backend     │
                      │  DriveManager  │
                      └────────────────┘
                               │
                    Recognizes USB-123 as
                    SAME drive across laptops
```

## Key Concepts

### 1. Unique Identifier

The `unique_identifier` is the PRIMARY key for recognizing drives across clients:

- **USB Drives**: Hardware UUID, serial number
- **Cloud Storage**: Account ID (e.g., `ONEDRIVE-user@example.com`)
- **Network Drives**: Server path or share ID

### 2. Client-Specific Mounts

Same drive can have different mount points on different clients:

```python
# USB-123 on laptop1
mount_point = "/media/usb"

# Same USB-123 on laptop2
mount_point = "/mnt/usb"

# Backend recognizes it's the SAME drive
```

### 3. Drive Availability Per Client

A drive may be available on one client but not another:

```python
# USB plugged into laptop1
laptop1: is_available = True
laptop2: is_available = False

# USB moved to laptop2
laptop1: is_available = False
laptop2: is_available = True
```

## API Reference

### get_drives(user_id: str) -> List[Drive]

Retrieve all known drives for a user across ALL client devices.

**Returns**: List of Drive objects with `client_mounts` populated

**Example**:
```python
manager = DriveManager(db_path)
drives = manager.get_drives("user123")

for drive in drives:
    print(f"{drive.volume_label} ({drive.drive_type})")
    for mount in drive.client_mounts:
        status = "available" if mount.is_available else "unavailable"
        print(f"  - {mount.client_id}: {mount.mount_point} ({status})")
```

---

### register_drive(user_id: str, drive_info: dict, client_id: str) -> Optional[Drive]

Register or update a drive reported by a frontend client.

**Parameters**:
- `user_id`: User identifier
- `drive_info`: Dictionary with:
  - `unique_identifier` (required): Hardware/cloud ID
  - `mount_point` (required): Local mount path
  - `volume_label` (optional): Human-readable name
  - `drive_type` (required): 'internal', 'usb', 'cloud'
  - `cloud_provider` (optional): 'onedrive', 'dropbox', etc.
- `client_id`: Client/laptop identifier

**Drive Matching Logic**:
1. Check if drive exists by `unique_identifier`
2. If exists: Update mount for this client
3. If new: Create new drive record

**Example**:
```python
# Frontend on laptop1 detects USB drive
drive_info = {
    'unique_identifier': 'USB-SERIAL-12345',
    'mount_point': '/media/usb',
    'volume_label': 'My Backup',
    'drive_type': 'usb'
}

drive = manager.register_drive("user123", drive_info, "laptop1")
print(f"Registered: {drive.volume_label}")
```

---

### update_drive_availability(user_id: str, unique_identifier: str, is_available: bool, client_id: str) -> bool

Update availability status for a drive on a specific client.

**Parameters**:
- `user_id`: User identifier
- `unique_identifier`: Hardware/cloud ID
- `is_available`: Whether drive is accessible
- `client_id`: Client reporting the change

**Example**:
```python
# USB unplugged from laptop1
success = manager.update_drive_availability(
    "user123", 
    "USB-SERIAL-12345", 
    False, 
    "laptop1"
)
```

---

### match_drive_by_identifier(user_id: str, unique_identifier: str) -> Optional[Drive]

Find a drive by its unique identifier. PRIMARY method for recognizing drives across clients.

**Example**:
```python
drive = manager.match_drive_by_identifier("user123", "USB-SERIAL-12345")
if drive:
    print(f"Found: {drive.volume_label}")
```

---

### get_drive_for_path(user_id: str, path: str, client_id: str) -> Optional[Drive]

Determine which drive contains a path on a specific client.

**Example**:
```python
drive = manager.get_drive_for_path(
    "user123", 
    "/media/usb/Documents/file.pdf", 
    "laptop1"
)
```

---

### get_shared_cloud_drives(user_id: str, cloud_provider: str) -> List[Drive]

Get all drives for a specific cloud provider.

**Example**:
```python
onedrive_drives = manager.get_shared_cloud_drives("user123", "onedrive")
for drive in onedrive_drives:
    print(f"OneDrive with {len(drive.client_mounts)} client(s)")
```

---

### get_client_drives(user_id: str, client_id: str) -> List[Drive]

Get all drives currently available on a specific client.

**Example**:
```python
laptop1_drives = manager.get_client_drives("user123", "laptop1")
print(f"Laptop1 has {len(laptop1_drives)} drive(s)")
```

## Multi-Client Scenarios

### Scenario 1: USB Drive Mobility

**Step 1**: USB plugged into laptop1
```python
drive_info = {
    'unique_identifier': 'USB-BACKUP-789',
    'mount_point': '/media/usb',
    'volume_label': 'Backup Drive',
    'drive_type': 'usb'
}
drive = manager.register_drive("user123", drive_info, "laptop1")
# Result: New drive created, mounted on laptop1
```

**Step 2**: USB unplugged from laptop1
```python
manager.update_drive_availability("user123", 'USB-BACKUP-789', False, "laptop1")
# Result: Drive marked unavailable on laptop1
```

**Step 3**: USB plugged into laptop2
```python
drive_info = {
    'unique_identifier': 'USB-BACKUP-789',  # Same identifier!
    'mount_point': '/mnt/usb',  # Different mount point
    'volume_label': 'Backup Drive',
    'drive_type': 'usb'
}
drive = manager.register_drive("user123", drive_info, "laptop2")
# Result: SAME drive recognized, now mounted on laptop2
# drive.id remains unchanged
# drive.client_mounts has 2 entries (laptop1 unavailable, laptop2 available)
```

### Scenario 2: Shared Cloud Storage

**3 Laptops with OneDrive**:

```python
# Laptop1
drive_info1 = {
    'unique_identifier': 'ONEDRIVE-user@example.com',
    'mount_point': '/home/user1/OneDrive',
    'volume_label': 'OneDrive',
    'drive_type': 'cloud',
    'cloud_provider': 'onedrive'
}
drive1 = manager.register_drive("user123", drive_info1, "laptop1")

# Laptop2 (same OneDrive, different path)
drive_info2 = {
    'unique_identifier': 'ONEDRIVE-user@example.com',  # Same!
    'mount_point': '/Users/user/OneDrive',  # Different path
    'volume_label': 'OneDrive',
    'drive_type': 'cloud',
    'cloud_provider': 'onedrive'
}
drive2 = manager.register_drive("user123", drive_info2, "laptop2")

# Laptop3
drive_info3 = {
    'unique_identifier': 'ONEDRIVE-user@example.com',  # Same!
    'mount_point': 'C:\\Users\\user\\OneDrive',
    'volume_label': 'OneDrive',
    'drive_type': 'cloud',
    'cloud_provider': 'onedrive'
}
drive3 = manager.register_drive("user123", drive_info3, "laptop3")

# Result: drive1.id == drive2.id == drive3.id (SAME drive)
# drive.client_mounts has 3 entries
```

### Scenario 3: Offline Cloud Drive

```python
# Laptop1 goes offline
manager.update_drive_availability(
    "user123", 
    'ONEDRIVE-user@example.com', 
    False, 
    "laptop1"
)

# Laptop2 and Laptop3 still have OneDrive available
# Destinations on OneDrive still accessible from laptop2 and laptop3
```

## Frontend Integration

### Detecting Drives (Frontend)

```javascript
// Frontend detects drives locally
async function detectDrives() {
    const drives = [];
    
    // Example: Detect USB drives (platform-specific)
    const usbDrives = await detectUSBDrives();
    for (const usb of usbDrives) {
        drives.push({
            unique_identifier: usb.serialNumber,
            mount_point: usb.mountPath,
            volume_label: usb.label,
            drive_type: 'usb'
        });
    }
    
    // Example: Detect OneDrive
    const oneDrivePath = await detectOneDrivePath();
    if (oneDrivePath) {
        drives.push({
            unique_identifier: `ONEDRIVE-${userEmail}`,
            mount_point: oneDrivePath,
            volume_label: 'OneDrive',
            drive_type: 'cloud',
            cloud_provider: 'onedrive'
        });
    }
    
    return drives;
}
```

### Reporting to Backend

```javascript
// Report drives to backend
async function reportDrives() {
    const clientId = getClientId();  // Stable client identifier
    const drives = await detectDrives();
    
    for (const drive of drives) {
        await fetch('/api/drives/register', {
            method: 'POST',
            body: JSON.stringify({
                client_id: clientId,
                drive_info: drive
            })
        });
    }
}

// Run on startup and periodically
reportDrives();
setInterval(reportDrives, 60000);  // Every minute
```

### Handling Drive Changes

```javascript
// Listen for drive mount/unmount events
window.addEventListener('drive-mounted', async (event) => {
    const drive = event.detail;
    await fetch('/api/drives/register', {
        method: 'POST',
        body: JSON.stringify({
            client_id: getClientId(),
            drive_info: drive
        })
    });
});

window.addEventListener('drive-unmounted', async (event) => {
    const uniqueId = event.detail.unique_identifier;
    await fetch('/api/drives/availability', {
        method: 'PUT',
        body: JSON.stringify({
            client_id: getClientId(),
            unique_identifier: uniqueId,
            is_available: false
        })
    });
});
```

## Backend API Endpoints

### POST /api/drives/register

Register or update a drive.

```python
@app.route('/api/drives/register', methods=['POST'])
def register_drive():
    data = request.json
    user_id = get_current_user_id()
    client_id = data.get('client_id')
    drive_info = data.get('drive_info')
    
    manager = get_drive_manager()
    drive = manager.register_drive(user_id, drive_info, client_id)
    
    if drive:
        return jsonify({
            'success': True,
            'drive_id': drive.id,
            'unique_identifier': drive.unique_identifier
        })
    else:
        return jsonify({'success': False}), 400
```

### PUT /api/drives/availability

Update drive availability.

```python
@app.route('/api/drives/availability', methods=['PUT'])
def update_availability():
    data = request.json
    user_id = get_current_user_id()
    client_id = data.get('client_id')
    unique_identifier = data.get('unique_identifier')
    is_available = data.get('is_available')
    
    manager = get_drive_manager()
    success = manager.update_drive_availability(
        user_id, unique_identifier, is_available, client_id
    )
    
    return jsonify({'success': success})
```

### GET /api/drives

Get all drives for user.

```python
@app.route('/api/drives', methods=['GET'])
def get_drives():
    user_id = get_current_user_id()
    
    manager = get_drive_manager()
    drives = manager.get_drives(user_id)
    
    return jsonify({
        'drives': [drive_to_dict(d) for d in drives]
    })
```

## Testing

Run the test suite:
```bash
python3 backend/file_organizer/test_drive_manager.py
```

Tests cover:
- ✅ Registering new drives
- ✅ USB mobility between laptops
- ✅ Shared cloud storage
- ✅ Drive matching by identifier
- ✅ Path-to-drive matching
- ✅ Getting all drives
- ✅ Getting client-specific drives

## Benefits

1. **USB Portability**: Same USB recognized across laptops
2. **Cloud Sync**: OneDrive/Dropbox tracked across devices
3. **Accurate Tracking**: Know which drives are available where
4. **Path Resolution**: Match paths to correct drives per client
5. **Offline Handling**: Track availability per client

## See Also

- [DRIVE_CLIENT_MOUNTS.md](DRIVE_CLIENT_MOUNTS.md) - Database schema
- [MULTI_CLIENT_SUPPORT.md](MULTI_CLIENT_SUPPORT.md) - Multi-client architecture
- [Migration 002](../migrations/002_drive_client_mounts.py) - Database migration
