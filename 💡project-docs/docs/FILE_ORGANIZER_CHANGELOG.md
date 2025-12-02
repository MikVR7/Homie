# File Organizer Changelog

## [Unreleased]

### Added - 2025-11-25

#### Enhanced File Metadata Support (v2.0)
- `/api/file-organizer/organize` now accepts rich file metadata alongside file paths
- Supports 6 metadata types: Image, Video, Audio, Document, Archive, Source Code
- AI uses metadata for 50-70% more specific folder suggestions
- Image metadata: date_taken, camera_model, location → organize by trip/event
- Archive metadata: contents, detected_project_type → extract to proper project folders
- Document metadata: author, title → organize by company/category
- 100% backward compatible with existing clients
- New Pydantic models for type-safe request validation
- See `💡project-docs/docs/ENHANCED_METADATA_SUPPORT.md` for details
- See `💡project-docs/docs/METADATA_EXAMPLES.json` for example requests

#### Multi-Provider AI Support
- Added support for Kimi K2 (Moonshot AI) as alternative to Google Gemini
- Switch providers via `AI_PROVIDER` environment variable (`gemini` or `kimi`)
- Unified `AIModelWrapper` provides consistent interface for all providers
- Easy to add new providers in the future
- See `💡project-docs/docs/AI_PROVIDER_CONFIGURATION.md` for setup guide

### Added - 2025-11-24

#### Automatic Destination Memory Integration with AI
- AI now automatically receives ALL known destinations with full paths
- Backend builds AI context from DestinationMemoryManager and DriveManager before each organize request
- AI decides which destination to use and returns full paths (not just category names)
- When no destinations exist, backend sends source folder as fallback destination
- AI can organize files in-place when no saved destinations are available
- Removed dependency on `destination_context` parameter from frontend
- No CLI parameters needed - backend supplies all context automatically
- Added comprehensive logging of AI responses for debugging
- See `💡project-docs/docs/AI_CONTEXT_INTEGRATION.md` for details

### Fixed - 2025-11-22

#### Destination Persistence and Reactivation
- Fixed issue where POST `/api/file-organizer/destinations` returned destinations with `is_active=false`
- Fixed issue where GET `/api/file-organizer/destinations` returned empty list after POST
- Destinations are now automatically reactivated when re-added after soft deletion
- All destination fields (id, path, category, drive_id, etc.) are now properly populated in responses
- Destinations now persist correctly across requests
- See `destination_memory_manager.py` line 121-141 for implementation

### Added - 2025-11-19

#### Multi-Step File Plans
- New `file_plans` array in `/api/file-organizer/organize` response
- Supports multi-step workflows per file (move → rename → tag)
- Each file gets exactly one plan with ordered steps
- Atomic execution: stops on first step failure per file
- Backward compatible: legacy `operations` array still included
- Per-step success/failure reporting in execution response
- See `test_file_plans.py` for structure examples

### Added - 2025-11-10

#### Batch Drive Registration
- New `/api/file-organizer/drives/batch` endpoint for registering multiple drives in one request
- ~80% performance improvement over sequential registration (5 drives: 250ms → 50ms)
- Atomic transactions ensure all-or-nothing behavior
- See `BATCH_DRIVE_QUICK_REFERENCE.md` for integration examples

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
