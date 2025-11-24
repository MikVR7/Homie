# DestinationMemoryManager

A comprehensive manager class for handling all destination-related operations in the File Organizer.

## Overview

The `DestinationMemoryManager` provides a clean API for:
- Managing destination CRUD operations
- Tracking usage statistics
- Auto-capturing destinations from file operations
- Extracting categories from paths
- Generating usage analytics

## Installation

The class is ready to use after running the database migrations:

```python
from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
manager = DestinationMemoryManager(db_path)
```

## API Reference

### get_destinations(user_id: str) -> List[Destination]

Retrieve all active destinations for a user.

**Parameters:**
- `user_id` (str): User identifier

**Returns:**
- List of `Destination` objects ordered by usage_count DESC, last_used_at DESC

**Example:**
```python
destinations = manager.get_destinations("user123")
for dest in destinations:
    print(f"{dest.path} - Used {dest.usage_count} times")
```

---

### add_destination(user_id: str, path: str, category: str, client_id: str, drive_id: Optional[str] = None) -> Optional[Destination]

Manually add a new destination or return existing one.

**Parameters:**
- `user_id` (str): User identifier
- `path` (str): Destination folder path
- `category` (str): File category for this destination
- `client_id` (str): Client/laptop identifier reporting this destination
- `drive_id` (Optional[str]): Drive identifier (auto-detected if None)

**Returns:**
- `Destination` object if successful, `None` on error

**Features:**
- Validates path format
- Normalizes paths (resolves to absolute)
- Returns existing destination if duplicate
- Generates UUID automatically

**Example:**
```python
destination = manager.add_destination(
    user_id="user123",
    path="/home/user/Documents/Invoices",
    category="invoice"
)

if destination:
    print(f"Added: {destination.path}")
```

---

### remove_destination(user_id: str, destination_id: str) -> bool

Mark a destination as inactive (soft delete).

**Parameters:**
- `user_id` (str): User identifier
- `destination_id` (str): Destination UUID

**Returns:**
- `True` if successful, `False` if not found

**Note:** This is a soft delete - the destination remains in the database for audit trail but won't appear in active queries.

**Example:**
```python
success = manager.remove_destination("user123", destination_id)
if success:
    print("Destination removed")
```

---

### get_destinations_by_category(user_id: str, category: str) -> List[Destination]

Get all active destinations for a specific category.

**Parameters:**
- `user_id` (str): User identifier
- `category` (str): File category (case-insensitive)

**Returns:**
- List of `Destination` objects ordered by usage

**Example:**
```python
invoices = manager.get_destinations_by_category("user123", "invoice")
print(f"Found {len(invoices)} invoice destinations")
```

---

### auto_capture_destinations(user_id: str, operations: List[Dict[str, Any]], client_id: str) -> List[Destination]

Automatically extract and capture destination paths from file operations.

**Parameters:**
- `user_id` (str): User identifier
- `operations` (List[Dict]): File operations with 'dest' or 'destination' keys
- `client_id` (str): Client/laptop identifier reporting these operations

**Returns:**
- List of newly captured `Destination` objects

**Features:**
- Extracts unique destination folder paths
- Skips already-known destinations
- Auto-extracts category from path
- Auto-detects drive type

**Example:**
```python
operations = [
    {"type": "move", "src": "/tmp/file1.pdf", "dest": "/home/user/Documents/Invoices/file1.pdf"},
    {"type": "move", "src": "/tmp/file2.pdf", "dest": "/home/user/Documents/Invoices/file2.pdf"},
    {"type": "copy", "src": "/tmp/file3.jpg", "dest": "/home/user/Pictures/Vacation/file3.jpg"},
]

captured = manager.auto_capture_destinations("user123", operations)
print(f"Captured {len(captured)} new destinations")
```

---

### extract_category_from_path(path: str) -> str

Extract category name from a file path using the last folder name.

**Parameters:**
- `path` (str): File system path

**Returns:**
- Category name (title-cased) or "Uncategorized"

**Examples:**
```python
manager.extract_category_from_path("/home/user/Videos/Movies")
# Returns: "Movies"

manager.extract_category_from_path("/home/user/Documents/Work/Projects")
# Returns: "Projects"

manager.extract_category_from_path("/home/user/my_folder")
# Returns: "My Folder"

manager.extract_category_from_path("")
# Returns: "Uncategorized"
```

---

### get_drive_for_path(user_id: str, client_id: str, path: str) -> Optional[str]

Determine the drive_id for a given path on a specific client.

**Parameters:**
- `user_id` (str): User identifier
- `client_id` (str): Client/laptop identifier
- `path` (str): File system path

**Returns:**
- Drive UUID or `None` if no matching drive found

**Features:**
- Checks client-specific mount points from `drive_client_mounts` table
- Returns drive with longest matching mount point
- Ensures accurate path-to-drive matching per client

**Example:**
```python
drive_id = manager.get_drive_for_path("/media/usb/Documents")
# Returns: drive UUID or None
```

---

### get_destinations_for_client(user_id: str, client_id: str) -> List[Destination]

Get destinations that are accessible from a specific client.

**Parameters:**
- `user_id` (str): User identifier
- `client_id` (str): Client/laptop identifier

**Returns:**
- List of `Destination` objects accessible from this client

**Filtering Logic:**
- Returns destinations where:
  - `drive_id` is NULL (local paths, no drive tracking)
  - Drive type is 'cloud' (accessible from all clients)
  - Drive has an available mount on this client

**Example:**
```python
# Get destinations accessible from laptop1
destinations = manager.get_destinations_for_client("user123", "laptop1")

# Only shows:
# - Destinations on drives mounted on laptop1
# - Cloud storage destinations (accessible from all)
# - Local destinations (no drive tracking)
```

---

### update_usage(destination_id: str, file_count: int = 1, operation_type: str = "move") -> bool

Update destination usage statistics.

**Parameters:**
- `destination_id` (str): Destination UUID
- `file_count` (int): Number of files in operation (default: 1)
- `operation_type` (str): Operation type - 'move' or 'copy' (default: "move")

**Returns:**
- `True` if successful, `False` on error

**Actions:**
- Increments `usage_count` in destinations table
- Updates `last_used_at` to current timestamp
- Inserts record into `destination_usage` table

**Example:**
```python
success = manager.update_usage(
    destination_id=dest.id,
    file_count=5,
    operation_type="move"
)
```

---

### get_usage_analytics(user_id: str) -> Dict[str, Any]

Get comprehensive usage analytics for a user's destinations.

**Parameters:**
- `user_id` (str): User identifier

**Returns:**
- Dictionary with analytics data:
  - `overall`: Overall statistics
  - `by_category`: Stats grouped by category
  - `most_used`: Top 10 most-used destinations

**Example:**
```python
analytics = manager.get_usage_analytics("user123")

print(f"Total destinations: {analytics['overall']['total_destinations']}")
print(f"Total uses: {analytics['overall']['total_uses']}")

for category in analytics['by_category']:
    print(f"{category['category']}: {category['total_uses']} uses")

for dest in analytics['most_used']:
    print(f"{dest['path']}: {dest['usage_count']} uses")
```

## Usage Patterns

### Pattern 1: Manual Destination Management

```python
from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from pathlib import Path

manager = DestinationMemoryManager(Path("backend/data/modules/homie_file_organizer.db"))

# Add destinations
invoice_dest = manager.add_destination(
    user_id="user123",
    path="/home/user/Documents/Invoices",
    category="invoice"
)

receipt_dest = manager.add_destination(
    user_id="user123",
    path="/home/user/Documents/Receipts",
    category="receipt"
)

# Get all destinations
all_destinations = manager.get_destinations("user123")
print(f"User has {len(all_destinations)} destinations")

# Get by category
invoices = manager.get_destinations_by_category("user123", "invoice")
print(f"Found {len(invoices)} invoice destinations")
```

### Pattern 2: Auto-Capture from Operations

```python
# After file operations complete
operations = [
    {"type": "move", "src": "/tmp/file1.pdf", "dest": "/home/user/Documents/Invoices/2024/file1.pdf"},
    {"type": "move", "src": "/tmp/file2.pdf", "dest": "/home/user/Documents/Invoices/2024/file2.pdf"},
]

# Auto-capture new destinations
captured = manager.auto_capture_destinations("user123", operations)
print(f"Learned {len(captured)} new destinations")

# Update usage for known destinations
for dest in captured:
    manager.update_usage(dest.id, file_count=2, operation_type="move")
```

### Pattern 3: Usage Tracking

```python
# When organizing files
destination_id = "some-uuid"

# Update usage
manager.update_usage(
    destination_id=destination_id,
    file_count=5,
    operation_type="move"
)

# Get analytics
analytics = manager.get_usage_analytics("user123")
print(f"Most used: {analytics['most_used'][0]['path']}")
```

### Pattern 4: Smart Suggestions

```python
# Get popular destinations for a category
suggestions = manager.get_destinations_by_category("user123", "invoice")

# Sort by usage (already sorted by the method)
top_suggestion = suggestions[0] if suggestions else None

if top_suggestion:
    print(f"Suggested destination: {top_suggestion.path}")
    print(f"Used {top_suggestion.usage_count} times")
```

## Integration with PathMemoryManager

The `DestinationMemoryManager` can be integrated into `PathMemoryManager`:

```python
class PathMemoryManager:
    def __init__(self, event_bus, shared_services):
        # ... existing code ...
        self._destination_manager = None
    
    async def start(self):
        # ... existing code ...
        
        # Initialize destination manager
        from .destination_memory_manager import DestinationMemoryManager
        self._destination_manager = DestinationMemoryManager(self._db_path)
        
        logger.info("✅ DestinationMemoryManager initialized")
    
    def get_destination_manager(self):
        """Get the destination manager instance"""
        return self._destination_manager
```

## Error Handling

All methods handle errors gracefully:

- Invalid inputs return `None` or empty lists
- Database errors are logged and don't crash
- Duplicate operations are handled safely
- Missing records return appropriate defaults

**Example:**
```python
# Invalid path
dest = manager.add_destination("user123", "", "test")
# Returns: None (logged as error)

# Non-existent destination
success = manager.remove_destination("user123", "fake-id")
# Returns: False (logged as warning)

# Database error
destinations = manager.get_destinations("user123")
# Returns: [] (logged as error)
```

## Testing

Run the comprehensive test suite:

```bash
python3 backend/file_organizer/test_destination_memory_manager.py
```

Tests cover:
- ✅ Adding destinations
- ✅ Retrieving destinations
- ✅ Removing destinations (soft delete)
- ✅ Filtering by category
- ✅ Category extraction
- ✅ Auto-capture from operations
- ✅ Usage tracking
- ✅ Analytics generation

## Performance

- All queries use indexes for fast lookups
- Batch operations minimize database round-trips
- Soft deletes preserve audit trail without impacting queries
- Connection pooling compatible

## Future Enhancements

1. **Drive Integration**: Full integration with `DrivesManager` for path portability
2. **ML Predictions**: Use machine learning to predict best destinations
3. **Conflict Resolution**: Handle path conflicts when drives reconnect
4. **Batch Operations**: Bulk add/update methods for efficiency
5. **Caching**: In-memory cache for frequently accessed destinations
6. **Export/Import**: Backup and restore destination preferences

## See Also

- [DESTINATION_MEMORY.md](DESTINATION_MEMORY.md) - Database schema documentation
- [models.py](models.py) - Data models
- [migration_runner.py](migration_runner.py) - Migration system
