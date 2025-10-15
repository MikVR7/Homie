# Development Guide

## Adding New Endpoints

## Adding New Endpoints

### Route Organization

Routes are organized into modules by functionality:

```
backend/core/routes/
├── file_organizer_routes.py    # Core file organization
├── analysis_routes.py          # Content analysis
├── operation_routes.py         # Operation management
├── ai_routes.py                # AI-powered features
└── destination_routes.py       # Destination management
```

### How to Add a New Endpoint

1. **Choose the appropriate route module** based on functionality
2. **Add your route function** inside the `register_*_routes()` function
3. **Use shared helper methods** from `web_server` to avoid duplication:
   - `web_server._get_file_organizer_db_connection()` - Database access
   - `web_server._call_ai_with_recovery(prompt)` - AI calls with recovery
   - `web_server._batch_analyze_files(paths, use_ai)` - Batch file analysis

### Example: Adding a New Endpoint

```python
# In backend/core/routes/analysis_routes.py

def register_analysis_routes(app, web_server):
    """Register analysis routes with the Flask app"""
    
    @app.route('/api/file-organizer/my-new-endpoint', methods=['POST'])
    def my_new_endpoint():
        try:
            data = request.get_json(force=True, silent=True) or {}
            
            # Use shared database connection
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                # Your logic here
                result = do_something()
                conn.commit()
                return jsonify({'success': True, 'result': result})
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/my-new-endpoint error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
```

### Best Practices

1. **Always use shared helper methods** - Don't duplicate database or AI logic
2. **Handle errors gracefully** - Return proper HTTP status codes
3. **Log errors** - Use `logger.error()` for debugging
4. **Return consistent JSON** - Always include `success` field
5. **Close database connections** - Use try/finally blocks
6. **Validate input** - Check required parameters early

## Console Logging

The project uses the **Serilog** library for structured logging. All log output is directed to the console where the application was launched.

### Configuration

The logger is configured in `Program.cs`. We use the `Serilog.Sinks.Console` package with a specific theme to provide color-coded output, making it easy to distinguish between different log levels.

-   **Information (`Log.Information`)**: Standard blue/cyan text for general application flow.
-   **Warning (`Log.Warning`)**: Yellow text for non-critical issues.
-   **Error (`Log.Error`)**: Red text for critical failures and exceptions.

This setup ensures that all important events, especially errors, are highly visible in the terminal during development, which is crucial for debugging. To see the logs, you must run the application via one of the provided shell scripts (e.g., `./run-file-organizer.sh`) and not directly from the IDE's debugger if it swallows console output.

## Environment Setup

### Required Environment Variables
Create a `.env` file in the `backend/` directory:

```bash
# Google Gemini API Key (required for AI-powered file organization)
GEMINI_API_KEY=your_gemini_api_key_here

# Raiffeisen Bank API (optional, for financial features)
RAIFFEISEN_CLIENT_ID=your_raiffeisen_client_id
RAIFFEISEN_CLIENT_SECRET=your_raiffeisen_client_secret
```

### Getting API Keys

#### Google Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add it to your `.env` file as `GEMINI_API_KEY`

#### Raiffeisen Bank API (Optional)
1. Register at [Raiffeisen Developer Portal](https://developer.raiffeisen.at/)
2. Create a new application
3. Add the credentials to your `.env` file

## Backend Development

### Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Running the Backend
```bash
# Start the orchestrator (starts core services and web server)
python main.py

# The server will be available at http://localhost:8000 (configured in `core/web_server.py`)
```

### Testing
```bash
# Run all tests
python -m pytest

# Run specific test
python test_file_organizer_database.py
python test_module_databases.py
```

## Frontend Development

### Setup
```bash
cd mobile_app
flutter pub get
```

### Running the Frontend

#### Web (Recommended for Development)
```bash
# Start Flutter web server
flutter run -d chrome

# The app will be available at:
# http://localhost:8080
```

#### Linux Desktop (Wayland recommended)
> IMPORTANT: Hot reload is NOT supported for the File Organizer app on Linux desktop. Do not use `--hot-reload` for development; prefer full runs via the script below.
```bash
# Recommended: run via Wayland script for stable rendering
./start_file_organizer.sh            # normal build/run

# Hot reload (experimental): may differ from release behavior
./start_file_organizer.sh --hot-reload

# Environment variables honored by scripts
#  - FLUTTER_FULLSCREEN=true  → native GTK maximize
#  - HOMIE_ROUTE, HOMIE_SOURCE, HOMIE_DESTINATION → initial route/paths
```

#### Mobile
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

## Known Issues

## Known Issues

### Linux Platform Limitations

#### Drag-and-Drop from External File Managers
**Issue**: Drag-and-drop of folders from external file managers (Nemo, Nautilus, Dolphin, etc.) does not work on Linux with X11.

**Cause**: This is a known limitation in the Avalonia framework's drag-and-drop implementation on Linux. The Avalonia `DragDrop` events do not fire when dragging files from external applications on Linux/X11.

**Affected Components**: 
- `LetsSortView` - Source folder selection screen

**Workarounds**:
- Use the "Browse Folders" button instead (works on all platforms)
- Quick Access buttons for common folders
- Drag-and-drop should work correctly on Windows

**Status**: Framework limitation, awaiting Avalonia upstream fix

**Testing**: TODO - Test drag-and-drop functionality on Windows to verify it works correctly there

## API Endpoints

### File Organizer
- `POST /api/file-organizer/organize` - Analyzes a folder and creates persistent analysis session with operations.
- `POST /api/file-organizer/execute-operations` - Executes a list of operations from the `organize` endpoint.
- `GET /api/file-organizer/destinations` - Retrieves a list of all known destination paths.
- `DELETE /api/file-organizer/destinations` - Removes a destination path from memory.
- `GET /api/file-organizer/analyses` - Returns user's analysis history.
- `GET /api/file-organizer/analyses/{analysis_id}` - Returns specific analysis details with operations.
- `PUT /api/file-organizer/operations/{operation_id}/status` - Updates operation status (pending/applied/ignored/reverted).
- `PUT /api/file-organizer/operations/batch-status` - Batch updates multiple operation statuses.

#### Analyze (`organize`) request/response

Endpoint:

```
POST /api/file-organizer/organize
Content-Type: application/json
```

Request body:

```json
{
  "source_path": "/absolute/path/to/source",
  "destination_path": "/absolute/path/to/destination",
  "organization_style": "by_type"   
}
```

Behavior:
- Scans the `source_path` and enumerates files (non-recursive, current implementation)
- Maps files to destination subfolders based on extension (e.g., PDFs → `Documents/`, images → `Pictures/`, videos → `Videos/`, archives → `Archives/`, ISOs → `Software/`, others → `Other/`)
- Creates a persistent analysis session in the database
- Stores all operations with `pending` status for tracking
- Returns analysis session info and operations list

Response example:

```json
{
  "success": true,
  "analysis_id": "550e8400-e29b-41d4-a716-446655440000",
  "analysis": {
    "analysis_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "dev_user",
    "source_path": "/absolute/path/to/source",
    "destination_path": "/absolute/path/to/destination",
    "organization_style": "by_type",
    "file_count": 12,
    "created_at": "2025-09-18T21:48:45.362Z",
    "updated_at": "2025-09-18T21:48:45.362Z",
    "status": "active"
  },
  "operations": [
    {
      "operation_id": "550e8400-e29b-41d4-a716-446655440000_op_0",
      "type": "move",
      "source": "/src/file.pdf",
      "destination": "/dest/Documents/file.pdf",
      "reason": "Move file.pdf to Documents/",
      "status": "pending"
    }
  ]
}
```

Note:
- The `organize` endpoint now creates persistent analysis sessions that survive app restarts
- Each operation includes an `operation_id` for status tracking
- Operations are stored with `pending` status and can be updated via status endpoints
- The `source_path` and `destination_path` keys are used instead of `source_folder`/`destination_folder`

#### Analysis History (`analyses`)

Endpoint:
```
GET /api/file-organizer/analyses
```

Returns a list of all analysis sessions for the current user, ordered by creation date (newest first).

Response example:
```json
{
  "success": true,
  "analyses": [
    {
      "analysis_id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "dev_user",
      "source_path": "/absolute/path/to/source",
      "destination_path": "/absolute/path/to/destination",
      "organization_style": "by_type",
      "file_count": 12,
      "created_at": "2025-09-18T21:48:45.362Z",
      "updated_at": "2025-09-18T21:48:45.362Z",
      "status": "active"
    }
  ]
}
```

#### Analysis Detail (`analyses/{analysis_id}`)

Endpoint:
```
GET /api/file-organizer/analyses/{analysis_id}
```

Returns a specific analysis session with its associated operations.

Response example:
```json
{
  "success": true,
  "analysis": {
    "analysis_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "dev_user",
    "source_path": "/absolute/path/to/source",
    "destination_path": "/absolute/path/to/destination",
    "organization_style": "by_type",
    "file_count": 12,
    "created_at": "2025-09-18T21:48:45.362Z",
    "updated_at": "2025-09-18T21:48:45.362Z",
    "status": "active"
  },
  "operations": [
    {
      "operation_id": "550e8400-e29b-41d4-a716-446655440000_op_0",
      "analysis_id": "550e8400-e29b-41d4-a716-446655440000",
      "operation_type": "move",
      "source_path": "/src/file.pdf",
      "destination_path": "/dest/Documents/file.pdf",
      "file_name": "file.pdf",
      "operation_status": "pending",
      "applied_at": null,
      "reverted_at": null,
      "metadata": "{\"reason\": \"Move file.pdf to Documents/\"}"
    }
  ]
}
```

#### Operation Status Update (`operations/{operation_id}/status`)

Endpoint:
```
PUT /api/file-organizer/operations/{operation_id}/status
Content-Type: application/json
```

Request body:
```json
{
  "status": "applied",
  "timestamp": "2025-09-18T21:50:00.000Z"
}
```

Updates the status of a single operation. Valid statuses: `pending`, `applied`, `ignored`, `reverted`, `removed`.

Response example:
```json
{
  "success": true,
  "operation": {
    "operation_id": "550e8400-e29b-41d4-a716-446655440000_op_0",
    "operation_status": "applied",
    "applied_at": "2025-09-18T21:50:00.000Z"
  }
}
```

#### Batch Operation Status Update (`operations/batch-status`)

Endpoint:
```
PUT /api/file-organizer/operations/batch-status
Content-Type: application/json
```

Request body:
```json
{
  "operation_ids": ["op1", "op2", "op3"],
  "status": "ignored",
  "timestamp": "2025-09-18T21:50:00.000Z"
}
```

Updates the status of multiple operations in a single request.

Response example:
```json
{
  "success": true,
  "updated_count": 3,
  "operations": [
    {
      "operation_id": "op1",
      "operation_status": "ignored"
    },
    {
      "operation_id": "op2", 
      "operation_status": "ignored"
    },
    {
      "operation_id": "op3",
      "operation_status": "ignored"
    }
  ]
}
```

#### Delete Destination

Endpoint:

```
DELETE /api/file-organizer/destinations
Content-Type: application/json
```

Request body:

```json
{
  "path": "/path/to/remove"
}
```

Behavior:
- Removes the specified path from the `destination_mappings` table in the database.
- Returns `200 OK` on success or `404 Not Found` if the path does not exist.

### Financial Manager
- `GET /api/financial/summary` - Financial summary
- `GET/POST /api/financial/income` - Income management
- `GET/POST /api/financial/expenses` - Expense management
- `GET/POST /api/financial/construction` - Construction budget
- `GET /api/financial/tax-report` - Tax reporting
- `POST /api/financial/import-csv` - CSV import

### System
- `GET /api/health` - Health check
- `GET /api/status` - System status

## Database Architecture

### Module-Specific Databases
Each module has its own database file for complete isolation:

```
backend/data/
├── homie_users.db              # User management and authentication
└── modules/
    ├── homie_file_organizer.db    # File organization and destination memory
    ├── homie_financial_manager.db # Financial data and transactions
    ├── homie_media_manager.db     # Media library and watch history
    └── homie_document_manager.db  # Document management and OCR
```

### Testing Database Features
```bash
# Test module database architecture
python test_module_databases.py

# Test File Organizer database functionality
python test_file_organizer_database.py

# Test File Organizer learning (requires API key)
python test_file_organizer_learning.py

# Test SIMPLE USB drive recognition
python test_simple_usb.py

# Test centralized memory system (no more folder .json files)
python test_centralized_memory.py
```

## Development Workflow

### 1. Backend Development
1. **Start with tests**: Write tests for new features
2. **Database first**: Design database schema for new modules
3. **API endpoints**: Create REST endpoints for frontend
4. **Integration testing**: Test with real files/data

### 2. Frontend Development
1. **UI/UX design**: Create mockups and wireframes
2. **State management**: Design data flow with Provider
3. **Icons and assets**: Check Material Icons first, use ICONS_AND_ASSETS.md for custom needs
4. **API integration**: Connect to backend endpoints
5. **Testing**: Widget and integration tests

### 3. Integration Testing
1. **End-to-end testing**: Test complete workflows
2. **Real data testing**: Test with actual files and data
3. **Performance testing**: Ensure scalability
4. **User acceptance**: Get feedback from real users

## Code Quality

### Python Backend
- **Type hints**: Use type annotations
- **Docstrings**: Document all functions and classes
- **Error handling**: Comprehensive exception handling
- **Security**: Input validation and SQL injection prevention

### Flutter Frontend
- **Material Design 3**: Follow design guidelines
- **State management**: Use Provider pattern
- **Error handling**: Graceful error handling
- **Performance**: Optimize for mobile devices

## Deployment

### Local Development
```bash
# Backend
cd backend && python main.py

# Frontend
cd mobile_app && flutter run -d chrome
```

### Production Considerations
- **Database backups**: Regular backups of module databases
- **Security**: HTTPS, authentication, authorization
- **Monitoring**: Logging and error tracking
- **Scalability**: Load balancing and caching

## Troubleshooting

### Common Issues

#### API Key Issues
```bash
# Check if API key is loaded
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('GEMINI_API_KEY:', bool(os.getenv('GEMINI_API_KEY')))"
```

#### Database Issues
```bash
# Check database files
ls -la data/
ls -la data/modules/
```

#### Flutter Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

### Getting Help
1. **Check logs**: Look at console output for errors
2. **Test components**: Test individual parts separately
3. **Documentation**: Check this file and architecture docs
4. **Git history**: Look at recent changes for issues


<!-- Last updated: 2025-10-15 19:33 - Reason: Added documentation for the new modular route structure and how to add endpoints -->
