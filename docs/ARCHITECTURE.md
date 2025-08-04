# Homie Architecture

## Overview

Homie is a mobile-first intelligent home management platform that provides AI-powered file organization, financial management, media management, and document management through a unified ecosystem.

## Core Modules

### Phase 1: File Organizer ✅ COMPLETE
- **Status**: Complete with module-specific database
- **Features**: AI-powered file categorization, destination memory, drive discovery
- **Database**: `homie_file_organizer.db` (separate module database)
- **Key Components**:
  - `SmartOrganizer`: AI-powered file analysis and organization
  - `ModuleDatabaseService`: Module-specific database operations
  - Destination memory learning and persistence
  - Drive discovery and mapping

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
- **Framework**: Flask (API server)
- **Database**: SQLite with module-specific databases
- **AI**: Google Gemini API
- **Security**: bcrypt, SQL injection prevention, audit logging

### Frontend
- **Framework**: Flutter (Dart)
- **Platforms**: Mobile (Android/iOS), Web, Desktop
- **UI**: Material Design 3, dark theme
- **State Management**: Provider/Riverpod

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

### Code Organization
```
backend/
├── api_server.py              # Main Flask API server
├── services/
│   ├── shared/
│   │   └── module_database_service.py  # Module database service
│   ├── file_organizer/
│   │   ├── smart_organizer.py          # AI file organization
│   │   └── discover.py                 # Drive discovery
│   └── financial_manager/
│       └── financial_manager.py        # Financial operations
└── data/
    ├── homie_users.db                 # User management
    └── modules/                       # Module databases
        ├── homie_file_organizer.db
        ├── homie_financial_manager.db
        ├── homie_media_manager.db
        └── homie_document_manager.db
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
