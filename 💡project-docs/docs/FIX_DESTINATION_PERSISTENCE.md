# Fix: Destination Persistence and Reactivation

## Problem

The Avalonia frontend was experiencing a regression where:

1. **POST `/api/file-organizer/destinations`** returned a destination with blank/incorrect fields:
   - `is_active` was `false` instead of `true`
   - Path, category, and drive fields appeared to be missing or incorrect

2. **GET `/api/file-organizer/destinations`** returned an empty list immediately after POST

3. Existing destinations were being wiped out between requests

## Root Cause

The issue was in `DestinationMemoryManager.add_destination()` method. When a destination path already existed in the database (even if it was soft-deleted with `is_active=0`), the method would:

1. Find the existing record
2. Return it as-is without checking or updating the `is_active` flag
3. This caused soft-deleted destinations to be returned with `is_active=false`
4. The GET endpoint filters out inactive destinations, so they wouldn't appear in the list

## Solution

Modified `DestinationMemoryManager.add_destination()` to automatically reactivate soft-deleted destinations:

```python
existing = cursor.fetchone()
if existing:
    # If destination exists but is inactive, reactivate it
    if not existing['is_active']:
        logger.info(f"Reactivating inactive destination: {normalized_path}")
        conn.execute("""
            UPDATE destinations
            SET is_active = 1, last_used_at = ?
            WHERE id = ?
        """, (datetime.now().isoformat(), existing['id']))
        conn.commit()
        
        # Fetch the updated destination
        cursor = conn.execute("""
            SELECT id, user_id, path, category, drive_id,
                   created_at, last_used_at, usage_count, is_active
            FROM destinations
            WHERE id = ?
        """, (existing['id'],))
        existing = cursor.fetchone()
    else:
        logger.info(f"Destination already exists: {normalized_path}")
    
    return Destination.from_db_row(existing)
```

## Changes Made

**File:** `backend/file_organizer/destination_memory_manager.py`
- **Lines 121-141:** Added reactivation logic for soft-deleted destinations

**File:** `backend/file_organizer/CHANGELOG.md`
- Added entry documenting the fix

**File:** `backend/file_organizer/test_destination_reactivation.py`
- Created comprehensive test to prevent regression

## Testing

### Unit Test
Run the test suite:
```bash
python3 backend/file_organizer/test_destination_reactivation.py
```

Expected output:
```
Test 1: Add new destination
  ✓ Created destination: id=..., is_active=True

Test 2: Verify destination appears in get_destinations
  ✓ Found 1 destination(s)

Test 3: Soft delete destination
  ✓ Removed destination ...

Test 4: Verify destination doesn't appear after deletion
  ✓ Found 0 destination(s) (correctly filtered out inactive)

Test 5: Re-add deleted destination (should reactivate)
  ✓ Reactivated destination: id=..., is_active=True

Test 6: Verify reactivated destination appears in get_destinations
  ✓ Found 1 destination(s)

✅ All tests passed!
```

### Integration Test
Test the API endpoints:

```bash
# 1. POST a new destination
curl -X POST http://localhost:8000/api/file-organizer/destinations \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/destination", "category": "TestCategory"}'

# Expected: Returns destination with is_active=true and all fields populated

# 2. GET destinations immediately after
curl -X GET http://localhost:8000/api/file-organizer/destinations

# Expected: Returns list containing the newly created destination

# 3. DELETE the destination
curl -X DELETE http://localhost:8000/api/file-organizer/destinations/{destination_id}

# 4. GET destinations after delete
curl -X GET http://localhost:8000/api/file-organizer/destinations

# Expected: Returns empty list (destination is soft-deleted)

# 5. POST the same destination again
curl -X POST http://localhost:8000/api/file-organizer/destinations \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/destination", "category": "TestCategory"}'

# Expected: Returns the same destination with is_active=true (reactivated)

# 6. GET destinations after reactivation
curl -X GET http://localhost:8000/api/file-organizer/destinations

# Expected: Returns list containing the reactivated destination
```

## Verification

✅ POST returns fully populated destination with `is_active=true`
✅ GET returns the newly created destination immediately after POST
✅ Destinations persist across requests
✅ Soft-deleted destinations are automatically reactivated when re-added
✅ All fields (id, path, category, drive_id, etc.) are properly populated

## Impact

- **Frontend:** No changes required - the API now works as expected
- **Backend:** Destinations are properly managed with soft-delete and reactivation
- **Database:** No schema changes required
- **Performance:** Minimal impact - one additional UPDATE query when reactivating

## Related Files

- `backend/file_organizer/destination_memory_manager.py` - Core fix
- `backend/core/routes/destination_routes.py` - API endpoints
- `backend/file_organizer/test_destination_reactivation.py` - Test suite
- `backend/file_organizer/CHANGELOG.md` - Documentation
