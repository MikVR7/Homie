# USB Drive Memory System - SIMPLE Drive Recognition

## 🎯 **What This System Does**

**SIMPLE**: Just recognizes your USB stick when you plug it back in. No bullshit.

- ✅ **Finds your USB stick by hardware ID** (doesn't change unless formatted)  
- ✅ **Remembers the same stick when plugged back in**
- ✅ **Tracks where it's currently mounted**
- ✅ **NO purpose nonsense** - it's YOUR drive, YOU decide what to put on it
- ✅ **NO file_types nonsense** - it's an external drive, live with it!

## 📊 **What Information is Stored (MINIMAL)**

### **Database Schema: `user_drives` Table**

```sql
CREATE TABLE user_drives (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    drive_path TEXT NOT NULL,                -- Current mount path (changes)
    drive_type TEXT NOT NULL,                -- 'usb', 'local', 'network', 'cloud'
    drive_label TEXT,                        -- Readable label (e.g., "sda1")
    usb_serial_number TEXT,                  -- Hardware USB serial (PERMANENT ID)
    partition_uuid TEXT,                     -- Filesystem UUID (changes on format)
    identifier_type TEXT NOT NULL,           -- 'usb_serial', 'partition_uuid', 'label_size'
    primary_identifier TEXT NOT NULL,        -- The actual identifier used
    is_connected BOOLEAN DEFAULT 0,          -- Currently connected?
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, primary_identifier)
);
```

### **Example Stored Data**

```json
{
  "id": 1,
  "user_id": "7e95f555-5cb0-42b1-909b-eaadbf85f8a4",
  "drive_path": "/dev/sda1",
  "drive_type": "usb",
  "drive_label": "sda1",
  "usb_serial_number": "0401328cd2e003b97b98c92e91012659eda852bb",
  "partition_uuid": "4E21-0000",
  "identifier_type": "usb_serial",
  "primary_identifier": "0401328cd2e003b97b98c92e91012659eda852bb",
  "is_connected": true,
  "last_used": "2025-08-04T18:43:49.440",
  "created_at": "2025-08-04T15:30:00.000"
}
```

## 🆔 **Drive Identification Strategy (RELIABLE)**

### **1. 🥇 USB Serial Number (BEST)**
- **Hardware-based identifier** - doesn't change unless firmware is rewritten
- **Cross-platform reliable** - works on Linux, macOS, Windows
- **Example**: `0401328cd2e003b97b98c92e91012659eda852bb`

### **2. 🥈 Partition UUID (GOOD)**  
- **Filesystem-based identifier** - changes only when drive is formatted
- **Stable otherwise** - survives reboots, different mount points
- **Example**: `4E21-0000`

### **3. 🥉 Label + Size (FALLBACK)**
- **User can change label** - least reliable but still useful
- **Last resort** when hardware IDs aren't available
- **Example**: `sda1_16000000000` (label_size)

## 🔄 **SIMPLE Drive Registration Process**

### **Step 1: Just Register The Drive (NO BULLSHIT)**
```bash
curl -X POST http://localhost:8000/api/file-organizer/register-usb-drive \
  -H "Content-Type: application/json" \
  -d '{
    "drive_path": "/dev/sda1"
  }'
```

### **Step 2: System Processing**
1. **Hardware ID Detection**: Gets USB serial number using `udevadm` and `lsusb`
2. **Fallback IDs**: Gets partition UUID and label+size as backups
3. **Database Storage**: Stores minimal info in `user_drives` table  
4. **Confirmation**: Returns success with identifier type and confidence

### **Step 3: Recognition**
- **Plug USB back in**: System recognizes it by hardware ID
- **Updates mount path**: Tracks current `/dev/sdX1` or `/media/usb1`
- **YOU navigate to YOUR folders**: No AI suggestions, just find your drive
- **User Isolation**: Each user has their own drive memory
- **Cross-Session**: Memory persists across app restarts
- **Disconnected Drives**: System remembers drives even when not connected

## 📱 **How to Use**

**1. Plug in your USB stick**
**2. Register it once:**
```bash
curl -X POST http://localhost:8000/api/file-organizer/register-usb-drive \
  -d '{"drive_path": "/dev/sda1"}'
```
**3. System remembers it forever**
**4. Navigate to YOUR folders and work with YOUR files**

**That's it!** No AI suggestions, no purpose nonsense, just USB stick recognition.

## 🔧 **Technical Implementation**

### **USB Serial Number Extraction (Linux)**
```python
def _get_usb_serial_number(self, mount_path: str) -> Optional[str]:
    # Find block device: df /dev/sda1 → /dev/sda1
    result = subprocess.run(['df', mount_path], capture_output=True, text=True, check=True)
    device_line = result.stdout.splitlines()[1]
    block_device = device_line.split()[0] # /dev/sda1
    
    # Get parent device: /dev/sda1 → /dev/sda  
    parent_device = block_device.rstrip('0123456789')
    
    # Get hardware serial: udevadm info --name=/dev/sda --attribute-walk
    result = subprocess.run(
        ['udevadm', 'info', '--name', parent_device, '--attribute-walk'],
        capture_output=True, text=True, check=True
    )
    
    # Extract ATTRS{serial} or ATTRS{idSerial}
    for line in result.stdout.splitlines():
        if 'ATTRS{serial}==' in line:
            return line.split('==')[1].strip('"')
```

### **Partition UUID Extraction**
```python
def _get_partition_uuid(self, mount_path: str) -> Optional[str]:
    # Get filesystem UUID: blkid -s UUID -o value /dev/sda1
    result = subprocess.run(['blkid', '-s', 'UUID', '-o', 'value', mount_path], 
                           capture_output=True, text=True, check=True)
    return result.stdout.strip()
```

## 📁 **API Endpoints**

### **Register USB Drive**
```bash
POST /api/file-organizer/register-usb-drive
Content-Type: application/json

{"drive_path": "/dev/sda1"}
```

### **Get USB Drives Memory**
```bash
GET /api/file-organizer/usb-drives
```

---

**Updated:** 2025-08-04  
**Status:** ✅ COMPLETE - Simple USB recognition without bullshit 