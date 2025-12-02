# File Organizer Module

AI-powered file organization system with destination memory learning and enhanced metadata support.

## Documentation

All documentation is in `💡project-docs/docs/`:

### API & Integration
- [API Endpoints](../../💡project-docs/docs/API_ENDPOINTS.md) - Complete API reference
- [Enhanced Metadata Support](../../💡project-docs/docs/ENHANCED_METADATA_SUPPORT.md) - v2.0 metadata features
- [Frontend Integration Guide](../../💡project-docs/docs/FRONTEND_INTEGRATION_GUIDE.md) - Integration examples
- [Metadata Examples](../../💡project-docs/docs/METADATA_EXAMPLES.json) - Example requests

### Architecture & Features
- [AI Context Integration](../../💡project-docs/docs/AI_CONTEXT_INTEGRATION.md) - How AI uses context
- [AI Context Builder](../../💡project-docs/docs/AI_CONTEXT_BUILDER.md) - Context preparation
- [Destination Memory Manager](../../💡project-docs/docs/DESTINATION_MEMORY_MANAGER.md) - Learning system
- [Drive Manager](../../💡project-docs/docs/DRIVE_MANAGER.md) - Multi-client drive tracking
- [Multi-Client Support](../../💡project-docs/docs/MULTI_CLIENT_SUPPORT.md) - Multi-device architecture

### Changelog
- [File Organizer Changelog](../../💡project-docs/docs/FILE_ORGANIZER_CHANGELOG.md) - Version history

## Key Components

### Core Classes
- `FileOrganizerApp` - Main application coordinator
- `PathMemoryManager` - Path history and analytics
- `DestinationMemoryManager` - Destination learning and suggestions
- `DriveManager` - Multi-client drive tracking
- `AIContextBuilder` - AI prompt context preparation
- `AICommandGenerator` - AI-powered operation generation
- `AIContentAnalyzer` - File content analysis
- `FileOperationManager` - File system operations
- `DrivesManager` - Drive detection and monitoring (legacy)

### Data Models
- `Drive` - Physical/cloud drive representation
- `Destination` - Learned destination folder
- `DestinationUsage` - Usage tracking

## Examples

Run the examples:
```bash
# Destination memory system
python3 backend/file_organizer/example_destination_memory.py

# Destination manager API
python3 backend/file_organizer/example_destination_manager.py
```

## Testing

Run the test suite:
```bash
python3 backend/file_organizer/test_destination_memory_manager.py
```

## Database

The module uses SQLite database at:
```
backend/data/modules/homie_file_organizer.db
```

Migrations run automatically on startup.
