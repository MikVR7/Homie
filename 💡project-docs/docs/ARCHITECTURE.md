# Homie Architecture

## File Organizer AI Features

## File Organizer AI Features

### Context-Aware Organization
The AI analyzes files in batches and adapts granularity based on:

1. **Existing Folders**: Reuses existing folder names when appropriate
2. **File Diversity**: 
   - Mixed file types → Generic categories (Documents, Images, Videos)
   - Same file type → Specific categories (Finance, Personal, Health)
3. **Batch Processing**: Single AI call for all files (massive performance improvement)

### Intelligent Archive Handling
The system automatically handles archives with three strategies:

1. **Redundant Archives → DELETE**
   - Detects when archive matches extracted content
   - Example: `movie.rar` + `movie.mkv` → deletes `.rar`, keeps `.mkv`
   
2. **Unknown Content → UNPACK**
   - If archive name doesn't reveal content
   - Extracts to `ToReview/` folder for analysis
   
3. **Known Content → MOVE**
   - Organizes by detected content type
   - Example: Project archives → `Projects/`

### On-Demand Explanations
- "Why?" button generates AI explanations for file operations
- Explanations generated only when requested (not upfront)
- Supports move, delete, and unpack operations

### Alternative Suggestions
- "Disagree" button provides 2-4 alternative folder suggestions
- AI considers file content and context for alternatives
- Respects base path and provides diverse organizational strategies

## Web Server Component

## Web Server Component

**Location:** `backend/core/web_server.py`

**Purpose:** Flask + SocketIO server that handles HTTP API and WebSocket connections.

### Architecture

The web server is now **modular** with routes split into separate files:

```
backend/core/
├── web_server.py          # Main server class (500 lines)
└── routes/
    ├── __init__.py
    ├── file_organizer_routes.py    # Core organization endpoints
    ├── analysis_routes.py          # Content analysis endpoints
    ├── operation_routes.py         # Operation management endpoints
    ├── ai_routes.py                # AI-powered features
    └── destination_routes.py       # Destination management
```

### Route Modules

**1. File Organizer Routes** (`file_organizer_routes.py`)
- `/api/file-organizer/organize` - Analyze and organize files
- `/api/file-organizer/execute` - Execute approved operations
- `/api/file-organizer/add-granularity` - Add one level of folder granularity

**2. Analysis Routes** (`analysis_routes.py`)
- `/api/file-organizer/analyze-content` - Analyze single file
- `/api/file-organizer/analyze-content-batch` - Batch analyze multiple files
- `/api/file-organizer/analyze-archive` - Analyze archive contents
- `/api/file-organizer/scan-duplicates` - Find duplicate files

**3. Operation Routes** (`operation_routes.py`)
- `/api/file-organizer/get-analyses` - Get user's analysis sessions
- `/api/file-organizer/update-operation-status` - Update single operation
- `/api/file-organizer/batch-update-status` - Batch update operations

**4. AI Routes** (`ai_routes.py`)
- `/api/file-organizer/suggest-destination` - AI destination suggestion
- `/api/file-organizer/explain-operation` - On-demand explanation (Why?)
- `/api/file-organizer/suggest-alternatives` - Alternative suggestions when user disagrees

**5. Destination Routes** (`destination_routes.py`)
- `/api/file-organizer/get-drives` - Get available drives/mount points
- `/api/file-organizer/get-destinations` - Get saved destinations
- `/api/file-organizer/delete-destination` - Remove saved destination

### Shared Helper Methods

To eliminate code duplication, the `WebServer` class provides:

1. **`_get_file_organizer_db_connection()`** - Single source of truth for database connections
2. **`_call_ai_with_recovery(prompt)`** - Centralized AI calls with automatic model recovery
3. **`_batch_analyze_files(file_paths, use_ai)`** - Batch file analysis (used by multiple endpoints)

### Key Features

- **Modular Design:** Routes are organized by functionality, making the codebase maintainable
- **No Code Duplication:** Shared logic is centralized in helper methods
- **AI Model Recovery:** Automatic fallback when AI models are deprecated
- **Batch Processing:** Efficient AI calls for multiple files
- **WebSocket Support:** Real-time communication for live updates

## Code Quality Improvements

## Code Quality Improvements (Recent Refactoring)

### Eliminated Code Duplication

**Problem:** Multiple endpoints had duplicate logic for:
1. Database connections (6 duplicates)
2. AI calls with recovery (4 duplicates)
3. Batch file analysis (2 duplicates)

**Solution:** Created shared helper methods:

#### `_get_file_organizer_db_connection()`
- **Location:** `WebServer` class
- **Purpose:** Single source of truth for database connections
- **Impact:** Changed 6 duplicate `db_path` definitions to 1 method

#### `_call_ai_with_recovery(prompt)`
- **Location:** `WebServer` and `AIContentAnalyzer` classes
- **Purpose:** Single source of truth for AI calls with automatic model recovery
- **Impact:** Changed 4 duplicate try-except-recovery blocks to 2 methods

#### `_batch_analyze_files(file_paths, use_ai)`
- **Location:** `WebServer` class
- **Purpose:** Single source of truth for batch file analysis
- **Impact:** Both `/organize` and `/analyze-content-batch` now call this method

**Benefits:**
- Easier maintenance (change logic in ONE place)
- No more "fix one, forget the other" bugs
- Cleaner, more readable code

### Known Technical Debt

**Issue:** `web_server.py` is becoming too large (1384+ lines)

**Recommended Refactoring:**
- Split into separate route modules:
  - `routes/file_organizer_routes.py` - File organization endpoints
  - `routes/analysis_routes.py` - Analysis and content endpoints
  - `routes/operation_routes.py` - Operation management endpoints
- Keep `web_server.py` as the main orchestrator
- Use Flask Blueprints for route organization


## AI Service Resilience

## AI Service Resilience

### Fast Startup (No Performance Impact)
- At startup, system configures a default model (`gemini-flash-latest`) without API calls
- Model discovery only happens **on-demand** when first AI request is made or if model fails
- Startup time: < 100ms instead of 1-2 seconds

### Runtime Auto-Recovery
If an AI model fails during runtime (e.g., Google deprecates it after months/years):
1. System automatically triggers model discovery
2. Queries Google's API for all available models
3. Scores and ranks models by preference (flash > latest > version number)
4. Tries top 5 models automatically
5. Retries the failed request with recovered model
6. All happens transparently - user never sees the error

### Model Selection Logic
**Scoring system (higher = better):**
- "flash" models: +100 (faster, cheaper)
- "latest" aliases: +50 (auto-tracks Google's recommendations)
- Version numbers: 2.5 (+30), 2.0 (+20), 1.5 (+10)
- "exp"/"preview": -20 (unstable)

**User override:** Set `GEMINI_MODEL=model-name` in `.env` to force a specific model

### Benefits
- ✅ **No performance penalty** - discovery only when needed
- ✅ **Long-term resilience** - survives years without restarts
- ✅ **Zero maintenance** - adapts to Google's model changes automatically
- ✅ **Transparent recovery** - users don't experience failures

## Phase 6: Granular Control

- **Outcome:** Selecting an alternative updates the file's proposed destination and reason in the UI. The file view model is then visually moved to the appropriate category card, creating a new category on the fly if one does not already exist. The actual file operation is not executed until the user clicks one of the "Apply" buttons.

## Phase 6: Granular Control (Completed)

- **Outcome:** Selecting an alternative updates the file's proposed destination and reason in the UI. The file view model is then visually moved to the appropriate category card, creating a new category on the fly if one does not already exist. The actual file operation is not executed until the user clicks one of the "Apply" buttons.

## File Organizer - Phase 5: Advanced AI Features

## File Organizer - Phase 5: Advanced AI Features

### Content Analysis Engine

The File Organizer now includes a sophisticated content analysis system that extracts rich metadata from various file types without manual categorization.

#### Supported File Types

**1. Video Files (.mkv, .mp4, .avi, .mov)**
- **Movies**: Parses filename to extract title, year, quality, release group
  - Example: `Thunderbolts.2025.German.TELESYNC.LD.720p.x265-LDO.mkv`
  - Extracted: title="Thunderbolts", year=2025, quality="720p", release_group="LDO"
  - Confidence: 0.9
  
- **TV Shows**: Detects season/episode information
  - Example: `Breaking.Bad.S05E16.1080p.WEB-DL.mkv`
  - Extracted: show="Breaking Bad", season=5, episode=16
  - Confidence: 0.92

**2. Documents (.pdf, .doc, .docx)**
- **Invoices**: OCR/text extraction to find company, amount, date
  - Detects invoice-specific keywords in multiple languages
  - Extracts monetary amounts and dates
  - Returns content_type="invoice" with metadata
  
- **General Documents**: Basic categorization with confidence scores

**3. Images (.jpg, .png, .gif, .bmp)**
- EXIF data extraction when file is accessible
- Extracts: date_taken, camera_model, camera_make, GPS data
- Graceful degradation when file not accessible (returns image type with note)

**4. Archives (.zip, .rar, .7z)**
- Lists contents without extraction
- Returns file_count and sample_files
- Detects project types (optional, in deep analysis mode)
- Returns content_type="archive" with archive_type

**5. Unknown Files**
- Returns content_type="unknown" with file extension
- Low confidence score (0.5) indicating uncertainty

#### API Endpoints

##### `/api/file-organizer/analyze-content-batch` (POST)
Analyzes multiple files in a single request.

**Request:**
```json
{
  "files": [
    "/path/to/movie.mkv",
    "/path/to/invoice.pdf",
    "/path/to/archive.zip"
  ]
}
```

**Response:**
```json
{
  "success": true,
  "results": {
    "/path/to/movie.mkv": {
      "success": true,
      "content_type": "movie",
      "title": "Movie Title",
      "year": 2025,
      "quality": "1080p",
      "release_group": "GROUP",
      "confidence_score": 0.9
    },
    "/path/to/invoice.pdf": {
      "success": true,
      "content_type": "invoice",
      "company": "ACME Corp",
      "amount": 1234.56,
      "currency": "EUR",
      "confidence_score": 0.88
    },
    "/path/to/archive.zip": {
      "success": true,
      "content_type": "archive",
      "archive_type": "zip",
      "file_count": 42,
      "sample_files": ["file1.txt", "file2.doc", ...],
      "confidence_score": 1.0
    }
  }
}
```

#### Quality Detection
The analyzer automatically detects video quality from filenames:
- 4K, 2160p, 1080p, 720p, 480p
- TELESYNC, CAM, HDRip, BluRay, WEB-DL, WEBRip, DVDRip

#### Release Group Detection
Extracts release group names from video filenames (e.g., YIFY, SPARKS, LDO)

#### Confidence Scoring
Each analysis includes a confidence score (0.0 - 1.0):
- 1.0: Perfect match with all metadata extracted
- 0.9: High confidence (movie with year/title)
- 0.8: Good confidence (basic file type)
- 0.7: Medium confidence (file type known but limited metadata)
- 0.5: Low confidence (unknown file type)

#### Graceful Degradation
The analyzer works even when files are not accessible:
- **Videos**: Filename parsing works without file access
- **Documents/Images/Archives**: Returns type with note "File not accessible"
- Never fails hard - always returns analyzable results

#### Implementation Details
- Location: `backend/file_organizer/ai_content_analyzer.py`
- Class: `AIContentAnalyzer`
- Regex-based parsing for movies/TV shows
- Optional dependencies: PyPDF2, Pillow, rarfile, py7zr
- Batch processing: Up to 50 files per request


## UI Components


### AISuggestionsView.axaml / .cs
*   **Role:** Displays the results of the AI's file sorting analysis.
*   **Description:** This view presents files grouped into dynamically generated categories based on the AI's response. It uses the `CategoryCard` component to display each category. The view is populated with data after the analysis is triggered from the `FileBrowserView`.

### CategoryCard.axaml / .cs
*   **Role:** A reusable component to display a single category of sorted files.
*   **Description:** Shows a category's icon, name, file count, and a list of files within it. The card's background and accent colors are dynamically set based on the category, as defined in `App.axaml`.


## UI Components


### AISuggestionsView.axaml / .cs
*   **Role:** Displays the results of the AI's file sorting analysis.
*   **Description:** This view presents files grouped into dynamically generated categories based on the AI's response. It uses the `CategoryCard` component to display each category. The view is populated with data after the analysis is triggered from the `FileBrowserView`.

### CategoryCard.axaml / .cs
*   **Role:** A reusable component to display a single category of sorted files.
*   **Description:** Shows a category's icon, name, file count, and a list of files within it. The card's background and accent colors are dynamically set based on the category, as defined in `App.axaml`.


## Frontend Architectural Pattern (Model-Component)

The frontend for HomieA follows a custom architectural pattern we call "Model-Component". This pattern is born out of a desire for simplicity, strict adherence to Object-Oriented Programming (OOP) principles, and a clear separation of concerns, while explicitly avoiding complex frameworks like MVVM or MVC.

### Core Tenets

1.  **Model**: A pure C# class that holds data and business logic. It inherits from `ObservableObject` to notify the UI of property changes. It has no knowledge of the UI components that might display it. Example: `FoundFile.cs`.
2.  **Component (View/Code-Behind)**: The UI is defined in an `.axaml` file (the View). The logic for user interaction within that component is in its `.axaml.cs` code-behind file. The code-behind's only job is to handle UI events (like button clicks) and translate them into actions, usually by modifying the Model's state or publishing an event. It should contain no business logic. Example: `FoundFileLine.axaml` and `FoundFileLine.axaml.cs`.
3.  **No Direct Dependencies**: UI components **never** directly call or hold instances of services or other components. All communication is decoupled.
4.  **Strict Single Responsibility**: Every class, whether it's a model, a component, or a service, must have a single, clearly defined purpose.

### Communication: The `CodeEvents` System

All communication and orchestration within the application is handled by the `CodeEvents` system. This is the backbone of our decoupled architecture.

*   **Publishers**: Any component or service can publish an event to announce that something has happened (e.g., a user clicked a button, data is ready, an error occurred).
*   **Subscribers**: Any component or service can subscribe to specific events it cares about and react accordingly.

This ensures that components are self-contained and reusable, without creating a tangled web of dependencies.

### Orchestration: Services and the Main Window

While components are self-contained, the overall application flow and business logic are orchestrated by dedicated services and the main window controller (`FileOrganizerWindow.axaml.cs`).

*   **Services**: These are stateful, often singleton-like classes that manage a specific domain.
    *   `DestinationsService`: Manages the state of all known destination drives and folders, handles communication with the backend for this data, and responds to UI requests for changes (add/delete/set root).
    *   `ExecutionService`: Acts as a controller for the core sorting workflow. It coordinates fetching destinations, finding files, calling the AI backend for suggestions, and then publishing the results for the UI to display.
*   **Main Window (`FileOrganizerWindow.axaml.cs`)**: This acts as the central "conductor". It is responsible for:
    *   Instantiating and injecting the core services.
    *   Subscribing to high-level events (like a button click to start the main process or a backend connection failure).
    *   Coordinating the overall UI state, such as showing/hiding views, displaying error overlays, or opening dialogs.

### Backend Connection Management

The application is designed to be resilient to backend connection failures.

1.  **`BackendConnectionException`**: The `ApiService` will throw this custom exception if any network request fails.
2.  **Error Overlay**: The `FileOrganizerWindow` listens for a `Pub_BackendConnectionFailed` event. When this event is caught, it displays a non-closeable `BackendConnectionManagerView` overlay that informs the user of the issue.
3.  **Automatic Reconnection**: The `BackendConnectionManagerView` contains a timer that periodically attempts to re-establish a connection by making a key API call (`GetDestinationsAsync`).
4.  **Restoration**: Once the connection is successful, it fires a `Pub_BackendConnectionRestored` event. The `FileOrganizerWindow` catches this, removes the overlay, and re-initializes the application's data state.

## API Endpoints

## API Endpoints

The backend exposes the following HTTP endpoints:

### Health Check Endpoints

- **`GET /health`**: Simple health check endpoint that returns `{"status": "ok"}` with a 200 status code. This is a lightweight endpoint for the frontend to verify the backend is running and responsive. Does not connect to database or perform any heavy operations.

- **`GET /api/health`**: Detailed health check endpoint that returns comprehensive system status including component health, version information, and timestamp.

### File Organizer Endpoints

- **`POST /api/file-organizer/organize`**: Analyze a folder and generate file organization operations
- **`POST /api/file-organizer/execute-operations`**: Execute file organization operations
- **`GET /api/file-organizer/analyses`**: Get all analysis sessions for the current user
- **`GET /api/file-organizer/analyses/<analysis_id>`**: Get details of a specific analysis session
- **`PUT /api/file-organizer/operations/<operation_id>/status`**: Update the status of a specific operation
- **`PUT /api/file-organizer/operations/batch-status`**: Batch update operation statuses
- **`GET /api/file_organizer/drives`**: Get available drives
- **`GET /api/file-organizer/destinations`**: Get saved destination paths
- **`DELETE /api/file-organizer/destinations`**: Remove a destination path

### System Endpoints

- **`GET /api/status`**: Get detailed system status including all component health checks
- **`POST /api/test-ai`**: Test AI service connection
- **`POST /__internal__/shutdown`**: Development-only endpoint for graceful shutdown (localhost only)

## Containerization Strategy

The backend is packaged into a Docker container for deployment. This is managed by the `homie-devops` MCP server, which automates the build process defined in `backend/Dockerfile`. The Dockerfile uses a multi-stage build to produce a minimal, secure image, ensuring a consistent and isolated production environment. See the `DEPLOYMENT.md` guide for detailed instructions.

## Overview

Homie is a mobile-first intelligent home management platform that provides AI-powered file organization, financial management, media management, and document management through a unified ecosystem.

## Core Modules (Rebuilt 2025-08-09)

### Phase 1: File Organizer ✅ Rebuilt
- **Status**: Rebuilt with abstract operations, pure Python execution, and persistent analysis storage
- **Features**: AI-powered file categorization, destination memory, drive discovery/monitoring, persistent analysis sessions
- **Database**: `homie_file_organizer.db` (separate module database)
- **Key Components**:
  - `file_organizer_app.py`: High-level coordinator; subscribes to `EventBus`
  - `path_memory_manager.py`: Central memory; OWNS `drives_manager.py`
  - `drives_manager.py`: Drive discovery + monitoring (internal dependency of PathMemoryManager)
  - `ai_command_generator.py`: Builds AI prompts; returns abstract operations
  - `file_operation_manager.py`: Executes operations via pure Python (`pathlib`/`shutil`)

**Persistent Analysis Storage**:
- **Analysis Sessions**: Each "Analyze" action creates a stored analysis session in the database
- **Operation Tracking**: Individual operations track their status (pending/applied/ignored/reverted)
- **Session History**: Users can see their analysis history when reopening the app
- **Resume Capability**: Frontend can resume exactly where they left off

**Database Schema**:
- `analysis_sessions`: Stores analysis metadata (user_id, source_path, destination_path, file_count, status)
- `analysis_operations`: Stores individual operations with status tracking and timestamps

API alignment:
- Analyze is exposed as `POST /api/file-organizer/organize` (creates persistent analysis session)
- Analysis history: `GET /api/file-organizer/analyses` (returns user's analysis history)
- Analysis detail: `GET /api/file-organizer/analyses/{analysis_id}` (returns specific analysis with operations)
- Operation status: `PUT /api/file-organizer/operations/{operation_id}/status` (updates single operation)
- Batch status: `PUT /api/file-organizer/operations/batch-status` (updates multiple operations)
- Responses return frontend-compatible operations: `type`, `source`, `destination`, `operation_id`, `status`
- Additional telemetry fields: `analysis_id`, `analysis` object, `total_files`, `stats.by_category`, `warnings`.

### Phase 2: Home Server/NAS (Planned)
- **Status**: Planned
- **Features**: Centralized storage, backup, media server
- **Database**: `homie_media_manager.db` (separate module database)

### Phase 3: Media Manager (Planned)
- **Status**: Planned
- **Features**: Media library, watch history, recommendations
- **Database**: `homie_media_manager.db` (separate module database)

### Phase 4: Document Management (Planned)
- **Status**: Planned
- **Features**: OCR, document categorization, search
- **Database**: `homie_document_manager.db` (separate module database)

### Phase 5: Financial Management (In Progress)
- **Status**: In Progress
- **Features**: Expense tracking, budget management, tax reporting
- **Database**: `homie_financial_manager.db` (separate module database)

## Technology Stack

### Backend
- **Language**: Python 3.11+
- **Framework**: Flask + Socket.IO with **gevent** async engine (via `core/web_server.py`)
- **Orchestrator**: `backend/main.py` (starts core only, not apps)
- **App Lifecycle**: `core/app_manager.py` (register, start/stop on demand)
- **Database**: SQLite with module-specific databases
- **AI**: Google Gemini API
- **Security**: bcrypt, SQL injection prevention, audit logging

#### Async Engine Choice: Gevent
- **Why gevent**: Excellent Python 3.12 compatibility, proper signal handling (clean Ctrl+C shutdown)
- **vs threading**: Better performance for WebSocket-heavy applications
- **vs eventlet**: eventlet has compatibility issues with Python 3.12 (removed `distutils`, `ssl.wrap_socket`)
- **Production ready**: Used by many Flask-SocketIO applications in production

### Database Architecture

#### Module-Specific Database Design
Each module has its own dedicated database file for complete isolation:

```
backend/data/
├── homie_users.db              # User management and authentication
└── modules/
    ├── homie_file_organizer.db    # File organization and destination memory
    ├── homie_financial_manager.db # Financial data and transactions
    ├── homie_media_manager.db     # Media library and watch history
    └── homie_document_manager.db  # Document management and OCR
```

#### Key Benefits
- **Complete Module Isolation**: Each module's data is completely separate
- **User Isolation**: Complete data separation between users
- **Scalability**: Each module can scale independently
- **Maintenance**: Easy to backup, restore, or migrate individual modules
- **Security**: Compartmentalized data access

#### Database Schema

**Users Database (`homie_users.db`)**:
- `users`: User accounts and authentication
- `user_preferences`: User-specific settings
- `security_audit`: Security event logging

**File Organizer Database (`homie_file_organizer.db`)**:
- `destination_mappings`: Learned file category → destination mappings
- `series_mappings`: TV series episode organization
- `user_drives`: Discovered storage drives
- `file_actions`: File operation audit trail
- `module_data`: Module-specific configuration and data

**Financial Manager Database (`homie_financial_manager.db`)**:
- `user_accounts`: Bank accounts and balances
- `transactions`: Financial transactions
- `construction_budget`: Construction project budgets
- `securities`: Investment portfolio
- `module_data`: Financial configuration

**Media Manager Database (`homie_media_manager.db`)**:
- `media_library`: Media file catalog
- `watch_history`: Viewing history
- `series_episodes`: TV series episode tracking
- `module_data`: Media preferences

**Document Manager Database (`homie_document_manager.db`)**:
- `documents`: Document catalog and metadata
- `document_categories`: Document organization
- `module_data`: OCR settings and preferences

## Data Flow

### File Organizer Flow
1. **Discovery**: Scan user's drives and files
2. **Analysis**: AI analyzes file types, content, and context
3. **Learning**: Update destination memory based on user actions
4. **Organization**: Suggest and execute file moves
5. **Audit**: Log all actions for security and debugging

### Financial Manager Flow
1. **Data Import**: Import from CSV, bank APIs, or manual entry
2. **Categorization**: AI categorizes transactions
3. **Analysis**: Generate reports and insights
4. **Budgeting**: Track spending against budgets
5. **Tax Preparation**: Generate tax reports

## Security Features

### Database Security
- **SQL Injection Prevention**: Parameterized queries
- **Path Validation**: Prevents directory traversal attacks
- **User Isolation**: Complete data separation between users
- **Module Isolation**: Complete data separation between modules
- **Audit Logging**: All operations logged with timestamps
- **Encryption**: Password hashing with bcrypt

### API Security
- **CORS**: Configured for frontend communication
- **Input Validation**: All inputs validated and sanitized
- **Error Handling**: Secure error messages without data leakage
- **Rate Limiting**: Planned for production deployment

## Development Workflow

### Database Management
- **Module-Specific**: Each module manages its own database
- **Migration**: Schema changes handled per module
- **Backup**: Individual module databases can be backed up separately
- **Testing**: Each module has isolated test databases

### Code Organization (Current)
```
backend/
├── main.py                         # Orchestrator (starts core services only)
├── core/
│   ├── web_server.py              # Flask + Socket.IO + gevent, owns host/port
│   ├── event_bus.py               # Internal pub/sub + socket broadcasting
│   ├── client_manager.py          # WebSocket sessions and module switching
│   ├── shared_services.py         # AI keys, env, utilities
│   └── app_manager.py             # Module registration and lifecycle
├── file_organizer/
│   ├── file_organizer_app.py      # Module coordinator
│   ├── path_memory_manager.py     # Central memory; owns DrivesManager
│   ├── drives_manager.py          # Drive discovery/monitoring (internal)
│   ├── ai_command_generator.py    # AI prompts → abstract operations
│   └── file_operation_manager.py  # Execute operations via pure Python
├── data/
│   ├── homie_users.db
│   └── modules/
│       ├── homie_file_organizer.db
│       ├── homie_financial_manager.db
│       ├── homie_media_manager.db
│       └── homie_document_manager.db
└── test_client/                    # ✅ Backend test client (2025-08-13)
    ├── index.html                  # Multi-user test interface
    ├── app.js                      # WebSocket + HTTP API testing
    └── server.py                   # Development test server
```

## Deployment Architecture

### Multi-Backend Support
The system supports multiple backend configurations:
- **Local Development**: SQLite databases on local machine
- **Home Server**: Centralized SQLite databases on home server
- **Cloud**: Future cloud database support

### Module Independence
Each module can be:
- **Deployed Independently**: Modules can be enabled/disabled
- **Scaled Independently**: Each module can scale based on usage
- **Updated Independently**: Module updates don't affect others
- **Backed Up Independently**: Individual module data backup

## Future Enhancements

### Planned Features
- **Multi-User Support**: Complete user isolation and management
- **Cloud Sync**: Synchronization with cloud storage
- **Mobile App**: Native mobile applications
- **API Integration**: Third-party service integrations
- **Advanced AI**: Enhanced AI capabilities for all modules

### Scalability Considerations
- **Database Sharding**: Module-specific databases enable easy sharding
- **Microservices**: Each module can become a separate microservice
- **Load Balancing**: Individual modules can be load balanced
- **Caching**: Module-specific caching strategies












<!-- Last updated: 2025-10-16 21:15 - Reason: Documented new context-aware AI features and intelligent archive handling -->
