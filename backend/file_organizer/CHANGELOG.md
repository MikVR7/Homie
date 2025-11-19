# File Organizer Changelog

## [Unreleased]

### Added - 2025-11-10

#### Batch Drive Registration
- New `/api/file-organizer/drives/batch` endpoint for registering multiple drives in one request
- ~80% performance improvement over sequential registration (5 drives: 250ms → 50ms)
- Atomic transactions ensure all-or-nothing behavior
- See `BATCH_DRIVE_REGISTRATION_EXAMPLE.md` for integration examples

### Fixed - 2025-11-19

#### Cascading Delete for Destinations
- Deleting a destination now automatically deactivates all child destinations
- Prevents orphaned child destinations when parent is deleted
- Example: Deleting `/tmp/Videos` now also deactivates `/tmp/Videos/Images`, `/tmp/Videos/Documents`, etc.
- See commit `36c6b83` for implementation details

#### Nested Files in Organization Operations
- Backend now processes all files sent by frontend, including those in subdirectories
- Preserves relative subfolder structure in destination paths
- Files without AI analysis results get fallback "Uncategorized" operation instead of being dropped
- Added diagnostic logging to track input vs output file counts
- Example: `Source/Test/file.txt` → `Dest/Category/Test/file.txt` (preserves `Test/` subfolder)
- See commit `d7ff262` for implementation details

### Added - 2025-11-19

#### Documentation
- Added FRONTEND_INTEGRATION_GUIDE.md with correct API endpoint usage examples
- Updated DRIVE_MANAGER.md with test coverage details

---

## Previous Changes

For changes before 2025-11-19, see git history:
```bash
git log --oneline backend/file_organizer/
```
