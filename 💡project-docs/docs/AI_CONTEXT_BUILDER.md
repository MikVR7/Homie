# AIContextBuilder - AI Prompt Context Preparation

## Overview

The AIContextBuilder prepares comprehensive context about destinations and drives for AI requests. It formats this information in a way that helps the AI make intelligent decisions about file organization.

## Purpose

When the AI needs to organize files, it should:
1. **Prefer known destinations** that the user has used before
2. **Consider drive availability** and space
3. **Respect usage patterns** (frequently used destinations)
4. **Choose appropriate drive types** for different file types

The AIContextBuilder provides all this information in a clear, structured format.

## Architecture

```
┌─────────────────────────┐
│  DestinationMemoryMgr   │
│  (Known destinations)   │
└───────────┬─────────────┘
            │
            ├──────────────┐
            │              │
            ▼              ▼
    ┌───────────────┐  ┌──────────────┐
    │ DriveManager  │  │ os.statvfs() │
    │ (Drive info)  │  │ (Disk space) │
    └───────┬───────┘  └──────┬───────┘
            │                 │
            └────────┬────────┘
                     ▼
            ┌─────────────────┐
            │ AIContextBuilder│
            └────────┬────────┘
                     │
                     ├─────────────────┐
                     ▼                 ▼
            ┌──────────────┐   ┌──────────────┐
            │ Structured   │   │ Natural      │
            │ Context Dict │   │ Language     │
            └──────────────┘   └──────────────┘
```

## API Reference

### __init__(destination_manager, drive_manager)

Initialize the AIContextBuilder.

**Parameters**:
- `destination_manager`: DestinationMemoryManager instance
- `drive_manager`: DriveManager instance

**Example**:
```python
from backend.file_organizer.ai_context_builder import AIContextBuilder
from backend.file_organizer.destination_memory_manager import DestinationMemoryManager
from backend.file_organizer.drive_manager import DriveManager
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
dest_manager = DestinationMemoryManager(db_path)
drive_manager = DriveManager(db_path)

builder = AIContextBuilder(dest_manager, drive_manager)
```

---

### build_context(user_id: str, client_id: str) -> Dict[str, Any]

Build complete context for AI including destinations and drives.

**Parameters**:
- `user_id`: User identifier
- `client_id`: Client/laptop identifier

**Returns**: Dictionary with structure:
```python
{
    "known_destinations": [
        {
            "category": "Movies",
            "paths": [
                {
                    "path": "/home/user/Videos/Movies",
                    "drive_type": "internal",
                    "drive_label": "System",
                    "available_space_gb": 250.5,
                    "is_available": True,
                    "usage_count": 15,
                    "last_used": "2025-10-20T14:30:00Z",
                    "cloud_provider": None
                }
            ]
        }
    ],
    "drives": [
        {
            "id": "drive-uuid-123",
            "type": "internal",
            "mount_point": "/",
            "volume_label": "System",
            "available_space_gb": 500.0,
            "is_available": True,
            "cloud_provider": None
        }
    ]
}
```

**Example**:
```python
context = builder.build_context("user123", "laptop1")

# Access destinations
for category_info in context['known_destinations']:
    print(f"Category: {category_info['category']}")
    for path_info in category_info['paths']:
        print(f"  - {path_info['path']} (used {path_info['usage_count']} times)")

# Access drives
for drive in context['drives']:
    print(f"Drive: {drive['volume_label']} ({drive['available_space_gb']} GB free)")
```

---

### format_for_ai_prompt(context: Dict[str, Any]) -> str

Convert context dict to natural language for AI prompt.

**Parameters**:
- `context`: Context dictionary from `build_context()`

**Returns**: Formatted string suitable for AI prompt

**Example Output**:
```
============================================================
KNOWN DESTINATIONS
============================================================

Category: Movies (2 locations)
  - /home/user/Videos/Movies
    (System (Internal), 250.5 GB free, used 15 times)
  - /media/usb/Movies
    (Backup Drive (Usb), 50.0 GB free, used 3 times)

Category: Documents (1 location)
  - /home/user/OneDrive/Documents
    (Onedrive Cloud, used 42 times)

============================================================
AVAILABLE DRIVES
============================================================

  - System: / (500.0 GB free)
  - Backup Drive: /media/usb (50.0 GB free)
  - Onedrive Cloud: /home/user/OneDrive

============================================================
INSTRUCTIONS FOR FILE ORGANIZATION
============================================================

When organizing files, prefer using these known destinations when appropriate.

If multiple destinations exist for a category, choose based on:
  1. Drive availability (avoid unavailable drives)
  2. Available space (ensure sufficient space for files)
  3. Usage frequency (prefer frequently used destinations)
  4. Drive type:
     - Internal drives: Best for frequently accessed files
     - Cloud drives: Good for backup and sync across devices
     - USB drives: Suitable for portable storage

If no suitable known destination exists, suggest creating a new one.
```

**Example**:
```python
context = builder.build_context("user123", "laptop1")
prompt_text = builder.format_for_ai_prompt(context)

# Use in AI request
ai_prompt = f"""
You are organizing files for a user.

{prompt_text}

Files to organize:
- movie1.mp4 (5 GB)
- movie2.mp4 (3 GB)

Please suggest where to organize these files.
"""
```

---

### build_context_summary(user_id: str, client_id: str) -> str

Build a brief summary of context for logging/debugging.

**Returns**: Brief summary string like:
```
"Context: 5 destination(s) in 3 categories, 2 drive(s) available"
```

**Example**:
```python
summary = builder.build_context_summary("user123", "laptop1")
logger.info(f"AI context prepared: {summary}")
```

## Usage Patterns

### Pattern 1: Basic AI Request

```python
# Initialize
builder = AIContextBuilder(dest_manager, drive_manager)

# Build context
context = builder.build_context(user_id, client_id)
prompt_text = builder.format_for_ai_prompt(context)

# Send to AI
ai_response = call_ai_service(f"""
{prompt_text}

Files to organize:
{file_list}

Please suggest organization.
""")
```

### Pattern 2: With Logging

```python
# Build context with logging
summary = builder.build_context_summary(user_id, client_id)
logger.info(f"Building AI context: {summary}")

context = builder.build_context(user_id, client_id)
prompt_text = builder.format_for_ai_prompt(context)

logger.debug(f"AI prompt length: {len(prompt_text)} characters")
```

### Pattern 3: Conditional Context

```python
# Only include context if user has destinations
context = builder.build_context(user_id, client_id)

if context['known_destinations']:
    # User has history - include it
    prompt_text = builder.format_for_ai_prompt(context)
else:
    # New user - skip context
    prompt_text = "No known destinations yet. Suggest new organization structure."
```

## Context Features

### 1. Destination Grouping

Destinations are grouped by category and sorted by usage:

```python
# Most used categories appear first
# Within each category, most used paths appear first
known_destinations = [
    {
        "category": "Movies",  # Used 18 times total
        "paths": [
            {"path": "/home/user/Videos/Movies", "usage_count": 15},
            {"path": "/media/usb/Movies", "usage_count": 3}
        ]
    },
    {
        "category": "Documents",  # Used 10 times total
        "paths": [...]
    }
]
```

### 2. Drive Space Information

Real-time available space using `os.statvfs()`:

```python
{
    "available_space_gb": 250.5,  # Actual free space
    "is_available": True           # Drive is mounted
}
```

### 3. Cloud Drive Detection

Cloud drives are identified and formatted appropriately:

```python
{
    "drive_type": "cloud",
    "cloud_provider": "onedrive",
    # Formatted as: "Onedrive Cloud" in prompt
}
```

### 4. Unavailable Drive Marking

Offline drives are clearly marked:

```
  - /media/usb/Movies
    (Backup Drive (Usb), ⚠️ UNAVAILABLE)
```

### 5. Client-Specific Context

Context is tailored to the specific client:
- Only shows drives mounted on that client
- Only shows destinations accessible from that client
- Uses client-specific mount points

## AI Decision Guidelines

The formatted prompt includes instructions for the AI:

### Priority Order

1. **Drive Availability**: Never suggest unavailable drives
2. **Available Space**: Ensure sufficient space for files
3. **Usage Frequency**: Prefer frequently used destinations
4. **Drive Type**: Match drive type to file type

### Drive Type Recommendations

- **Internal Drives**: Frequently accessed files (documents, projects)
- **Cloud Drives**: Backup, sync across devices (photos, documents)
- **USB Drives**: Portable storage, backups (archives, media)

### Fallback Behavior

If no suitable known destination exists:
- AI should suggest creating a new destination
- Consider file type and size
- Recommend appropriate drive type

## Integration Example

### In AI Command Generator

```python
class AICommandGenerator:
    def __init__(self, event_bus, shared_services):
        # ... existing code ...
        self.context_builder = None
    
    async def start(self):
        # ... existing code ...
        
        # Initialize context builder
        from .ai_context_builder import AIContextBuilder
        self.context_builder = AIContextBuilder(
            self.path_memory_manager.get_destination_manager(),
            self.path_memory_manager.get_drive_manager()
        )
    
    def generate_operations(self, folder_path, user_id, client_id, intent=None):
        # Build context
        context = self.context_builder.build_context(user_id, client_id)
        context_text = self.context_builder.format_for_ai_prompt(context)
        
        # Build AI prompt
        prompt = f"""
{context_text}

Folder to organize: {folder_path}
User intent: {intent or 'Auto-organize'}

Please suggest file operations.
"""
        
        # Call AI
        return self._call_ai(prompt)
```

## Performance Considerations

### Disk Space Queries

- `os.statvfs()` is called for each drive
- Cached for the duration of the request
- Fails gracefully if mount point doesn't exist

### Database Queries

- Single query for destinations (with client filter)
- Single query for drives (with client filter)
- Efficient with proper indexes

### Context Size

- Typical context: 1-2 KB
- Scales with number of destinations
- Consider truncating for very large contexts

## Error Handling

All methods handle errors gracefully:

```python
# If destination query fails
context = {
    'known_destinations': [],  # Empty list
    'drives': []
}

# If disk space query fails
available_space_gb = None  # Not shown in prompt

# If formatting fails
formatted = "Error: Could not format context for AI."
```

## Testing

Run the test suite:
```bash
python3 backend/file_organizer/test_ai_context_builder.py
```

Tests cover:
- ✅ Building context with destinations and drives
- ✅ Formatting for AI prompt
- ✅ Handling unavailable drives
- ✅ Context summary generation
- ✅ Empty context (new user)
- ✅ Cloud drive formatting

## See Also

- [DESTINATION_MEMORY_MANAGER.md](DESTINATION_MEMORY_MANAGER.md) - Destination management
- [DRIVE_MANAGER.md](DRIVE_MANAGER.md) - Drive tracking
- [MULTI_CLIENT_SUPPORT.md](MULTI_CLIENT_SUPPORT.md) - Multi-client architecture
