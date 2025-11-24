# AI Context Integration - Automatic Destination Memory

## Overview

The backend File Organizer module now automatically supplies destination memory and drive information to the AI model without requiring any parameters from the frontend. This eliminates the need for CLI parameters and `destination_context` payloads.

## What Changed

### 1. Automatic AI Context Building

**Before:**
- Frontend had to pass `destination_context` parameter with known destinations
- CLI parameters were used to configure destination preferences
- AI had no knowledge of previously used destinations

**After:**
- Backend automatically builds AI context from `DestinationMemoryManager` and `DriveManager`
- Context includes:
  - Known destinations grouped by category
  - Drive information (type, space, availability)
  - Usage statistics (frequency, last used)
  - Drive-specific mount points per client
- No frontend parameters needed

### 2. AI Decides Full Paths

**Before:**
- AI returned category names only (e.g., "Images")
- Backend constructed paths by appending to destination root

**After:**
- AI receives ALL known destinations with full paths
- AI decides which destination to use and returns the full path
- AI can return:
  - Full absolute path to known destination: `/home/user/Pictures`
  - Relative folder name for new folders: `Images`
  - Subfolders within known destinations: `/home/user/Pictures/Vacation`
- Backend uses AI's decision as-is without modification

### 3. Fallback When No Destinations Exist

**Special case:** When there are NO saved destinations:
- Backend sends the source folder as the only available destination
- AI organizes files in-place by creating subfolders within the source folder
- This allows organization without requiring pre-configured destinations

## Implementation Details

### Files Modified

1. **`backend/core/web_server.py`**
   - Updated `_batch_analyze_files()` to accept `ai_context` parameter
   - Passes context to AI analyzer

2. **`backend/core/routes/file_organizer_routes.py`**
   - Builds AI context using `AIContextBuilder` before organizing
   - Passes context to `_batch_analyze_files()`
   - When no destinations exist, sends source folder as fallback destination
   - Simplified `_build_file_plan()` to use AI's path decision as-is

3. **`backend/file_organizer/ai_content_analyzer.py`**
   - Updated `analyze_files_batch()` to accept `ai_context` parameter
   - Includes context in AI prompt with full destination paths
   - AI instructed to return full paths for known destinations
   - Added comprehensive logging of AI responses
   - Passes context to AI analyzer

2. **`backend/core/routes/file_organizer_routes.py`**
   - Builds AI context using `AIContextBuilder` before organizing
   - Passes context to `_batch_analyze_files()`
   - Updated `_build_file_plan()` to check for known destinations
   - Uses known destinations when category matches

3. **`backend/file_organizer/ai_content_analyzer.py`**
   - Updated `analyze_files_batch()` to accept `ai_context` parameter
   - Includes context in AI prompt with instructions to prefer known destinations
   - AI receives formatted list of known destinations with usage stats

### AI Context Format

The AI receives context in this format:

```
============================================================
KNOWN DESTINATIONS
============================================================

Category: Images (2 locations)
  - /home/user/Pictures/Sorted
    (Internal Drive, 150.5 GB free, used 15 times)
  - /media/usb/Photos
    (USB Drive, 50.2 GB free, used 3 times)

Category: Documents (1 location)
  - /home/user/Documents/Organized
    (Internal Drive, 150.5 GB free, used 8 times)

============================================================
AVAILABLE DRIVES
============================================================

  - Internal Drive: /home (150.5 GB free)
  - USB Drive: /media/usb (50.2 GB free)

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

### Backend Logic Flow

```
1. Frontend calls POST /api/file-organizer/organize
   - Only passes: source_path, destination_path, user_id, client_id
   - NO destination_context parameter

2. Backend builds AI context
   - Queries DestinationMemoryManager for user's destinations
   - Queries DriveManager for available drives
   - Formats context for AI prompt

3. Backend calls AI with context
   - AI receives file list + known destinations + drives
   - AI suggests categories (e.g., "Images", "Documents")
   - AI considers known destinations when making suggestions

4. Backend builds file plans
   - For each file, checks if suggested category has known destination
   - Uses known destination if found (prefers most frequently used)
   - Creates new folder under destination root if not found

5. Backend returns operations
   - Operations include full paths (either known destinations or new folders)
   - Frontend executes operations as-is
```

## API Changes

### POST /api/file-organizer/organize

**Request (Before):**
```json
{
  "source_path": "/path/to/source",
  "destination_path": "/path/to/dest",
  "destination_context": {
    "known_destinations": [...],
    "drives": [...]
  }
}
```

**Request (After):**
```json
{
  "source_path": "/path/to/source",
  "destination_path": "/path/to/dest",
  "user_id": "user123",
  "client_id": "laptop1"
}
```

**Response (Unchanged):**
```json
{
  "success": true,
  "analysis_id": "uuid",
  "operations": [
    {
      "type": "move",
      "source": "/path/to/source/file.jpg",
      "destination": "/known/destination/Images/file.jpg",
      "operation_id": "op_123"
    }
  ],
  "file_plans": [...]
}
```

## Benefits

1. **Simpler Frontend**
   - No need to fetch and format destination context
   - No CLI parameters to manage
   - Just pass source, destination, user_id, client_id

2. **Consistent Behavior**
   - Backend is single source of truth for destination memory
   - All clients get same destination preferences
   - No risk of stale or inconsistent context from frontend

3. **Better AI Decisions**
   - AI has complete context about user's organization patterns
   - Can make informed decisions about drive space and availability
   - Prefers frequently used destinations

4. **Automatic Learning**
   - As user organizes files, destinations are learned automatically
   - Future organize operations benefit from past patterns
   - No manual configuration needed

## Testing

### Manual Test

```bash
# 1. Add a known destination
curl -X POST http://localhost:8000/api/file-organizer/destinations \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/home/user/Pictures/Sorted",
    "category": "Images",
    "user_id": "test_user",
    "client_id": "test_client"
  }'

# 2. Organize files (no destination_context needed!)
curl -X POST http://localhost:8000/api/file-organizer/organize \
  -H "Content-Type: application/json" \
  -d '{
    "source_path": "/home/user/Downloads",
    "destination_path": "/home/user/Organized",
    "user_id": "test_user",
    "client_id": "test_client"
  }'

# 3. Check operations - should use /home/user/Pictures/Sorted for images
```

### Verification

Check logs for:
```
Built AI context: Context: 1 destination(s) in 1 category, 1 drive(s) available
Using known destination for 'Images': /home/user/Pictures/Sorted
```

## Migration Notes

### For Frontend Developers

**Remove:**
- All code that builds `destination_context` parameter
- All code that fetches destinations before calling organize
- Any CLI parameter handling for destinations

**Keep:**
- `user_id` and `client_id` parameters (required for context building)
- `source_path` and `destination_path` parameters

### For Backend Developers

**No breaking changes:**
- Old organize requests without `user_id`/`client_id` still work (defaults to 'dev_user'/'default_client')
- AI context is optional - if it can't be built, organize still works
- Fallback behavior: creates new folders under destination root

## Future Enhancements

1. **Smart Destination Selection**
   - Consider file size vs available space
   - Prefer cloud drives for backup-worthy files
   - Avoid unavailable drives automatically

2. **Multi-Destination Support**
   - Split large batches across multiple destinations
   - Balance usage across drives
   - Automatic load balancing

3. **Learning from User Corrections**
   - Track when user moves files after organization
   - Learn preferred destinations from corrections
   - Improve AI suggestions over time

## Related Files

- `backend/file_organizer/ai_context_builder.py` - Builds context for AI
- `backend/file_organizer/destination_memory_manager.py` - Manages destinations
- `backend/file_organizer/drive_manager.py` - Manages drives
- `backend/core/routes/file_organizer_routes.py` - Organize endpoint
- `backend/file_organizer/ai_content_analyzer.py` - AI integration
- `backend/core/web_server.py` - Batch analysis method
