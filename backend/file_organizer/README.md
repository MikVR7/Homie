# File Organizer Module

AI-powered file organization system with destination memory learning.

## Quick Links

- **[Quick Start Guide](docs/QUICK_START.md)** - Get started in 5 minutes
- **[Destination Memory System](docs/README_DESTINATION_MEMORY.md)** - Overview and main documentation
- **[API Documentation](docs/DESTINATION_MEMORY_MANAGER.md)** - Complete API reference

## Documentation

All documentation is in the [`docs/`](docs/) directory:

- [Quick Start](docs/QUICK_START.md)
- [Destination Memory System](docs/README_DESTINATION_MEMORY.md)
- [Destination Memory Manager API](docs/DESTINATION_MEMORY_MANAGER.md)
- [Database Schema](docs/DESTINATION_MEMORY.md)
- [Migrations Guide](docs/MIGRATIONS.md)
- [Implementation Summary](docs/IMPLEMENTATION_SUMMARY.md)
- [Verification Checklist](docs/VERIFICATION_CHECKLIST.md)

## Key Components

### Core Classes
- `FileOrganizerApp` - Main application coordinator
- `PathMemoryManager` - Path history and analytics
- `DestinationMemoryManager` - Destination learning and suggestions
- `AICommandGenerator` - AI-powered operation generation
- `AIContentAnalyzer` - File content analysis
- `FileOperationManager` - File system operations
- `DrivesManager` - Drive detection and monitoring

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
