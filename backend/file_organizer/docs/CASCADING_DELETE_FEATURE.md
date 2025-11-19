# Cascading Delete Feature

**Implemented:** November 19, 2025  
**Author:** Development Team  
**Status:** ✅ Completed and Tested

## Overview

This document describes the cascading delete feature implemented for the Destination Management system in the File Organizer module.

## Problem Statement

Users were experiencing confusing behavior when deleting destination folders:

1. A user deleted `/tmp/Videos` folder
2. Subsequent file-sorting operations created new destinations inside that path:
   - `/tmp/Videos/Images`
   - `/tmp/Videos/Documents`
   - `/tmp/Videos/Software`
3. The UI showed `/tmp/Videos` as a non-deletable parent folder (because it wasn't returned as an active destination)
4. The delete button was disabled, leaving users unable to clean up these nested destinations

## Root Cause

When a destination was deleted (marked as `is_active = 0`), any child destinations that were created later remained active. This created an inconsistent state where:
- The parent destination was inactive
- Child destinations under that path were still active
- The UI couldn't delete the parent because it wasn't in the active destinations list

## Solution: Cascading Delete

### Implementation

The `remove_destination()` method in `DestinationMemoryManager` was enhanced to implement cascading delete:

```python
def remove_destination(self, user_id: str, destination_id: str) -> bool:
    """
    Remove (deactivate) a destination and all its child destinations.
    
    This implements cascading delete: when a destination is removed,
    all destinations whose paths are children of this destination
    are also deactivated.
    """
```

### How It Works

1. **Fetch the destination path** being deleted
2. **Normalize the path** to ensure consistent matching
3. **Deactivate the destination** itself
4. **Cascade to children**: Deactivate all destinations where:
   - `user_id` matches
   - `is_active = 1` (currently active)
   - `path LIKE '{parent_path}/%'` (is a child of the deleted destination)

### SQL Implementation

```sql
-- Deactivate the parent destination
UPDATE destinations
SET is_active = 0
WHERE id = ? AND user_id = ?

-- Cascade: deactivate all child destinations
UPDATE destinations
SET is_active = 0
WHERE user_id = ? 
  AND is_active = 1
  AND (path LIKE ? OR path LIKE ?)
```

The LIKE pattern uses `{path}/%` to match only children (paths that start with the parent path followed by a slash).

## Immediate Fix Applied

For the user's immediate issue, all destinations under `/tmp/` were manually deactivated:

```sql
UPDATE destinations 
SET is_active = 0 
WHERE user_id = 'dev_user' AND path LIKE '/tmp/%'
```

This resolved the UI confusion and allowed the user to start fresh.

## Testing

Comprehensive tests were created in `test_cascading_delete.py`:

### Test 1: Basic Cascading Delete
- Creates a parent destination: `/home/user/Videos`
- Creates child destinations:
  - `/home/user/Videos/Movies`
  - `/home/user/Videos/TV Shows`
  - `/home/user/Videos/Movies/Action` (nested)
- Creates an unrelated destination: `/home/user/Documents`
- Deletes the parent
- Verifies:
  - Parent and all children are deactivated
  - Unrelated destination remains active

### Test 2: /tmp Path Cascading Delete
- Simulates the user's exact scenario
- Creates `/tmp/Videos` with child destinations
- Deletes the parent
- Verifies all are deactivated

### Test Results
```
✅ Cascading delete test PASSED!
✅ /tmp cascading delete test PASSED!
🎉 All tests passed!
```

## Benefits

1. **Consistent Behavior**: Deleting a parent destination now properly cleans up all child destinations
2. **Better UX**: Users won't encounter confusing states where child destinations remain after parent deletion
3. **Data Integrity**: Prevents orphaned child destinations that reference non-existent parent paths
4. **Intuitive**: Matches user expectations - deleting a folder should delete everything inside it

## API Impact

The DELETE `/destinations/{id}` endpoint now automatically cascades the delete operation to child destinations. No API changes are required - the behavior is enhanced transparently.

## Future Considerations

1. **Soft Delete Retention**: Consider adding a `deleted_at` timestamp for audit trails
2. **Undo Functionality**: Could implement restoration of cascaded deletes
3. **User Notification**: Could notify users when cascading delete affects multiple destinations
4. **Selective Cascade**: Could add an option to delete parent without cascading (if needed)

## Related Files

- `backend/file_organizer/destination_memory_manager.py` - Implementation
- `backend/file_organizer/test_cascading_delete.py` - Tests
- `backend/core/routes/destination_routes.py` - API endpoint
