# File Organizer Database Migrations

This directory contains database migrations for the File Organizer module. Migrations are applied automatically when the PathMemoryManager starts.

## Migration System

### Structure

Each migration is a Python file with the following structure:

```python
def get_migration_version() -> int:
    """Returns the version number of this migration"""
    return 1

def apply_migration(conn: sqlite3.Connection) -> None:
    """Apply the migration"""
    # Create tables, indexes, etc.
    pass

def rollback_migration(conn: sqlite3.Connection) -> None:
    """Rollback the migration (optional)"""
    # Drop tables, indexes, etc.
    pass
```

### Naming Convention

Migrations are named: `{version}_{description}.py`

Examples:
- `001_destination_memory.py`
- `002_add_user_preferences.py`
- `003_optimize_indexes.py`

### Migration Tracking

The system maintains a `schema_migrations` table that tracks which migrations have been applied:

```sql
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    migration_name TEXT NOT NULL
)
```

### Running Migrations

Migrations run automatically when PathMemoryManager starts. You can also run them manually:

```python
from backend.file_organizer.migration_runner import run_migrations
from pathlib import Path

db_path = Path("path/to/homie_file_organizer.db")
applied_count = run_migrations(db_path)
print(f"Applied {applied_count} migrations")
```

### Checking Migration Status

```python
from backend.file_organizer.migration_runner import MigrationRunner
from pathlib import Path

runner = MigrationRunner(Path("path/to/homie_file_organizer.db"))
status = runner.get_migration_status()
print(f"Current version: {status['current_version']}")
print(f"Pending migrations: {status['pending_migrations']}")
```

## Available Migrations

### 001_destination_memory.py

Creates the destination memory system tables:

**Tables:**
- `drives` - Tracks physical and cloud drives
- `destinations` - Stores learned destination paths
- `destination_usage` - Detailed usage history

**Indexes:**
- `idx_destinations_user_category` - Fast lookups by user and category
- `idx_destinations_user_active` - Filter active destinations
- `idx_drives_user_available` - Find available drives
- `idx_usage_destination` - Usage analytics

## Creating New Migrations

1. Create a new file: `{next_version}_{description}.py`
2. Implement required functions:
   - `get_migration_version()` - Return the version number
   - `apply_migration(conn)` - Apply the changes
   - `rollback_migration(conn)` - (Optional) Revert the changes
3. Test your migration:
   ```bash
   python backend/file_organizer/migrations/{your_migration}.py
   ```
4. Restart the backend to apply automatically

## Best Practices

1. **Incremental Changes**: Each migration should be focused and atomic
2. **Backwards Compatible**: Avoid breaking changes when possible
3. **Test Thoroughly**: Always test migrations on a copy of production data
4. **Document Changes**: Add clear comments explaining what and why
5. **Handle Errors**: Use try/except and rollback on failures
6. **Index Strategy**: Add indexes for common query patterns
7. **Data Migration**: If migrating data, handle edge cases and nulls

## Troubleshooting

### Migration Failed

If a migration fails:
1. Check the logs for the specific error
2. The database will be rolled back to the previous state
3. Fix the migration file
4. Restart the backend to retry

### Manual Rollback

To manually rollback a migration:

```python
import sqlite3
from backend.file_organizer.migrations.{migration_file} import rollback_migration

conn = sqlite3.connect("path/to/homie_file_organizer.db")
rollback_migration(conn)
conn.execute("DELETE FROM schema_migrations WHERE version = {version}")
conn.commit()
conn.close()
```

### Reset All Migrations

⚠️ **Warning**: This will delete all data!

```python
import sqlite3

conn = sqlite3.connect("path/to/homie_file_organizer.db")
conn.execute("DROP TABLE IF EXISTS schema_migrations")
# Drop all other tables...
conn.commit()
conn.close()
```
