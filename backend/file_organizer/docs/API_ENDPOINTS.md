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
