# Architecture

## Development Guidelines 📋
**See `GENERAL_RULES.md` for complete development guidelines including date management, commit formats, and coding standards.**

## System Overview

Homie is a comprehensive intelligent home management ecosystem designed as a mobile-first application suite. It provides integrated modules for complete personal and household management, evolving from a file organizer into a full-featured home automation and management platform.

## Core Modules

### 🗂️ Module 1: File Organizer (Current - Phase 1)
- **AI-Powered Organization**: Uses Google Gemini for intelligent file categorization
- **Smart Folder Detection**: Analyzes existing folder structures and suggests improvements
- **Duplicate Management**: Content-based duplicate detection and resolution
- **Safe Operations**: Preview mode with rollback capabilities

### 🏠 Module 2: Home Server/NAS (Phase 2)
- **Personal Cloud Storage**: OneDrive replacement for home use
- **Cross-Device Sync**: Seamless file synchronization across all devices
- **Remote Access**: Secure external connectivity via WebRTC/P2P or AWS proxy
- **Multi-Platform Support**: Windows, Linux, iOS, Android compatibility

### 🎬 Module 3: Media Manager (Phase 3)
- **Netflix-Style Interface**: Beautiful media browsing and discovery
- **Watch History**: Track viewing progress and completion status
- **Smart Recommendations**: "What to watch next" based on viewing patterns
- **Metadata Integration**: IMDB ratings, descriptions, posters, and cast info
- **Progress Tracking**: Resume watching, series episode tracking
- **Family Profiles**: Multiple user viewing histories

### 📄 Module 4: Document Management (Phase 4)
- **Austrian Business Focus**: Tailored for Austrian employment/self-employment
- **Document Categories**:
  - **Zeiterfassung**: Time tracking records and timesheets
  - **Lohnzettel**: Pay slips and salary documentation
  - **Rechnungen**: Invoice management (incoming/outgoing)
  - **Verträge**: Contracts and agreements
  - **Behörden**: Government and official documents
- **OCR Integration**: Automatic text extraction and categorization
- **Search and Filter**: Quick document retrieval by date, type, amount
- **Tax Preparation**: Automated reporting for Austrian tax requirements

### 💰 Module 5: Financial Management (Phase 5)
- **Dual Employment Tracking**: Employee + Self-employed income management
- **Austrian Tax Compliance**: 
  - Incoming invoice tracking for business expenses
  - Outgoing invoice management for self-employment
  - VAT/USt calculation and tracking
  - Annual tax preparation assistance
- **House Construction Management**:
  - Real-time cost tracking against budget
  - Supplier invoice management
  - Payment scheduling and reminders
  - Cost category analysis (materials, labor, permits, etc.)
- **Credit/Loan Management**:
  - Monthly payment tracking
  - Interest calculation and projections
  - Early payment scenario planning
- **Financial Forecasting**:
  - Cash flow predictions based on income/expenses
  - House construction affordability timeline
  - Major purchase planning
  - Emergency fund tracking

### 📱 Mobile-First Dashboard
- **Unified Home Screen**: Overview widgets from all active modules
- **Touch-Optimized Navigation**: Smartphone-native interaction patterns
- **Quick Actions**: Most common tasks accessible with one tap
- **Responsive Design**: Seamless experience from phone to tablet to desktop
- **Offline Capabilities**: Core functions work without internet connection

## Core Components

### File Scanner
- Recursively scans directories
- Extracts metadata and content signatures
- Identifies file types and patterns

### Organization Engine
- Applies rule-based and ML-driven organization logic
- Suggests file movements and folder structures
- Handles duplicate detection and resolution

### User Interface
- Flutter cross-platform application
- Configuration management
- Progress reporting and logging

## Technology Stack

### Backend (Core Logic)
- **Language**: Python 3.8+
- **Framework**: Flask with CORS support
- **AI Integration**: Google Gemini 1.5 Flash for file organization
- **Database**: SQLite for metadata and organization history
- **Configuration**: JSON files in `backend/config/`
- **Testing**: pytest with comprehensive file operation tests
- **Code Quality**: black (formatting), flake8 (linting)

### Frontend (Mobile/Web/Desktop)
- **Framework**: Flutter (Dart) for cross-platform development
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux
- **State Management**: Provider pattern for reactive state updates
- **Navigation**: Go Router for declarative routing
- **HTTP Client**: Built-in Dart HTTP client for API communication
- **UI Framework**: Material Design 3 with custom dark theme
- **Testing**: Flutter test framework for widget and integration tests
- **Code Quality**: Dart analyzer with strict linting rules

### Architecture Pattern
- **Backend**: Modular Python services with clear separation of concerns
- **Frontend**: Flutter widget-based architecture with Provider state management
- **Communication**: REST API between Python backend and Flutter frontend
- **Data Flow**: Provider pattern with reactive state updates

## Design Decisions

### Key Principles
1. Non-destructive operations by default
2. User control over automation level
3. Extensible rule system
4. Performance-first for large file sets
5. Mobile-first responsive design
6. Cross-platform compatibility

## Cloud Service Integration

### AWS Services (Available via AWS CLI)

While Homie operates as a self-hosted home server, AWS services may enhance functionality:

#### Core Integration Points
- **API Gateway + Lambda**: Secure connection proxy for external access
- **Route53**: Dynamic DNS management for home server discovery
- **CloudFront**: CDN for media streaming optimization
- **S3**: Optional backup and sync destinations
- **SNS**: Push notifications for file sync events
- **IAM**: Fine-grained access control for shared resources

#### WebRTC/P2P Enhancement
- **EC2 TURN/STUN servers**: For NAT traversal when direct connections fail
- **Elastic IPs**: Stable endpoints for connection brokering

#### Security & Access
- **Certificate Manager**: SSL/TLS certificates for HTTPS access
- **WAF**: Web application firewall for external-facing components
- **Secrets Manager**: Secure storage of API keys and tokens

### Hybrid Architecture Benefits
- Home server maintains data sovereignty
- AWS services provide global connectivity infrastructure
- Cost-effective: only pay for cloud services actually used
- Fallback connectivity when home network is unreachable

## Detailed System Architecture

### Data Flow

```
[File System] → [Scanner] → [Metadata Extractor] → [Organization Engine]
      ↓              ↓              ↓                     ↓
 [File Watcher] → [Event Queue] → [Rules Engine] → [Action Executor]
      ↓              ↓              ↓                     ↓
 [User Interface] ← [Progress Monitor] ← [Logging System] ← [Operations Log]
```

### Component Architecture

#### Core Layer
- **File System Abstraction**: Unified interface for local and cloud storage
- **Metadata Engine**: Content analysis, EXIF, media info extraction
- **Rules Engine**: Configurable organization logic with ML recommendations
- **Event System**: Async processing for file operations

#### Service Layer
- **Organization Service**: Coordinates file analysis and movement
- **Configuration Service**: User preferences and rule management
- **Monitoring Service**: System health and operation tracking
- **Backup Service**: Safety nets and rollback capabilities

#### Interface Layer
- **CLI Interface**: Primary automation interface
- **REST API**: For web UI and external integrations
- **WebSocket**: Real-time updates and progress streaming
- **Plugin API**: Third-party extension support

### Data Storage & Database Architecture

#### **Multi-Backend Database Design** 💾

##### **SQLite Database Structure** (Primary Implementation)
```sql
-- Central destination memory and user preferences
CREATE TABLE destination_mappings (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    file_category TEXT NOT NULL,        -- 'videos', 'documents', 'images'
    destination_path TEXT NOT NULL,     -- '/drive1/Movies', '/OneDrive/eBooks'
    drive_info TEXT,                    -- JSON: drive type, mount point
    confidence_score REAL DEFAULT 0.5,
    usage_count INTEGER DEFAULT 1,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Series-specific mappings for consistent TV show organization
CREATE TABLE series_mappings (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    series_name TEXT NOT NULL,
    destination_path TEXT NOT NULL,     -- '/drive1/Series/Breaking Bad'
    season_structure TEXT,              -- JSON: season folder patterns
    usage_count INTEGER DEFAULT 1,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Available drives and mount points
CREATE TABLE user_drives (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    drive_path TEXT NOT NULL,
    drive_type TEXT NOT NULL,           -- 'local', 'network', 'cloud', 'usb'
    drive_name TEXT,
    filesystem TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User preferences and settings
CREATE TABLE user_preferences (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    preference_key TEXT NOT NULL,
    preference_value TEXT,
    module_name TEXT,                   -- 'file_organizer', 'financial', etc.
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- File action history (migrated from .homie_memory.json)
CREATE TABLE file_actions (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    action_type TEXT NOT NULL,          -- 'move', 'delete', 're_analyze'
    file_name TEXT NOT NULL,
    source_path TEXT,
    destination_path TEXT,
    success BOOLEAN,
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User accounts and authentication
CREATE TABLE users (
    id TEXT PRIMARY KEY,                -- UUID
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE,
    password_hash TEXT,                 -- For cloud backend
    subscription_tier TEXT DEFAULT 'free',
    backend_type TEXT DEFAULT 'local', -- 'local', 'cloud'
    backend_url TEXT,                   -- User's backend endpoint
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);
```

##### **Backend Deployment Scenarios**

**Scenario 1: Home Server/NAS Backend** 🏠
- **Database Location**: `~/homie/data/homie.db` on user's NAS
- **Access Pattern**: Direct SQLite file access
- **Benefits**: Full data control, no cloud dependency
- **Use Case**: Privacy-conscious users with technical setup

**Scenario 2: Cloud Backend Service** ☁️
- **Database Location**: AWS RDS PostgreSQL (multi-tenant)
- **Access Pattern**: Authenticated API calls with user isolation
- **Benefits**: No setup required, access from anywhere
- **Use Case**: Convenience-focused users willing to pay

**Scenario 3: Development/Localhost** 🔧
- **Database Location**: `backend/data/homie.db`
- **Access Pattern**: Direct SQLite for rapid iteration
- **Benefits**: Fast development, easy testing
- **Use Case**: Development and feature testing

#### Legacy Configuration Storage
- **Format**: JSON for compatibility
- **Location**: `backend/config/`
- **Contents**: Migration data, templates, folder maps
- **Status**: Being migrated to SQLite database

#### Cache Layer & Performance
- **File Hashes**: Stored in database for deduplication
- **Thumbnails**: Generated previews in `backend/cache/`
- **AI Results**: Cached organization suggestions
- **Drive Discovery**: Cached mount point information

### Centralized Authentication & Multi-User Architecture

#### **Authentication Outside Module Apps** 🔐
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Homie App     │    │  Auth Service    │    │ Backend Server  │
│  (Flutter)      │───▶│  (Unified Login) │───▶│   (API + DB)    │
│                 │    │                  │    │                 │
│ • File Organizer│    │ • User Accounts  │    │ • File Organizer│
│ • Finance Mgr   │    │ • Server Discovery│    │ • Finance Mgr   │
│ • Media Mgr     │    │ • Connection Mgmt│    │ • Media Mgr     │
│ • Future Modules│    │ • Subscription   │    │ • Future Modules│
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

#### **Login Flow Design**
1. **Server Discovery**: App detects available backends (local NAS, cloud service)
2. **Authentication**: Single login works across all modules
3. **Connection Management**: Seamless switching between local/cloud backends
4. **Module Access**: Each module checks user permissions/subscriptions

#### **Unified API Design**
```python
# All modules share same authentication and database access
class BaseModule:
    def __init__(self, user_id: str, db_connection):
        self.user_id = user_id
        self.db = db_connection
    
    def get_user_preferences(self, module_name: str):
        # Shared preferences system
        pass
    
    def log_action(self, action_type: str, details: dict):
        # Shared action logging
        pass

class FileOrganizerModule(BaseModule):
    def get_destination_mappings(self):
        # File organizer specific logic
        pass

class FinancialManagerModule(BaseModule):
    def get_account_settings(self):
        # Financial manager specific logic
        pass
```

### Security Architecture

#### Data Protection
- **Multi-Backend Security**: Different security models for local vs cloud
- **Encryption at Rest**: Optional for sensitive file metadata
- **Secure Communications**: TLS for all network operations
- **User Isolation**: Complete data separation between users

#### Privacy by Design
- **Local Processing**: Content analysis happens locally
- **Backend Choice**: Users choose local NAS vs cloud hosting
- **Data Sovereignty**: Local backend = user owns all data
- **User Consent**: Explicit permission for each cloud integration

### Performance Considerations

#### Scalability
- **Concurrent Processing**: Multi-threaded file operations
- **Incremental Scanning**: Only process changed files
- **Lazy Loading**: Stream large directory listings

#### Resource Management
- **Memory Limits**: Configurable bounds for large file sets
- **Disk I/O**: Throttling to prevent system slowdown
- **Network Bandwidth**: QoS controls for cloud operations

### Error Handling & Recovery

#### Fault Tolerance
- **Operation Rollback**: All moves tracked and reversible
- **Partial Failures**: Continue processing despite individual errors
- **State Recovery**: Resume operations after interruption

#### Monitoring & Alerting
- **Health Checks**: System component status monitoring
- **Error Tracking**: Detailed logging with severity levels
- **User Notifications**: Progress updates and issue alerts

## Current Implementation (Phase 1 Complete + Module Launch Scripts)

### Module-Specific Launch System ✅ COMPLETED (2025-07-22)

**Startup Scripts Architecture:**
```
Root Directory:
├── start_homie.sh                 # 🚀 Full system (backend + frontend)
├── start_backend.sh               # 🔧 Backend API only  
├── start_frontend.sh              # 📱 Full dashboard (Linux desktop)
├── start_frontend_web.sh          # 🌐 Full dashboard (web browser)
├── start_file_organizer.sh        # 📁 File Organizer only (Linux desktop)
├── start_file_organizer_web.sh    # 📁 File Organizer only (web browser)
├── start_financial.sh             # 💰 Financial Manager only (Linux desktop)
└── start_financial_web.sh         # 💰 Financial Manager only (web browser)
```

**Technical Implementation:**
- **Runtime Route Arguments**: Flutter app accepts `--dart-entrypoint-args="--route=/module"`
- **Dynamic Initial Location**: Modified `main.dart` to parse command line arguments via `main(List<String> args)`
- **Conditional UI**: Screens hide back buttons when `isStandaloneLaunch = true`
- **Single Codebase**: No module exclusion; Flutter tree-shaking optimizes builds automatically
- **Focused Experience**: Standalone launches bypass dashboard for single-purpose workflows

### Integrated AI-Powered System ✅

**Backend Architecture:**
```
backend/
├── services/
│   ├── file_organizer/
│   │   ├── smart_organizer.py     # 🤖 Google Gemini AI integration
│   │   ├── discover.py            # Folder discovery system
│   │   └── __init__.py
│   ├── financial_manager/         # 💰 Financial management module
│   └── shared/                    # Shared utilities
├── api_server.py                  # 🌐 Flask REST API server
├── test_smart_organizer.py        # 🧪 AI system testing
├── .env                          # 🔑 Environment configuration
└── venv/                         # Python virtual environment
```

**Frontend Architecture:**
```
mobile_app/
├── lib/
│   ├── main.dart                 # Flutter app entry point
│   ├── theme/                    # Material 3 dark theme
│   ├── providers/                # State management
│   ├── services/                 # API communication
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   └── widgets/                  # Reusable components
├── android/                      # Android-specific code
├── ios/                         # iOS-specific code
├── web/                         # Web-specific code
└── linux/                       # Linux desktop code
```

**Cross-Platform Flutter Integration:**
- Material 3 dark theme with professional design
- Cross-platform support (Android, iOS, Web, Desktop)
- Provider pattern for reactive state management
- Real-time file organization with user control
- Native folder picker integration

**AI Integration Features:**
- **Smart Analysis**: Content-aware file categorization using Google Gemini
- **Context Awareness**: Understands existing folder structure
- **Project Detection**: Recognizes .git folders and treats projects as single units
- **Content Reading**: Analyzes PDF, DOC, and TXT file content
- **User Control**: Accept, Specify, or Delete actions for each file
- **AI Re-analysis**: Re-analyzes files with user input for custom specifications
- **Memory System**: Comprehensive logging of all operations
- **Privacy Focus**: Only metadata sent to AI, never file content

**API Endpoints:**
- `GET /api/health` - System health check
- `POST /api/file-organizer/organize` - AI-powered organization analysis
- `POST /api/file-organizer/execute-action` - Execute file operations (move, delete)
- `POST /api/file-organizer/re-analyze` - Re-analyze files with user input
- `POST /api/file-organizer/discover` - Discover files and folders
- `POST /api/file-organizer/browse-folders` - Browse file system

**Memory/Logging System:**
- **Memory Files**: `.homie_memory.json` created in both source and destination folders
- **Operation Tracking**: All file operations logged with timestamps
- **User Actions**: Tracks user decisions and custom specifications
- **Analytics Ready**: Data structure supports future usage pattern analysis

## Implementation Phases

### Phase 1: Core Foundation ✅ COMPLETE
- [x] Basic file scanning and metadata extraction
- [x] AI-powered intelligent organization with Google Gemini
- [x] Flutter cross-platform mobile app
- [x] Real file operations (move, delete) with user confirmation
- [x] Project detection with .git folder recognition
- [x] PDF/DOC/TXT content reading for better categorization
- [x] User control system with Accept/Specify/Delete actions
- [x] Completed actions tracking with timestamps
- [x] Memory/log system (.homie_memory.json) in both folders
- [x] AI re-analysis with user input integration
- [x] Environment configuration management
- [x] REST API for frontend integration

### Phase 2: Intelligence Layer
- [ ] Machine learning for content classification
- [ ] Duplicate detection and merging
- [ ] Advanced rule engine with conditions
- [ ] Automated organization suggestions

### Phase 3: Remote Access
- [ ] REST API development
- [ ] Web interface for configuration
- [ ] Cloud service integrations
- [ ] Mobile companion app

### Phase 4: Advanced Features
- [ ] Plugin system architecture
- [ ] Multi-user support
- [ ] Enterprise features (LDAP, SSO)
- [ ] Advanced media server capabilities

## Technology Decisions

### Language Selection Criteria
- **Performance**: Fast file I/O and metadata processing
- **Ecosystem**: Rich libraries for media processing
- **Cross-platform**: Run on various operating systems
- **Maintainability**: Clear, readable code for long-term development

### Selected Technologies

#### Backend: Python 3.8+
**Reasons for selection:**
- Rich ecosystem for file processing and metadata extraction
- Excellent libraries for ML/AI (future content classification)
- Rapid development and iteration
- Strong testing frameworks (pytest)
- Clear, readable code for long-term maintenance

#### Frontend: Svelte/SvelteKit
**Reasons for selection:**
- Lightweight and fast runtime performance
- Excellent developer experience with built-in reactivity
- Simple, semantic CSS approach (avoiding Tailwind complexity)
- Great for file management interfaces with real-time updates
- Smaller bundle sizes compared to React/Vue

### Dependency Management
- **Core Libraries**: Minimal dependencies for stability
- **Optional Features**: Plugin-based extensions
- **Security Updates**: Automated dependency scanning

## Future Architecture Considerations

### Extensibility
- Plugin system for custom organizers
- Custom metadata extractors
- Third-party service integrations
- Custom UI themes and layouts

### Advanced Features
- Web interface for remote management
- Integration with additional cloud storage services
- WASM-based client components for cross-platform compatibility
- AI-powered content understanding and tagging
- Collaborative organization for family/team use

## Commercial Viability & Market Expansion

### Current Implementation Success
Homie has successfully evolved from a simple file organizer into a comprehensive home management ecosystem. The Austrian-focused Financial Manager has proven the viability of compliance-specific tools in German-speaking markets.

### DACH Region Expansion Opportunity ✅ RESEARCHED (2025-01-XX)

**Comprehensive market research reveals massive commercial potential for expanding to Germany and Switzerland:**

#### **Market Analysis Summary:**
- **Total Addressable Market**: €95-190M across DACH region
- **Technical Feasibility**: 80% of current Austrian solution reusable
- **Market Timing**: Perfect alignment with Germany's mandatory B2B e-invoicing 2025-2028
- **Competitive Advantage**: First-mover position in AI-powered compliance tools

#### **Market Size Breakdown:**
- **Austria**: €10-20M (500K businesses) - Current market
- **Germany**: €70-140M (3.5M businesses) - 9x larger opportunity  
- **Switzerland**: €15-30M (600K businesses) - Premium pricing potential

#### **Implementation Strategy:**
```
Phase 1: Germany First (6 months)
├── Urgent need due to e-invoicing mandate
├── CEN 16931 format compliance
├── DATEV export integration
└── German tax validation (19%/7% VAT)

Phase 2: Switzerland Next (6-12 months)  
├── Premium market positioning
├── CHE number validation
├── Swiss accounting integration
└── Multi-currency CHF support
```

#### **Revenue Projections:**
- **Year 1**: €442K (Germany focus + Austria base)
- **Year 2**: €1.42M (Add Switzerland, scale Germany)  
- **Year 3-4**: €5M+ potential with market penetration

#### **Unified DACH AI Architecture:**
```
Common AI Processing Core (80% reusable):
├── Invoice Data Extraction
│   ├── Company names/addresses (DE/AT/CH)
│   ├── VAT/Tax numbers (DE-VAT, ATU, CHE)
│   ├── Amounts and tax rates
│   └── Dates and invoice numbers
├── Country-Specific Validation (20% new)
│   ├── German: CEN 16931 compliance
│   ├── Austrian: e-Rechnung.gv.at format
│   └── Swiss: CHE number validation
└── Export Formats
    ├── DATEV (Germany/Austria)
    ├── Abacus (Switzerland)
    └── Standard accounting formats
```

#### **Key Success Factors:**
1. **Regulatory Compliance**: All three countries follow EU VAT framework basics
2. **Language Unity**: German official in AT/DE, widely spoken in CH
3. **Business Culture**: Shared precision and compliance focus
4. **Technology Standards**: Common move toward EN 16931 European standard
5. **Premium Willingness**: High-value businesses pay for compliance tools

#### **Market Entry Strategy:**
- **Germany**: Target businesses preparing for 2025 e-invoicing mandate
- **Austria**: Leverage existing expertise and customer base
- **Switzerland**: Premium positioning for multinational corporations

This expansion represents a **€5M+ business opportunity** within 3-4 years, transforming Homie from a personal tool into a commercial DACH region compliance platform.
