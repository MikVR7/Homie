# Homie Architecture

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


<!-- Last updated: 2025-10-06 19:25 - Reason: Reflecting the major architectural refactoring: implementing the Model-Component pattern, enforcing event-driven communication, and creating orchestrator services. -->
