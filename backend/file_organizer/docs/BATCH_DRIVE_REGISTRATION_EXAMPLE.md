# Batch Drive Registration - Frontend Integration Guide

## Overview

The new batch drive registration endpoint allows frontends to register multiple drives in a single HTTP request, significantly improving initialization performance.

## Benefits

- **5x faster**: Reduces 5+ HTTP requests to 1
- **Atomic**: All drives succeed or all fail (database transaction)
- **Cleaner logs**: Single log entry instead of multiple
- **Better UX**: Faster app initialization

## Migration Guide

### Before (Old Approach)

```javascript
// ❌ OLD: Multiple individual requests
async function registerDrives(drives) {
  const results = [];
  
  for (const drive of drives) {
    try {
      const response = await fetch('/api/file-organizer/drives', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: userId,
          client_id: clientId,
          mount_point: drive.mountPoint,
          drive_type: drive.type,
          volume_label: drive.label,
          unique_identifier: drive.id
        })
      });
      
      const data = await response.json();
      results.push(data.drive);
    } catch (error) {
      console.error(`Failed to register drive ${drive.mountPoint}:`, error);
    }
  }
  
  return results;
}

// Result: 5 HTTP requests, ~250ms total
```

### After (New Approach)

```javascript
// ✅ NEW: Single batch request
async function registerDrives(drives) {
  try {
    const response = await fetch('/api/file-organizer/drives/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: userId,
        client_id: clientId,
        drives: drives.map(drive => ({
          mount_point: drive.mountPoint,
          drive_type: drive.type,
          volume_label: drive.label,
          unique_identifier: drive.id,
          cloud_provider: drive.cloudProvider
        }))
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log(`Registered ${data.count} drives`);
      return data.drives;
    } else {
      throw new Error(data.error);
    }
  } catch (error) {
    console.error('Failed to register drives:', error);
    throw error;
  }
}

// Result: 1 HTTP request, ~50ms total
```

## Complete Example

### TypeScript/JavaScript

```typescript
interface Drive {
  mountPoint: string;
  type: 'fixed' | 'usb' | 'cloud';
  label: string;
  id?: string;
  cloudProvider?: string;
  totalSpace?: number;
  availableSpace?: number;
}

interface BatchDriveResponse {
  success: boolean;
  drives: Array<{
    id: string;
    unique_identifier: string;
    mount_point: string;
    volume_label: string;
    drive_type: string;
    cloud_provider: string | null;
    is_available: boolean;
    available_space_gb?: number;
    last_seen_at: string;
    created_at: string;
    client_mounts: Array<{
      client_id: string;
      mount_point: string;
      is_available: boolean;
      last_seen_at: string;
    }>;
  }>;
  count: number;
  error?: string;
}

class DriveService {
  private baseUrl: string;
  private userId: string;
  private clientId: string;
  
  constructor(baseUrl: string, userId: string, clientId: string) {
    this.baseUrl = baseUrl;
    this.userId = userId;
    this.clientId = clientId;
  }
  
  /**
   * Register multiple drives in a single batch request
   */
  async registerDrivesBatch(drives: Drive[]): Promise<BatchDriveResponse> {
    const response = await fetch(`${this.baseUrl}/api/file-organizer/drives/batch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: this.userId,
        client_id: this.clientId,
        drives: drives.map(drive => ({
          mount_point: drive.mountPoint,
          drive_type: drive.type,
          volume_label: drive.label,
          unique_identifier: drive.id || `mount:${drive.mountPoint}`,
          cloud_provider: drive.cloudProvider,
          total_space: drive.totalSpace,
          available_space: drive.availableSpace
        }))
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to register drives');
    }
    
    return response.json();
  }
  
  /**
   * Initialize app by detecting and registering all drives
   */
  async initializeDrives(): Promise<void> {
    console.log('Detecting drives...');
    
    // Detect drives (platform-specific implementation)
    const detectedDrives = await this.detectDrives();
    
    console.log(`Found ${detectedDrives.length} drives`);
    
    // Register all drives in one batch
    const startTime = performance.now();
    const result = await this.registerDrivesBatch(detectedDrives);
    const duration = performance.now() - startTime;
    
    console.log(`Registered ${result.count} drives in ${duration.toFixed(2)}ms`);
    
    // Store registered drives
    this.saveDrivesToLocalStorage(result.drives);
  }
  
  /**
   * Detect drives on the system (platform-specific)
   */
  private async detectDrives(): Promise<Drive[]> {
    // Example implementation - replace with actual drive detection
    const drives: Drive[] = [];
    
    // Fixed drives
    drives.push({
      mountPoint: '/',
      type: 'fixed',
      label: 'System',
      id: 'mount:/'
    });
    
    drives.push({
      mountPoint: '/home',
      type: 'fixed',
      label: 'Home',
      id: 'mount:/home'
    });
    
    // USB drives (if any)
    const usbDrives = await this.detectUSBDrives();
    drives.push(...usbDrives);
    
    // Cloud storage (if any)
    const cloudDrives = await this.detectCloudDrives();
    drives.push(...cloudDrives);
    
    return drives;
  }
  
  private async detectUSBDrives(): Promise<Drive[]> {
    // Platform-specific USB detection
    return [];
  }
  
  private async detectCloudDrives(): Promise<Drive[]> {
    const drives: Drive[] = [];
    
    // Check for OneDrive
    const oneDrivePath = this.getOneDrivePath();
    if (oneDrivePath) {
      drives.push({
        mountPoint: oneDrivePath,
        type: 'cloud',
        label: 'OneDrive',
        cloudProvider: 'onedrive',
        id: `onedrive:${this.userId}`
      });
    }
    
    // Check for Dropbox
    const dropboxPath = this.getDropboxPath();
    if (dropboxPath) {
      drives.push({
        mountPoint: dropboxPath,
        type: 'cloud',
        label: 'Dropbox',
        cloudProvider: 'dropbox',
        id: `dropbox:${this.userId}`
      });
    }
    
    return drives;
  }
  
  private getOneDrivePath(): string | null {
    // Platform-specific OneDrive path detection
    return null;
  }
  
  private getDropboxPath(): string | null {
    // Platform-specific Dropbox path detection
    return null;
  }
  
  private saveDrivesToLocalStorage(drives: any[]): void {
    localStorage.setItem('registered_drives', JSON.stringify(drives));
  }
}

// Usage
const driveService = new DriveService(
  'http://localhost:5000',
  'user123',
  'laptop1'
);

// Initialize on app startup
driveService.initializeDrives()
  .then(() => console.log('Drives initialized'))
  .catch(error => console.error('Drive initialization failed:', error));
```

### Python Example

```python
import requests
from typing import List, Dict, Any

class DriveService:
    def __init__(self, base_url: str, user_id: str, client_id: str):
        self.base_url = base_url
        self.user_id = user_id
        self.client_id = client_id
    
    def register_drives_batch(self, drives: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Register multiple drives in a single batch request"""
        response = requests.post(
            f"{self.base_url}/api/file-organizer/drives/batch",
            json={
                "user_id": self.user_id,
                "client_id": self.client_id,
                "drives": drives
            }
        )
        response.raise_for_status()
        return response.json()
    
    def initialize_drives(self):
        """Initialize app by detecting and registering all drives"""
        print("Detecting drives...")
        
        # Detect drives
        detected_drives = self.detect_drives()
        print(f"Found {len(detected_drives)} drives")
        
        # Register all drives in one batch
        import time
        start_time = time.time()
        result = self.register_drives_batch(detected_drives)
        duration = (time.time() - start_time) * 1000
        
        print(f"Registered {result['count']} drives in {duration:.2f}ms")
        return result
    
    def detect_drives(self) -> List[Dict[str, Any]]:
        """Detect drives on the system"""
        import os
        drives = []
        
        # Fixed drives
        for mount_point in ['/', '/home']:
            if os.path.exists(mount_point):
                drives.append({
                    'mount_point': mount_point,
                    'drive_type': 'fixed',
                    'volume_label': mount_point.replace('/', '') or 'System',
                    'unique_identifier': f'mount:{mount_point}'
                })
        
        # USB drives
        usb_drives = self.detect_usb_drives()
        drives.extend(usb_drives)
        
        # Cloud storage
        cloud_drives = self.detect_cloud_drives()
        drives.extend(cloud_drives)
        
        return drives
    
    def detect_usb_drives(self) -> List[Dict[str, Any]]:
        """Detect USB drives"""
        # Platform-specific implementation
        return []
    
    def detect_cloud_drives(self) -> List[Dict[str, Any]]:
        """Detect cloud storage"""
        import os
        drives = []
        
        # Check for OneDrive
        onedrive_path = os.path.expanduser('~/OneDrive')
        if os.path.exists(onedrive_path):
            drives.append({
                'mount_point': onedrive_path,
                'drive_type': 'cloud',
                'volume_label': 'OneDrive',
                'cloud_provider': 'onedrive',
                'unique_identifier': f'onedrive:{self.user_id}'
            })
        
        return drives

# Usage
service = DriveService('http://localhost:5000', 'user123', 'laptop1')
service.initialize_drives()
```

## Error Handling

```javascript
async function registerDrivesWithErrorHandling(drives) {
  try {
    const response = await fetch('/api/file-organizer/drives/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: userId,
        client_id: clientId,
        drives: drives
      })
    });
    
    const data = await response.json();
    
    if (!data.success) {
      // Handle specific errors
      if (data.error.includes('array cannot be empty')) {
        console.warn('No drives to register');
        return [];
      }
      
      if (data.error.includes('DriveManager not available')) {
        console.error('Backend service not ready');
        // Retry after delay
        await new Promise(resolve => setTimeout(resolve, 1000));
        return registerDrivesWithErrorHandling(drives);
      }
      
      throw new Error(data.error);
    }
    
    return data.drives;
    
  } catch (error) {
    if (error.name === 'TypeError' && error.message.includes('fetch')) {
      console.error('Network error - backend not reachable');
      // Show user-friendly error
      showError('Cannot connect to server. Please check your connection.');
    } else {
      console.error('Failed to register drives:', error);
      showError('Failed to initialize drives. Please try again.');
    }
    
    throw error;
  }
}
```

## Testing

Run the test script to verify the batch endpoint:

```bash
# Make sure backend is running
cd backend
python main.py

# In another terminal, run the test
python file_organizer/test_batch_drive_registration.py
```

Expected output:
```
============================================================
Testing Batch Drive Registration
============================================================

1. Testing batch registration (5 drives)...
   Status: 201
   Duration: 45.23ms
   ✓ Success: True
   ✓ Count: 5
   ✓ Drives registered: 5
      - System (fixed) at /
      - Home (fixed) at /home
      - USB Drive 1 (usb) at /media/usb1
      - USB Drive 2 (usb) at /media/usb2
      - OneDrive (cloud) at /home/user/OneDrive

2. Verifying drives were saved...
   ✓ Total drives in database: 5
   ✓ System: /
   ✓ Home: /home
   ✓ USB Drive 1: /media/usb1
   ✓ USB Drive 2: /media/usb2
   ✓ OneDrive: /home/user/OneDrive

6. Performance comparison...
   Old approach (5 individual requests):
      Duration: 234.56ms
   New approach (1 batch request):
      Duration: 45.23ms
   ✓ Performance improvement: 80.7%
   ✓ Time saved: 189.33ms

============================================================
All tests completed successfully!
============================================================
```

## API Reference

See [API_ENDPOINTS.md](API_ENDPOINTS.md#post-apifile-organizerdrivesbatch) for complete API documentation.

## Backward Compatibility

The old single-drive endpoint (`POST /api/file-organizer/drives`) is still available for backward compatibility but is marked as deprecated. Migrate to the batch endpoint for better performance.
