# Database Migrations

See the main [Migrations Guide](../docs/MIGRATIONS.md) for complete documentation.

## Quick Reference

### Available Migrations

- **001_destination_memory.py** - Creates destination memory system tables

### Running Migrations

Migrations run automatically when PathMemoryManager starts.

Manual execution:
```python
from backend.file_organizer.migration_runner import run_migrations
from pathlib import Path

db_path = Path("backend/data/modules/homie_file_organizer.db")
run_migrations(db_path)
```

### Testing a Migration

```bash
python3 backend/file_organizer/migrations/001_destination_memory.py
```
