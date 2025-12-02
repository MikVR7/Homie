# Batch Drive Registration - Quick Reference

## Endpoint

```
POST /api/file-organizer/drives/batch
```

## Minimal Request

```json
{
  "user_id": "user123",
  "client_id": "laptop1",
  "drives": [
    {
      "mount_point": "/",
      "drive_type": "fixed"
    }
  ]
}
```

## Full Request

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
      "mount_point": "/home/user/OneDrive",
      "drive_type": "cloud",
      "volume_label": "OneDrive",
      "cloud_provider": "onedrive",
      "unique_identifier": "onedrive:user@example.com"
    }
  ]
}
```

## Response

```json
{
  "success": true,
  "drives": [...],
  "count": 2
}
```

## JavaScript Example

```javascript
const response = await fetch('/api/file-organizer/drives/batch', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: 'user123',
    client_id: 'laptop1',
    drives: [
      { mount_point: '/', drive_type: 'fixed' },
      { mount_point: '/home', drive_type: 'fixed' }
    ]
  })
});

const data = await response.json();
console.log(`Registered ${data.count} drives`);
```

## Python Example

```python
import requests

response = requests.post(
    'http://localhost:5000/api/file-organizer/drives/batch',
    json={
        'user_id': 'user123',
        'client_id': 'laptop1',
        'drives': [
            {'mount_point': '/', 'drive_type': 'fixed'},
            {'mount_point': '/home', 'drive_type': 'fixed'}
        ]
    }
)

data = response.json()
print(f"Registered {data['count']} drives")
```

## Required Fields

- `mount_point` - Path where drive is mounted
- `drive_type` - One of: `fixed`, `usb`, `cloud`

## Optional Fields

- `volume_label` - Human-readable name (defaults to mount_point)
- `unique_identifier` - Hardware/cloud ID (auto-generated if missing)
- `cloud_provider` - For cloud drives: `onedrive`, `dropbox`, `google_drive`
- `total_space` - Total space in bytes
- `available_space` - Available space in bytes
- `is_available` - Boolean (defaults to true)

## Drive Types

| Type | Description | Example |
|------|-------------|---------|
| `fixed` | Internal hard drive | `/`, `/home` |
| `usb` | USB/external drive | `/media/usb` |
| `cloud` | Cloud storage | `/home/user/OneDrive` |

## Error Responses

| Status | Error | Cause |
|--------|-------|-------|
| 400 | `drives must be an array` | Invalid request format |
| 400 | `drives array cannot be empty` | Empty drives array |
| 500 | `DriveManager not available` | Backend not ready |
| 500 | `Failed to register drives` | Validation or DB error |

## Performance

- **Old**: 5 requests × 50ms = 250ms
- **New**: 1 request × 50ms = 50ms
- **Improvement**: 80% faster

## Testing

```bash
python backend/file_organizer/test_batch_drive_registration.py
```

## Documentation

- Full API docs: [API_ENDPOINTS.md](API_ENDPOINTS.md)
- Frontend integration: [FRONTEND_INTEGRATION_GUIDE.md](FRONTEND_INTEGRATION_GUIDE.md)
- Changelog: [FILE_ORGANIZER_CHANGELOG.md](FILE_ORGANIZER_CHANGELOG.md)
