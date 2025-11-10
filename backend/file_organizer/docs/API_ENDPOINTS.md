# File Organizer API Endpoints

## Destination Management

### GET /api/file-organizer/destinations

Retrieve all active destinations for the current user.

**Query Parameters**:
- `user_id` (optional): User identifier (default: 'dev_user')
- `client_id` (optional): Client/laptop identifier (default: 'default_client')

**Response** (200 OK):
```json
{
  "success": true,
  "destinations": [
    {
      "id": "dest-uuid-123",
      "path": "/home/user/Videos/Movies",
      "category": "Movies",
      "drive_id": "drive-uuid-456",
      "drive_type": "internal",
      "drive_label": "System",
      "cloud_provider": null,
      "usage_count": 15,
      "last_used_at": "2025-10-20T14:30:00Z",
      "created_at": "2025-09-01T10:00:00Z",
      "is_active": true
    }
  ]
}
```

**Features**:
- Returns only destinations accessible from the specified client
- Includes drive information (type, label, cloud provider)
- Sorted by usage frequency
- Cloud drives accessible from all clients

**Example**:
```javascript
fetch('/api/file-organizer/destinations?user_id=user123&client_id=laptop1')
  .then(res => res.json())
  .then(data => {
    console.log(`Found ${data.destinations.length} destinations`);
  });
```

---

### POST /api/file-organizer/destinations

Manually add a new destination.

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "path": "/home/user/Documents/Work",
  "category": "Work Documents"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "destination": {
    "id": "dest-uuid-789",
    "path": "/home/user/Documents/Work",
    "category": "Work Documents",
    "drive_id": "drive-uuid-456",
    "usage_count": 0,
    "created_at": "2025-10-22T10:00:00Z",
    "is_active": true
  }
}
```

**Validation**:
- `path` is required
- `category` is required
- Path must exist on the filesystem
- Drive is auto-detected based on path and client

**Error Responses**:

400 Bad Request - Missing required fields:
```json
{
  "success": false,
  "error": "path is required"
}
```

400 Bad Request - Path doesn't exist:
```json
{
  "success": false,
  "error": "Path does not exist: /invalid/path"
}
```

500 Internal Server Error:
```json
{
  "success": false,
  "error": "DestinationMemoryManager not available"
}
```

**Example**:
```javascript
fetch('/api/file-organizer/destinations', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    path: '/home/user/Documents/Work',
    category: 'Work Documents'
  })
})
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      console.log('Destination added:', data.destination.id);
    }
  });
```

---

### DELETE /api/file-organizer/destinations/:destination_id

Remove a destination (soft delete).

**URL Parameters**:
- `destination_id`: Destination UUID

**Query Parameters**:
- `user_id` (optional): User identifier (default: 'dev_user')

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Destination removed successfully"
}
```

**Error Responses**:

404 Not Found - Destination doesn't exist:
```json
{
  "success": false,
  "error": "Destination not found"
}
```

**Note**: This is a soft delete - the destination is marked as inactive but remains in the database for audit trail.

**Example**:
```javascript
fetch('/api/file-organizer/destinations/dest-uuid-123?user_id=user123', {
  method: 'DELETE'
})
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      console.log('Destination removed');
    }
  });
```

---

### POST /api/file-organizer/delete-destination (Legacy)

Delete a saved destination (legacy endpoint for backward compatibility).

**Request Body**:
```json
{
  "user_id": "user123",
  "destination_id": "dest-uuid-123"
}
```

**Response** (200 OK):
```json
{
  "success": true
}
```

**Note**: Use the new `DELETE /api/file-organizer/destinations/:id` endpoint instead.

---

## Drive Management

### GET /api/file-organizer/drives

Retrieve all known drives for the current user.

**Query Parameters**:
- `user_id` (optional): User identifier (default: 'dev_user')

**Response** (200 OK):
```json
{
  "success": true,
  "drives": [
    {
      "id": "drive-uuid-123",
      "unique_identifier": "USB-SERIAL-12345",
      "mount_point": "/",
      "volume_label": "System",
      "drive_type": "internal",
      "cloud_provider": null,
      "is_available": true,
      "available_space_gb": 500.5,
      "last_seen_at": "2025-10-22T10:00:00Z",
      "created_at": "2025-09-01T08:00:00Z",
      "client_mounts": [
        {
          "client_id": "laptop1",
          "mount_point": "/",
          "is_available": true,
          "available_space_gb": 500.5,
          "last_seen_at": "2025-10-22T10:00:00Z"
        }
      ]
    }
  ]
}
```

**Features**:
- Returns all drives across all clients
- Includes real-time available space
- Shows client-specific mount points
- Includes cloud provider information

**Example**:
```javascript
fetch('/api/file-organizer/drives?user_id=user123')
  .then(res => res.json())
  .then(data => {
    console.log(`Found ${data.drives.length} drives`);
  });
```

---

### POST /api/file-organizer/drives

Register a new drive detected by frontend.

**⚠️ DEPRECATED**: Use `POST /api/file-organizer/drives/batch` for better performance.

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "unique_identifier": "USB-SERIAL-67890",
  "mount_point": "/media/usb",
  "volume_label": "MyUSB",
  "drive_type": "usb",
  "cloud_provider": null
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "drive": {
    "id": "drive-uuid-456",
    "unique_identifier": "USB-SERIAL-67890",
    "mount_point": "/media/usb",
    "volume_label": "MyUSB",
    "drive_type": "usb",
    "cloud_provider": null,
    "is_available": true,
    "available_space_gb": 50.0,
    "last_seen_at": "2025-10-22T10:00:00Z",
    "created_at": "2025-10-22T10:00:00Z",
    "client_mounts": [
      {
        "client_id": "laptop1",
        "mount_point": "/media/usb",
        "is_available": true,
        "last_seen_at": "2025-10-22T10:00:00Z"
      }
    ]
  }
}
```

**Validation**:
- `unique_identifier` is required
- `mount_point` is required
- `drive_type` is required
- Handles duplicate registration gracefully (updates existing drive)

**Drive Types**:
- `internal` - Internal hard drive
- `usb` - USB drive
- `cloud` - Cloud storage (OneDrive, Dropbox, etc.)

**Error Responses**:

400 Bad Request - Missing required fields:
```json
{
  "success": false,
  "error": "unique_identifier is required"
}
```

500 Internal Server Error:
```json
{
  "success": false,
  "error": "DriveManager not available"
}
```

**Example**:
```javascript
fetch('/api/file-organizer/drives', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    unique_identifier: 'USB-SERIAL-67890',
    mount_point: '/media/usb',
    volume_label: 'MyUSB',
    drive_type: 'usb'
  })
})
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      console.log('Drive registered:', data.drive.id);
    }
  });
```

---

### POST /api/file-organizer/drives/batch

Register multiple drives in a single request (RECOMMENDED).

**Benefits**:
- Reduces 5+ HTTP requests to 1
- Faster initialization
- Better database performance (single transaction)
- Cleaner logs
- Atomic operation (all succeed or all fail)

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "drives": [
    {
      "mount_point": "/",
      "drive_type": "fixed",
      "volume_label": "System",
      "unique_identifier": "mount:/",
      "total_space": 1000000000000,
      "available_space": 500000000000,
      "is_available": true
    },
    {
      "mount_point": "/home",
      "drive_type": "fixed",
      "volume_label": "Home",
      "unique_identifier": "mount:/home",
      "total_space": 2000000000000,
      "available_space": 1000000000000,
      "is_available": true
    },
    {
      "mount_point": "/home/user/OneDrive",
      "drive_type": "cloud",
      "volume_label": "OneDrive",
      "cloud_provider": "onedrive",
      "unique_identifier": "onedrive:user@example.com",
      "is_available": true
    }
  ]
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "drives": [
    {
      "id": "drive-uuid-123",
      "unique_identifier": "mount:/",
      "mount_point": "/",
      "volume_label": "System",
      "drive_type": "fixed",
      "cloud_provider": null,
      "is_available": true,
      "available_space_gb": 465.7,
      "last_seen_at": "2025-11-10T10:00:00Z",
      "created_at": "2025-11-10T10:00:00Z",
      "client_mounts": [
        {
          "client_id": "laptop1",
          "mount_point": "/",
          "is_available": true,
          "last_seen_at": "2025-11-10T10:00:00Z"
        }
      ]
    },
    {
      "id": "drive-uuid-456",
      "unique_identifier": "mount:/home",
      "mount_point": "/home",
      "volume_label": "Home",
      "drive_type": "fixed",
      "cloud_provider": null,
      "is_available": true,
      "available_space_gb": 931.3,
      "last_seen_at": "2025-11-10T10:00:00Z",
      "created_at": "2025-11-10T10:00:00Z",
      "client_mounts": [
        {
          "client_id": "laptop1",
          "mount_point": "/home",
          "is_available": true,
          "last_seen_at": "2025-11-10T10:00:00Z"
        }
      ]
    },
    {
      "id": "drive-uuid-789",
      "unique_identifier": "onedrive:user@example.com",
      "mount_point": "/home/user/OneDrive",
      "volume_label": "OneDrive",
      "drive_type": "cloud",
      "cloud_provider": "onedrive",
      "is_available": true,
      "last_seen_at": "2025-11-10T10:00:00Z",
      "created_at": "2025-11-10T10:00:00Z",
      "client_mounts": [
        {
          "client_id": "laptop1",
          "mount_point": "/home/user/OneDrive",
          "is_available": true,
          "last_seen_at": "2025-11-10T10:00:00Z"
        }
      ]
    }
  ],
  "count": 3
}
```

**Validation**:
- `drives` must be an array
- `drives` array cannot be empty
- Each drive must have `mount_point` (required)
- Each drive must have `drive_type` (required)
- `unique_identifier` is optional (auto-generated from mount_point if missing)
- `volume_label` is optional (defaults to mount_point)

**Drive Object Structure**:
```typescript
interface Drive {
  mount_point: string;           // Required: e.g., "/", "/home", "/media/usb"
  drive_type: string;             // Required: "fixed", "usb", "cloud"
  volume_label?: string;          // Optional: Human-readable name
  unique_identifier?: string;     // Optional: Auto-generated if missing
  cloud_provider?: string;        // Optional: "onedrive", "dropbox", "google_drive"
  total_space?: number;           // Optional: Total space in bytes
  available_space?: number;       // Optional: Available space in bytes
  is_available?: boolean;         // Optional: Defaults to true
}
```

**Behavior**:
- For each drive: checks if it exists (by unique_identifier)
- If exists: updates the drive record
- If new: creates a new drive record
- All operations happen in a single database transaction
- If any drive fails validation, entire batch fails (atomic)

**Error Responses**:

400 Bad Request - Invalid input:
```json
{
  "success": false,
  "error": "drives must be an array"
}
```

400 Bad Request - Empty array:
```json
{
  "success": false,
  "error": "drives array cannot be empty"
}
```

500 Internal Server Error:
```json
{
  "success": false,
  "error": "DriveManager not available"
}
```

**Example**:
```javascript
// Frontend initialization - register all detected drives at once
const detectedDrives = [
  { mount_point: '/', drive_type: 'fixed', volume_label: 'System' },
  { mount_point: '/home', drive_type: 'fixed', volume_label: 'Home' },
  { mount_point: '/media/usb', drive_type: 'usb', volume_label: 'MyUSB' },
  { mount_point: '/home/user/OneDrive', drive_type: 'cloud', cloud_provider: 'onedrive' }
];

fetch('/api/file-organizer/drives/batch', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    drives: detectedDrives
  })
})
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      console.log(`Registered ${data.count} drives in one request`);
      console.log('Drives:', data.drives);
    }
  });
```

**Performance Comparison**:

Old approach (5 drives):
```
5 HTTP requests × ~50ms = ~250ms
5 database transactions
5 log entries
```

New approach (5 drives):
```
1 HTTP request × ~50ms = ~50ms
1 database transaction
1 log entry
```

**Migration Guide**:

Before (multiple requests):
```javascript
for (const drive of detectedDrives) {
  await fetch('/api/file-organizer/drives', {
    method: 'POST',
    body: JSON.stringify({ ...drive, user_id, client_id })
  });
}
```

After (single batch request):
```javascript
await fetch('/api/file-organizer/drives/batch', {
  method: 'POST',
  body: JSON.stringify({ user_id, client_id, drives: detectedDrives })
});
```

---

### GET /api/file-organizer/drives/:drive_id

Get a specific drive by ID.

**URL Parameters**:
- `drive_id`: Drive UUID

**Query Parameters**:
- `user_id` (optional): User identifier (default: 'dev_user')

**Response** (200 OK):
```json
{
  "success": true,
  "drive": {
    "id": "drive-uuid-123",
    "unique_identifier": "USB-SERIAL-12345",
    "mount_point": "/media/usb",
    "volume_label": "MyUSB",
    "drive_type": "usb",
    "is_available": true,
    "available_space_gb": 50.0,
    "client_mounts": [...]
  }
}
```

**Error Responses**:

404 Not Found:
```json
{
  "success": false,
  "error": "Drive not found"
}
```

---

### PUT /api/file-organizer/drives/availability

Update drive availability status.

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "unique_identifier": "USB-SERIAL-12345",
  "is_available": false
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Drive availability updated"
}
```

**Use Case**: Frontend reports when a drive is unplugged or becomes unavailable.

**Error Responses**:

404 Not Found:
```json
{
  "success": false,
  "error": "Drive not found"
}
```

**Example**:
```javascript
// USB drive unplugged
fetch('/api/file-organizer/drives/availability', {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    unique_identifier: 'USB-SERIAL-12345',
    is_available: false
  })
});
```

---

### GET /api/file-organizer/get-drives (Legacy)

Get available drives/mount points.

**Response** (200 OK):
```json
{
  "success": true,
  "drives": [
    {
      "path": "/",
      "name": "/",
      "type": "local"
    }
  ]
}
```

**Note**: This is a legacy endpoint. Use `GET /api/file-organizer/drives` for more detailed information.

---

## File Organization

### POST /api/file-organizer/organize

Analyze files and suggest organization operations.

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "source_path": "/home/user/Downloads",
  "destination_path": "/home/user/Documents",
  "organization_style": "by_type"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "analysis_id": "analysis-uuid-123",
  "operations": [
    {
      "operation_id": "analysis-uuid-123_op_0",
      "type": "move",
      "source": "/home/user/Downloads/movie.mp4",
      "destination": "/home/user/Documents/Movies/movie.mp4",
      "status": "pending"
    }
  ]
}
```

**Features**:
- Includes AI context with known destinations
- AI prefers known destinations when appropriate
- Considers drive availability and space
- Returns analysis_id for tracking

**AI Context Integration**:
The endpoint automatically builds context including:
- Known destinations grouped by category
- Drive information and available space
- Usage statistics for each destination
- Instructions for AI to prefer known destinations

**Example**:
```javascript
fetch('/api/file-organizer/organize', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    source_path: '/home/user/Downloads',
    destination_path: '/home/user/Documents',
    organization_style: 'by_type'
  })
})
  .then(res => res.json())
  .then(data => {
    console.log(`Analysis ID: ${data.analysis_id}`);
    console.log(`${data.operations.length} operations suggested`);
  });
```

---

### POST /api/file-organizer/execute

Execute approved file operations.

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "analysis_id": "analysis-uuid-123",
  "operation_ids": [
    "analysis-uuid-123_op_0",
    "analysis-uuid-123_op_1"
  ]
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "results": [
    {
      "operation_id": "analysis-uuid-123_op_0",
      "success": true
    },
    {
      "operation_id": "analysis-uuid-123_op_1",
      "success": true
    }
  ],
  "new_destinations_captured": [
    {
      "id": "dest-uuid-456",
      "path": "/home/user/Documents/Movies",
      "category": "Movies"
    }
  ]
}
```

**Features**:
- Executes file operations (move, copy, delete, unpack)
- Auto-captures new destinations
- Updates usage statistics for destinations
- Returns newly captured destinations

**Auto-Capture Behavior**:
After successful operations:
1. Extracts destination folders from operations
2. Checks if destinations already exist
3. Creates new destination records for unknown folders
4. Updates usage count for all affected destinations
5. Returns list of newly captured destinations

**Example**:
```javascript
fetch('/api/file-organizer/execute', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    analysis_id: 'analysis-uuid-123',
    operation_ids: ['analysis-uuid-123_op_0', 'analysis-uuid-123_op_1']
  })
})
  .then(res => res.json())
  .then(data => {
    if (data.new_destinations_captured) {
      console.log(`Learned ${data.new_destinations_captured.length} new destinations`);
    }
  });
```

---

## Multi-Client Considerations

### Client ID

All endpoints support a `client_id` parameter to identify which laptop/device is making the request:

```javascript
const clientId = localStorage.getItem('client_id') || generateClientId();

fetch(`/api/file-organizer/destinations?client_id=${clientId}`)
```

### Client-Specific Filtering

- `GET /destinations` returns only destinations accessible from that client
- Destinations on USB drives only shown if USB is mounted on that client
- Cloud storage destinations shown to all clients

### Drive Detection

- `POST /destinations` auto-detects drive based on path and client
- Uses DriveManager.get_drive_for_path() with client-specific mounts

---

## Error Handling

All endpoints follow consistent error response format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

**HTTP Status Codes**:
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

---

## Authentication

Currently using simple `user_id` parameter. In production, implement proper authentication:

```javascript
// Example with JWT
fetch('/api/file-organizer/destinations', {
  headers: {
    'Authorization': `Bearer ${jwt_token}`
  }
})
```

---

## Rate Limiting

Consider implementing rate limiting for production:

```python
from flask_limiter import Limiter

limiter = Limiter(app, key_func=get_remote_address)

@app.route('/api/file-organizer/destinations', methods=['POST'])
@limiter.limit("10 per minute")
def add_destination():
    # ...
```

---

## AI-Powered Features

### POST /api/file-organizer/suggest-alternatives

Suggest alternative destinations when user disagrees with a suggestion.

**Request Body**:
```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "rejected_operation": {
    "source": "/home/user/Downloads/movie.mp4",
    "destination": "/home/user/Documents/Movies/movie.mp4",
    "type": "move"
  }
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "source": "known_destinations",
  "alternatives": [
    {
      "operation_id": "alt_a1b2c3d4",
      "type": "move",
      "source": "/home/user/Downloads/movie.mp4",
      "destination": "/media/usb/Movies/movie.mp4",
      "reason": "Alternative: Movies folder - used 3 times previously",
      "status": "pending"
    },
    {
      "operation_id": "alt_e5f6g7h8",
      "type": "move",
      "source": "/home/user/Downloads/movie.mp4",
      "destination": "/home/user/OneDrive/Movies/movie.mp4",
      "reason": "Alternative: Movies folder - used 1 time previously",
      "status": "pending"
    }
  ]
}
```

**Features**:
- First tries to suggest other known destinations in same category
- Excludes the rejected destination
- Orders by usage count (most used first)
- Falls back to AI-generated alternatives if no known destinations
- Includes source indicator ('known_destinations' or 'ai_generated')

**Algorithm**:
1. Extract category from rejected destination path
2. Find other destinations in same category
3. Exclude the rejected destination
4. Order by usage_count DESC
5. Create alternative operations with new destination paths
6. If no alternatives found, use AI to generate new suggestions

**Example**:
```javascript
fetch('/api/file-organizer/suggest-alternatives', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    rejected_operation: {
      source: '/home/user/Downloads/movie.mp4',
      destination: '/home/user/Documents/Movies/movie.mp4',
      type: 'move'
    }
  })
})
  .then(res => res.json())
  .then(data => {
    console.log(`Found ${data.alternatives.length} alternatives`);
    console.log(`Source: ${data.source}`);
  });
```

---

## Testing

### Using curl

```bash
# Get destinations
curl "http://localhost:5000/api/file-organizer/destinations?user_id=test&client_id=laptop1"

# Add destination
curl -X POST http://localhost:5000/api/file-organizer/destinations \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","client_id":"laptop1","path":"/home/user/Documents","category":"Documents"}'

# Delete destination
curl -X DELETE "http://localhost:5000/api/file-organizer/destinations/dest-uuid-123?user_id=test"
```

### Using Python requests

```python
import requests

# Get destinations
response = requests.get(
    'http://localhost:5000/api/file-organizer/destinations',
    params={'user_id': 'test', 'client_id': 'laptop1'}
)
print(response.json())

# Add destination
response = requests.post(
    'http://localhost:5000/api/file-organizer/destinations',
    json={
        'user_id': 'test',
        'client_id': 'laptop1',
        'path': '/home/user/Documents',
        'category': 'Documents'
    }
)
print(response.json())

# Delete destination
response = requests.delete(
    'http://localhost:5000/api/file-organizer/destinations/dest-uuid-123',
    params={'user_id': 'test'}
)
print(response.json())
```

---

## See Also

- [DESTINATION_MEMORY_MANAGER.md](DESTINATION_MEMORY_MANAGER.md) - Manager API
- [DRIVE_MANAGER.md](DRIVE_MANAGER.md) - Drive tracking
- [MULTI_CLIENT_SUPPORT.md](MULTI_CLIENT_SUPPORT.md) - Multi-client architecture
