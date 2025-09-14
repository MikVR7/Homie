# AI Agent Context - Homie

## Project Purpose
Homie is your comprehensive intelligent home management ecosystem that evolves from a smart file organizer into a complete personal management suite. It includes multiple integrated modules:

### 🗂️ **File Organizer** (Phase 1 - Rebuilt ✅)
- **ABSTRACT OPERATIONS ARCHITECTURE**: AI generates platform-agnostic operations
- **Pure Python Execution**: Operations run via `pathlib`/`shutil` (no shell)
- **AI-Powered File Organization**: Google Gemini integration for intelligent file categorization
- **Centralized Memory System**: SQLite database tracks all file operations and destination mappings
- **Simple USB Drive Recognition**: Hardware-based identification (USB Serial → Partition UUID → Label+Size)
- **Multi-Drive Support**: Detects and handles local, network (NAS), cloud, and USB drives
- **Redundant Archive Detection**: AI suggests deletion when content already extracted
- **Filename Cleaning**: Consistent rename operations (e.g., "Snatch (2000).mkv")
- **Project Detection**: .git folder recognition for project organization
- **PDF/DOC/TXT Content Reading**: Enhanced AI categorization based on file content
- **User-Controlled Actions**: Preview AI-generated operations before execution
- **Completed Actions Tracking**: All operations logged with success/failure status
- **No Folder Memory Files**: Eliminated `.homie_memory.json` clutter - all centralized in database
- **Cross-Platform USB Recognition**: Works on Linux, macOS, Windows
- **Module Isolation**: Separate database files for complete data isolation between modules
- **Security-First Design**: Validation, timeouts, comprehensive audit logging

### 🏠 **Home Server/NAS** (Phase 2)
- OneDrive-like personal cloud storage replacement
- File synchronization across devices
- Remote access and sharing capabilities
- Multi-device support (Windows, Linux, iOS, Android)

### 🎬 **Media Manager** (Phase 3)
- Netflix-like interface for personal movie/TV show collection
- Watch history tracking and recommendations
- "What to watch next" suggestions
- IMDB integration for ratings and metadata
- Progress tracking for series and movies

### 📄 **Document Management** (Phase 4)
- Organized storage for personal documents
- Categories: Zeiterfassung (time tracking), Lohnzettel (pay slips), Rechnungen (invoices)
- Invoice management for dual employment (employee + self-employed in Austria)
- Document OCR and automatic categorization

### 💰 **Financial Management** (Phase 5 - Complete ✅)
- **Account Management System**: Create, delete, and manage user accounts with different types (checking, savings, investment, cash)
- **Legacy Account Controls**: Enhanced management for system accounts (Main, Sparkonto, Aktien, Fonds) with popup menus
- **Manual Balance Date Tracking**: Set account balances with date tracking for historical accuracy and CSV import filtering
- **CSV Import with Date Filtering**: Import transactions only after manual balance date to prevent double-counting
- **Securities Portfolio**: Track investments with symbol, quantity, prices, and real-time gain/loss calculations
- **Inter-Account Transfers**: Transfer money between accounts with validation and history tracking
- **Enhanced UI/UX**: Comprehensive AccountManagementDialog with clean, professional design following user preferences
- Invoice tracking for Austrian tax requirements (incoming/outgoing)
- House construction cost tracking and budgeting
- Credit/loan management and payment predictions
- Future financial planning and affordability analysis
- Cash flow predictions for house construction expenses
- Flutter interface with comprehensive financial dashboard and account management

### 🌍 **DACH Market Expansion** (Phase 6 - Commercial Opportunity ✅ Researched)
- **Market Research Complete**: Comprehensive analysis of Austrian, German, and Swiss business invoice requirements
- **Unified Strategy Viable**: 80% of current Austrian solution reusable for Germany/Switzerland expansion
- **Massive Revenue Potential**: Combined €95-190M total addressable market across DACH region
- **Perfect Timing**: Germany mandatory B2B e-invoicing 2025-2028 creates urgent market opportunity
- **Technical Compatibility**: All three countries share EU VAT framework and similar compliance requirements
- **Premium Positioning**: Switzerland offers highest-value customers willing to pay premium for compliance tools

## 🎯 **CRITICAL: Abstract Operations Architecture**

### **Core Principle: AI Generates Abstract Operations; Backend Executes with Pure Python**
The File Organizer uses an **abstract operation architecture** where the AI generates platform-agnostic operations that work on any OS (Windows, Linux, macOS, Android, iOS). The backend executes these operations using pure Python (`pathlib`, `shutil`, `zipfile`, etc.) for reliability and cross-platform consistency.

### **How It Works:**
1. **AI Analysis**: Analyzes files and folder structure with destination memory  
2. **Abstract Operations**: AI returns JSON with universal operations:
   ```json
   {
     "operations": [
       {"type": "mkdir", "path": "/Movies", "parents": true},
       {"type": "move", "src": "/source/file.mkv", "dest": "/Movies/Clean Name.mkv"},
       {"type": "delete", "path": "/source/redundant.rar"}
     ],
     "explanations": ["Create directory", "Move and rename file", "Delete archive"],
     "fallback_operations": [
       {"type": "copy", "src": "/locked.txt", "dest": "/backup/", "reason": "File locked"}
     ]
   }
   ```
3. **Python Execution**: Backend maps each abstract operation to a pure Python implementation
4. **Cross-Platform Execution**: Same operations work on any platform without shell commands

### **Why This Is Superior:**
- ✅ **Truly cross-platform** - same operations work on Windows, Linux, macOS, Android, iOS
- ✅ **Permission-aware** - AI can check access and suggest fallbacks
- ✅ **Reliable** - pure Python file operations with structured error handling
- ✅ **AI has full intelligence** - can list directories, check permissions, handle archives
- ✅ **Smart fallbacks** - automatic alternatives when operations fail
- ✅ **Easy to debug** - operations are explicit and logged
- ✅ **Comprehensive logging** - all operations and results tracked

### **Complete Operation Set:**
- **File ops**: move, copy, delete, rename
- **Directory ops**: mkdir, list_dir  
- **Archive ops**: extract, compress, list_archive
- **Information**: get_info, get_size, check_exists, get_permissions
- **Security**: check_access, set_permissions, request_admin

### **API Endpoints:**
- `POST /api/file-organizer/organize` - AI analyzes and returns operations
- `POST /api/file-organizer/execute-operations` - Executes the generated operations with pure Python

**IMPORTANT**: Always use the abstract operation approach, and execute them via pure Python (no shell commands).

## ✅ **SOLVED: Flutter Linux Desktop Issues with Wayland**

### **BREAKTHROUGH: Wayland Solution for Linux Desktop**
**The Flutter Linux desktop rendering issues have been SOLVED using Wayland compositor!**

#### **Previous Issues (Now Resolved):**
1. ✅ **UI Flickering**: Resolved with Wayland compositor
2. ✅ **Black Popup Dialogs**: No longer occur with Wayland
3. ✅ **RenderShrinkWrappingViewport Errors**: Fixed by bypassing XCB
4. ✅ **Widget Tree Corruption**: Eliminated with Wayland display server
5. ✅ **Debug Flag Interference**: No longer affects Wayland rendering
6. ✅ **ListView.builder Failures**: Working correctly in Wayland
7. ✅ **Dialog State Management**: Full functionality restored

#### **Root Cause Identified:**
The issues were caused by **XCB/X11 threading bugs** in Flutter on Ubuntu 22.04/24.04. Wayland bypasses this entirely.

#### **SOLUTION: Use Wayland Compositor**
**NEW: Native Linux desktop support with Wayland:**

**Quick Start:**
```bash
# Launch full Homie app with Wayland (default)
./start_homie.sh

# Or launch File Organizer module only with Wayland (default)
./start_file_organizer.sh

# Legacy X11 versions (not recommended)
./start_homie.sh --x11
```

**Manual Setup (if needed):**
```bash
# 1. Install Wayland dependencies
sudo apt install -y weston wayland-protocols libwayland-dev

# 2. Start Python backend
cd backend && source venv/bin/activate && python main.py &

# 3. Set up Wayland environment
export WAYLAND_DISPLAY=wayland-0
export GDK_BACKEND=wayland

# 4. Start Wayland compositor
weston --backend=x11-backend.so --width=1400 --height=900 &

# 5. Build and run Flutter app
cd mobile_app
flutter build linux --release
export WAYLAND_DISPLAY=wayland-0
export GDK_BACKEND=wayland
./build/linux/x64/release/bundle/homie_app
```

#### **Wayland Benefits:**
- ✅ **Native Linux Desktop**: Full Flutter desktop functionality
- ✅ **Stable Rendering**: No more flickering or black dialogs
- ✅ **Proper Dialog Support**: All UI components work correctly
- ✅ **Better Performance**: Smoother animations and interactions
- ✅ **Modern Display Stack**: Uses Wayland instead of legacy X11

#### **Fallback Options:**
- **Flutter Web**: Still available via `./start_frontend_web.sh`
- **Direct X11**: Original desktop mode (with known issues)

## 🔧 **Current Implementation Status (September 2025)**

### **File Organizer - Recent Improvements**
**Backend Connectivity & Error Handling:**
- ✅ **Robust Backend Detection**: Frontend now checks backend availability before making API calls
- ✅ **Clear Error Messages**: Specific error messages for different connectivity issues:
  - Backend not running: "Backend server is not running. Please start the backend server first."
  - Timeout issues: "Request timed out. Please try again."
  - No files found: "No files found in the selected folder. Please select a folder with files to organize."
- ✅ **Timeout Handling**: 30-second timeout for API calls with proper error handling
- ✅ **Network Error Handling**: Proper handling of `SocketException` and `ClientException`
- ✅ **User-Friendly Feedback**: 5-second error message display with appropriate colors

**Database Integration:**
- ✅ **SQLite Database**: Centralized destination memory storage with enterprise-grade security
- ✅ **Destination Memory**: AI learns and remembers preferred folder locations for consistent organization
- ✅ **Multi-User Support**: Database supports multiple users with data isolation
- ✅ **Audit Logging**: All file operations logged with timestamps and user tracking

**AI Improvements:**
- ✅ **Redundant Archive Detection**: Automatically detects when RAR files contain already-extracted content
- ✅ **Filename Cleaning**: Removes prefixes like "Sanet.st." and standardizes movie names
- ✅ **Consistent Organization**: Uses destination memory to ensure files go to previously used folders
- ✅ **Enhanced Prompts**: AI prompts include specific rules for RAR handling and filename cleaning

**Security Implementation:**
- ✅ **Path Validation**: Prevents path traversal attacks
- ✅ **SQL Injection Prevention**: Parameterized queries throughout
- ✅ **Password Hashing**: bcrypt for secure user authentication
- ✅ **User Data Isolation**: Each user's data is properly isolated
- ✅ **Audit Logging**: Security events logged to `backend/logs/security.log`

### **Recent Achievements (2025-08-13/14)**
- ✅ **Backend Test Client Complete**: Full HTML/JavaScript test client with multi-user support
- ✅ **WebSocket Architecture Validated**: Confirmed Flask-SocketIO + gevent backend works correctly
- ✅ **Drive Monitoring Integration**: Real-time drive detection through File Organizer module
- ✅ **Multi-User Concurrent Testing**: Proven support for multiple simultaneous user connections
- ✅ **Fixed WebSocket Handlers**: Resolved async/sync compatibility issues in Flask-SocketIO
- ✅ **HTTP API Endpoints**: `/api/file_organizer/drives` endpoint for live drive information
- ✅ **Error Recovery**: Comprehensive error handling and debugging capabilities
- ✅ **File Organizer UI Enhancement**: Added destination folder input, organization style dropdown (By Type/Date/Smart/Custom), and dynamic custom intent field
- ✅ **Live USB Drive Detection**: Working real-time USB drive plug/unplug detection with immediate UI updates

### **Wayland Linux Desktop Solution (2025-09-10)** 🎉
- ✅ **Complete Flutter Linux Desktop Fix**: Solved all XCB/X11 rendering issues using Wayland compositor
- ✅ **Default Wayland Integration**: Both `start_homie.sh` and `start_file_organizer.sh` now use Wayland by default
- ✅ **Automatic Dependency Installation**: Scripts automatically install and configure Weston compositor
- ✅ **Backend Integration**: Smart backend detection - uses existing backend or provides clear error messages
- ✅ **Process Management**: Clean startup/shutdown with proper signal handling and process cleanup
- ✅ **Dynamic Socket Detection**: Automatically detects and uses available Wayland display sockets
- ✅ **User-Friendly Experience**: No manual flags needed - Wayland works out of the box
- ✅ **Legacy Support**: X11 mode still available via `--x11` flag for compatibility

### **Task 10 Testing Achievements (2025-01-24)**
- ✅ **Comprehensive Test Infrastructure**: 25 test files covering all major components
- ✅ **Dependency Resolution**: Fixed missing path_provider, connectivity_plus packages  
- ✅ **Compilation Error Fixes**: Resolved critical errors in performance widgets and memory manager
- ✅ **API Service Mocking**: Complete HTTP client mocking system with proper dependency injection
- ✅ **Test Results**: 368 passing tests vs 99 failing tests (79% success rate)
- ✅ **Cache & Data Management**: Enhanced testing for caching systems and data persistence
- ✅ **Cross-Platform Testing**: Desktop, mobile, and web integration tests running
- ✅ **Performance Benchmarks**: Memory optimization and caching performance tests
- ✅ **Error Handling Coverage**: Network, validation, and edge case test coverage

### Recent Bug Fixes (2025-08-18)
- ✅ **Critical API URL Fix**: Fixed File Organizer frontend connectivity
  - **Issue**: Flutter app used `/api/file-organizer/*` URLs (hyphen)
  - **Backend**: Expected `/api/file_organizer/*` URLs (underscore)  
  - **Result**: All File Organizer API calls returned 404 errors
  - **Fix**: Updated 15 endpoints in `api_service.dart` to use correct URL format
  - **Impact**: File Organizer frontend now connects properly to backend

### **Current Development Focus** 
- ✅ **Enhanced State Management Foundation**: Comprehensive FileOrganizerProvider and WebSocketProvider implementation with 22 unit tests passing
- ✅ **Modern UI Component Library Development**: Built ModernFileBrowser, EnhancedOrganizationSelector with advanced features
- ✅ **Organization Selector Improvements**: Enhanced dropdown with visual examples, preset management, organization history, and AI-powered suggestions
- 🔄 **Flutter Integration**: Enhanced state management integrated with modern UI components
- 🔄 **Real-World Testing**: Test File Organizer with actual files and comprehensive user workflows

### **Tab Structure Configuration Issues**

#### **Critical Requirement:**
- **Financial Manager tabs**: ONLY "Overview" and "Construction" 
- **NO "Securities" tab** - this was incorrectly added and caused user frustration
- **Add Security functionality**: Must be button in Overview tab, NOT separate tab

#### **Correct Implementation:**
```dart
TabController(length: 2, vsync: this);  // EXACTLY 2 TABS

tabs: const [
  Tab(text: 'Overview'),     // Tab 0 - contains Add Security button
  Tab(text: 'Construction'), // Tab 1 - construction budget tracking
  // NO SECURITIES TAB!
],

TabBarView(
  children: [
    _buildOverviewTab(provider),      // Tab 0 content
    _buildConstructionTab(provider),  // Tab 1 content
    // NO SECURITIES TAB CONTENT!
  ],
)
```

#### **Securities Functionality Location:**
- **Add Security Button**: Located in Overview tab, not separate tab
- **Design**: Blue gradient button after "Manage Accounts" button
- **Function**: Calls `_showAddSecurityDialog()` method

### **Add Security Dialog Issues**

#### **Black Popup Problem:**
**PERSISTENT PROBLEM**: Dialog becomes black screen when AI response arrives
- **Occurs on**: Both Linux desktop AND Flutter web
- **Trigger**: AI lookup response from backend causes widget corruption
- **Symptoms**: Input fields disappear, dialog becomes black, rendering errors
- **Status**: UNRESOLVED despite multiple fix attempts

#### **Root Causes Identified:**
1. **State Updates During Build**: `setState()` called during widget build cycle
2. **Provider Double Notifications**: Multiple `notifyListeners()` calls
3. **Dialog Context Corruption**: Provider context conflicts during dialog lifecycle
4. **Missing Error Handling**: Exceptions during AI lookup corrupt widget tree
5. **Complex Layout Structures**: Nested scrollable widgets cause rendering failures

#### **Attempted Fixes:**
```dart
// FAILED: Provider isolation
Consumer<FinancialProvider>(builder: (context, provider, child) { ... })

// FAILED: Callback pattern
onLookupSecurity: (symbol) async { ... }
onAddSecurity: (security) async { ... }

// FAILED: State management
bool _isLoading = false;
if (!mounted) return;

// FAILED: Layout simplification
Column(children: suggestions) // instead of ListView.builder
```

#### **Current Status:**
- Black popup still occurs on both Linux desktop AND web
- AI lookup triggers rendering corruption
- Input fields disappear when AI response arrives
- Error persists across all attempted fixes

### **Development Recommendations**

#### **Platform Strategy:**
1. **Primary Development**: Use Flutter Web (`flutter run -d chrome`)
2. **Testing**: Test on actual mobile devices (Android/iOS)
3. **Linux Desktop**: Avoid for development until Flutter engine fixes
4. **Production**: Target mobile platforms primarily

#### **Debug Configuration:**
```dart
// main.dart - DISABLE ALL DEBUG FLAGS
void main() {
  // debugRepaintRainbowEnabled = false; // KEEP DISABLED
  // debugPrintRebuildDirtyWidgets = false; // KEEP DISABLED
  // debugProfileBuildsEnabled = false; // KEEP DISABLED
  runApp(const HomieApp());
}
```

#### **Dialog Best Practices:**
```dart
// Use simple, static dialogs
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    // Avoid complex state management
    // Avoid nested Provider access
    // Use callbacks for data operations
  ),
);
```

### **Flutter Web Setup Script**
**Created**: `start_frontend_web.sh` for web development
```bash
#!/bin/bash
cd mobile_app
flutter run -d chrome
```

#### **User Interface Requirements:**
- **Design**: Clean, professional, minimal, uncluttered interface
- **Theme**: Dark theme preferred
- **No useless descriptions**: Avoid information overload in UI sections
- **Mobile-first**: Optimized for cross-platform use (Android, iOS, Web, Desktop)

### 🏦 **Salt Edge Open Banking Integration** (Phase 6 - In Progress 🚧)
- **Application Created Successfully** ✅ - Salt Edge developer account and application setup complete
- **Redirect URL Configured** ✅ - Using `http://127.0.0.1:3000/callback` for development
- **API Integration** ✅ - Complete backend services and endpoints implemented
- **Austrian Bank Support** ✅ - Erste Bank, Raiffeisen, Bank Austria, and more
- **AI-Powered Categorization** ✅ - Automatic transaction categorization with construction expense detection
- **Next**: Get API credentials and complete authentication setup

### 📱 **Mobile-First Design** (Complete ✅)
- Primary target: Cross-platform Flutter application
- Supports Android, iOS, Windows, macOS, Linux (NO WEB)
- Touch-optimized navigation and interactions
- Dashboard with module cards and seamless navigation
- Material 3 dark theme with responsive design

## Current Status
- **Phase**: File Organizer core implementation with abstract operations architecture
- **Priority**: Build AI-powered file organization after successful backend validation
- **Location**: `/home/mikele/Projects/Homie`
- **Target Platform**: Flutter cross-platform application
- **Easy Startup**: Use `./start_homie.sh` to launch both services
- **Backend Testing**: ✅ Complete - Multi-user test client validates WebSocket architecture (2025-08-13)
- **DACH Research Complete**: €95-190M market opportunity identified for future expansion
- **Recent Progress**: 
  - ✅ Complete Flutter app implementation with cross-platform support
  - ✅ AI-powered file organization with Google Gemini integration
  - ✅ Complete backend system with smart file analysis
  - ✅ Environment configuration with .env setup
  - ✅ Flask API server connecting Flutter frontend ↔ Python backend
  - ✅ Material 3 dark theme with modern UI design [[memory:2570958]]
  - ✅ Dashboard with File Organizer and Financial Manager modules
  - ✅ Provider pattern state management for reactive updates
  - ✅ Go Router navigation system for declarative routing
  - ✅ Complete API integration with error handling
  - ✅ Financial management with Austrian tax compliance
  - ✅ Documentation updated to reflect Flutter implementation
  - ✅ Startup scripts for easy development and deployment
  - ✅ Clean, professional UI redesign with minimal design approach
  - ✅ Fixed API endpoints to match actual backend implementation
  - ✅ Removed visual clutter and complex gradients for better UX
  - ✅ Real file operations: actual move and delete functionality
  - ✅ Enhanced user control with "Accept", "Specify", and "Delete" per file
  - ✅ Completed actions section with status tracking and timestamps
  - ✅ Memory/log system (.homie_memory.json) in both folders
  - ✅ Project detection with .git folder recognition
  - ✅ PDF/DOC/TXT content reading for better AI categorization
  - ✅ AI re-analysis with user input for "Specify" functionality
  - ✅ Compact button design with right-aligned actions
  - ✅ Salt Edge backend services implementation (8 API endpoints)
  - ✅ Austrian bank integration with construction expense detection
  - ✅ AI-powered transaction categorization system
  - ✅ Salt Edge developer account and application creation
  - ✅ Redirect URL configuration for OAuth flow
  - ✅ Account Management System: User account creation/deletion, legacy account controls
  - ✅ Enhanced CSV Import: Date-based filtering to prevent double-counting transactions
  - ✅ Securities Portfolio: Investment tracking with gain/loss calculations
  - ✅ Manual Balance Date Tracking: Historical accuracy with manual_balance_date field
  - ✅ Inter-Account Transfers: Money transfers between accounts with validation
  - ✅ AccountManagementDialog: Comprehensive UI for all account operations
  - ✅ Enhanced FinancialManager: UserAccount/Security dataclasses, enhanced API endpoints
  - ✅ UI/UX Improvements: Clean account management interface, removed clutter
  - ✅ DACH Market Research: Comprehensive analysis of Germany/Switzerland expansion potential
  - ✅ Backend Test Client: Complete multi-user test client with drive monitoring (2025-08-13)
  - ✅ WebSocket Architecture: Validated Flask-SocketIO + gevent backend works correctly
  - ✅ Task 10 Comprehensive Testing Suite: Enhanced test infrastructure with 368 passing tests
- ✅ Task 11.1 Material Design 3 Animation System: Smooth transitions, skeleton loading, and micro-interactions with comprehensive test suite
- 🚧 Current: File Organizer core implementation with abstract operations

## 🚀 Easy Startup Commands

### All Services
```bash
./start_homie.sh          # Starts both backend and frontend
```

### Full Application Services
```bash
./start_backend.sh        # Python API server (localhost:8000)
./start_frontend.sh       # Flutter app full dashboard (localhost:3000)
./start_frontend_web.sh   # Flutter web app full dashboard (localhost:33317)
```

### Linux Desktop with Wayland (✅ DEFAULT & RECOMMENDED)
```bash
# Full Homie app with Wayland (default - fixes all Linux desktop issues)
./start_homie.sh

# File Organizer module only with Wayland (default)
./start_file_organizer.sh

# Legacy X11 versions (not recommended due to rendering issues)
./start_homie.sh --x11
```

Additional notes:
- Hot reload (experimental): `./start_file_organizer.sh --hot-reload`
  - Uses `flutter run` with `--dart-define=INITIAL_ROUTE=/file-organizer`
  - Reads `HOMIE_ROUTE`, `HOMIE_SOURCE`, `HOMIE_DESTINATION` for routing/paths
- Fullscreen: set `FLUTTER_FULLSCREEN=true` to maximize the GTK window (implemented in `mobile_app/linux/runner/my_application.cc`).

### Module-Specific Services
```bash
# File Organizer Module Only (no back button, focused experience)
./start_file_organizer.sh      # Linux desktop version (Wayland default)
./start_file_organizer_web.sh  # Web version

# Financial Manager Module Only (no back button, focused experience)  
./start_financial.sh           # Linux desktop version (legacy X11)
./start_financial_web.sh       # Web version
```

### Manual Commands
```bash
# Backend
cd backend && source venv/bin/activate && python api_server.py

# Full Frontend
cd mobile_app && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000

# Module-Specific Frontend (using command line arguments)
cd mobile_app && flutter run -d chrome --dart-entrypoint-args="--route=/file-organizer"
cd mobile_app && flutter run -d chrome --dart-entrypoint-args="--route=/financial"
```

## 🏗️ **Multi-User Architecture & Database Design** (NEW! 📋)

### **Backend Deployment Scenarios**

#### **Scenario 1: Home Server/NAS Backend** 🏠
- **User Case**: User has own NAS/home server
- **Backend Location**: User's local network (e.g., `192.168.1.100:8000`)
- **Database**: SQLite on user's own hardware
- **Access**: Direct connection from mobile/desktop apps
- **Benefits**: Full data control, no cloud dependency, unlimited storage
- **Setup**: User installs Homie backend on their NAS/server

#### **Scenario 2: Cloud Backend Service** ☁️
- **User Case**: User wants convenience, no home server
- **Backend Location**: AWS/Cloud hosting (e.g., `api.homie-app.com`)
- **Database**: PostgreSQL/RDS with user isolation
- **Access**: Authenticated API calls with user accounts
- **Benefits**: No setup required, access from anywhere
- **Monetization**: Subscription-based service

#### **Scenario 3: Development/Localhost** 🔧
- **User Case**: Development and testing
- **Backend Location**: `localhost:8000`
- **Database**: SQLite for quick iteration
- **Access**: Direct connection for development
- **Purpose**: Testing new features before deployment

### **Centralized Authentication System** 🔐

#### **Authentication Outside Module Apps**
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

### **Database Architecture** 💾

#### **SQLite Database Structure** (Local/Development)
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

#### **Multi-Backend Data Synchronization**
- **Local Backend**: User's data stays on their hardware
- **Cloud Backend**: User data isolated by user_id in cloud database
- **Hybrid Mode**: Local primary + cloud backup (future feature)
- **Data Migration**: Tools to move from local to cloud backend

### **Module Integration Strategy** 🧩

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

#### **Future Module Addition**
- **Media Manager**: Same login, same database, new tables for media
- **Document Manager**: Extends file organization for business documents
- **Home Automation**: IoT device management with same user account
- **Family Sharing**: Multiple users per household with role-based access

### **AWS Integration Roadmap** 🌐

#### **Phase 1: Development** (Current)
- Local SQLite backend
- Single user development
- Feature development and testing

#### **Phase 2: Cloud Infrastructure**
- **RDS PostgreSQL**: Multi-user database
- **Cognito**: User authentication and management
- **API Gateway + Lambda**: Scalable API endpoints
- **S3**: File storage and backup
- **CloudFront**: CDN for media streaming

#### **Phase 3: Commercial Platform**
- **Multi-tenant SaaS**: Subscription-based service
- **User Onboarding**: Easy signup and backend connection
- **Premium Features**: Advanced AI, larger storage, priority support
- **Enterprise**: Custom deployments, SSO integration

### **Development Priorities & Implementation Roadmap** 📋

#### **🚀 Phase 1: SQLite Database Foundation** ✅ COMPLETE (2025-07-28)
**Goal**: Replace scattered `.homie_memory.json` files with centralized SQLite database

**Week 1: Database Foundation** ✅ COMPLETE
1. **SQLite Setup** - Created `backend/data/homie.db` with all required tables including module isolation
2. **DatabaseService** - Centralized database operations class with user_id and module_name isolation
3. **Module Isolation** - Complete module isolation with separate memory for each module
4. **Basic Testing** - Database operations working correctly with security validation

**Week 2: Destination Memory System** ✅ COMPLETE
1. **Drive Discovery** - Cross-platform drive detection (local, network, cloud, USB)
2. **Destination Tracking** - AI learns "movies → `/drive1/Movies`" patterns from database
3. **API Endpoints** - Backend endpoints for destination management and visualization
4. **AI Enhancement** - Feed destination memory to AI for consistent file organization
5. **Memory Persistence** - Learned patterns persist across app restarts
6. **Security Audit** - All operations logged with module tracking

**Immediate Value**:
- ✅ Consistent destination memory ("movies always go to X")
- ✅ Multi-drive support (local + OneDrive + NAS)
- ✅ Better AI organization with historical patterns
- ✅ Foundation for future multi-user system
- ✅ Complete module isolation (File Organizer, Financial Manager, etc.)
- ✅ Enterprise-grade security with audit trail

#### **🔮 Phase 2: Authentication & Multi-Backend** (2-4 weeks later)
**Goal**: Support both local development and future cloud deployment

**Authentication & User Management**
1. **User System** - Simple user management (start with single "dev" user)
2. **Authentication Service** - Login system outside modules, shared across File Organizer, Finance, etc.
3. **Backend Discovery** - Auto-detect local vs remote backends
4. **Flutter Integration** - Login screen, server connection management

**Multi-Backend Support**
1. **Local Backend Mode** - SQLite database on localhost/NAS
2. **Cloud Backend Mode** - Preparation for PostgreSQL/AWS
3. **Connection Management** - Seamless switching between backend types
4. **Data Synchronization** - User data consistency across backends

#### **🌐 Phase 3: AWS & Commercial Platform** (Future - 3+ months)
**Goal**: Cloud hosting and commercial viability

**AWS Infrastructure**
1. **RDS PostgreSQL** - Multi-tenant cloud database
2. **Cognito Authentication** - User authentication and management
3. **API Gateway + Lambda** - Scalable API endpoints
4. **S3 + CloudFront** - File storage and CDN

**Commercial Features**
1. **Multi-tenant SaaS** - Subscription-based service
2. **User Onboarding** - Easy signup and backend connection
3. **Premium Features** - Advanced AI, larger storage, priority support
4. **Mobile App Store** - Production releases on iOS/Android

#### **Current Focus: Phase 1 Implementation**
- **Next Task**: SQLite database setup with destination_mappings table
- **Development Environment**: localhost:8000 backend + Flutter web frontend
- **Target**: Solve immediate destination consistency problem
- **Foundation**: Prepare architecture for future multi-user commercial platform

## Key Architecture Principles
1. **Non-destructive by default** - Always suggest moves, never delete without explicit permission
2. **User control** - Users can configure automation level and override any decision
3. **Performance-first** - Designed to handle large file sets efficiently
4. **Extensible** - Modular design for easy feature additions
5. **Mobile-first** - Cross-platform Flutter app with responsive design
6. **Cross-platform compatibility** - Single codebase for all platforms

## Recent Technical Achievements

### DACH Market Expansion Research ✅ COMPLETED (2025-01-XX)
**Comprehensive analysis of German and Swiss market expansion opportunities:**

#### **Key Findings:**
- **Market Viability**: Germany and Switzerland expansion is highly feasible and strategically valuable
- **Technical Compatibility**: 80% of current Austrian AI invoice processor can be reused
- **Market Size**: Germany 9x larger than Austria (3.5M vs 400K businesses)
- **Revenue Potential**: Combined DACH region = €95-190M total addressable market
- **Perfect Timing**: Germany mandatory B2B e-invoicing 2025-2028 creates urgent need

#### **Implementation Strategy:**
- **Phase 1**: Germany first (next 6 months) - urgent e-invoicing mandate
- **Phase 2**: Switzerland next (6-12 months) - premium market opportunity
- **Revenue Projection**: €442K Year 1 → €1.42M Year 2 → €5M+ potential

#### **Technical Requirements:**
- **German Features**: CEN 16931 format, DATEV export, German tax validation
- **Swiss Features**: CHE number validation, Swiss accounting integration, CHF support
- **Unified Platform**: Single AI core with country-specific modules

#### **Business Opportunity:**
This represents a **€5M+ business opportunity** within 3-4 years, leveraging existing Austrian expertise across the German-speaking business compliance market.

### Module-Specific Launch Scripts ✅ COMPLETED (2025-07-22)
- **Standalone Module Scripts**: Created 4 new startup scripts for focused single-module experience
- **File Organizer Scripts**: `start_file_organizer.sh` and `start_file_organizer_web.sh` launch only File Organizer
- **Financial Manager Scripts**: `start_financial.sh` and `start_financial_web.sh` launch only Financial Manager
- **No Back Button**: Standalone launches remove back button for focused, single-purpose experience
- **Command Line Arguments**: Uses `--dart-entrypoint-args="--route=/module"` for runtime route specification
- **Flutter App Enhancement**: Modified main.dart to accept runtime route arguments via `main(List<String> args)`
- **Conditional UI**: Screens conditionally hide back buttons based on `isStandaloneLaunch` parameter
- **Architecture Decision**: Kept single codebase architecture; no module exclusion from builds (Flutter tree-shaking handles optimization)

### Account Management System ✅
- **User Account Management**: Complete CRUD operations for user-created accounts with different types (checking, savings, investment, cash)
- **Legacy Account Enhancement**: Enhanced controls for system accounts (Main Account, Sparkonto, Aktien, Fonds) with popup menus
- **Manual Balance Date Tracking**: AccountBalance dataclass enhanced with manual_balance_date field for historical accuracy
- **CSV Import Date Filtering**: Core logic to only process transactions after manual balance date, preventing double-counting
- **Securities Portfolio**: New Security dataclass for investment tracking with symbol, quantity, prices, and gain/loss calculations
- **Inter-Account Transfers**: Transfer functionality with validation and history tracking
- **Enhanced API Endpoints**: 10+ new endpoints for account creation, deletion, balance setting, transfers, and securities
- **Comprehensive UI**: AccountManagementDialog with clean, professional design following user preferences for minimal interface
- **Data Persistence**: Enhanced FinancialManager with proper JSON serialization and backward compatibility

### Salt Edge Open Banking Integration ✅
- **Backend Services**: Complete Salt Edge service implementation with 8 API endpoints
- **Bank Connection Manager**: Customer and connection persistence with status tracking
- **Transaction Sync**: Automatic import with intelligent Austrian/German keyword categorization
- **Data Enrichment**: AI-powered categorization using Gemini with ML models and rule-based categorization
- **Construction Expense Detection**: Automatic detection from Austrian hardware stores and service providers
- **Developer Account**: Successfully created Salt Edge developer account and application
- **OAuth Configuration**: Redirect URL configured as `http://127.0.0.1:3000/callback` for development
- **Austrian Bank Support**: Ready for Erste Bank, Raiffeisen, Bank Austria, and other Austrian banks

### Flutter Cross-Platform Implementation ✅
- **Complete App Structure**: Full Flutter application with Material 3 design
- **Cross-Platform Support**: Android, iOS, Windows, macOS, Linux from single codebase (NO WEB)
- **State Management**: Provider pattern for reactive state updates
- **Navigation**: Go Router for declarative routing
- **API Integration**: Complete HTTP client with error handling
- **Data Models**: JSON serialization for all data structures
- **Responsive Design**: Mobile-first design optimized for all screen sizes

### Smart AI Analysis System ✅
- **Document Processing**: OCR support for scanned PDFs, text extraction from Word docs
- **Content-Based Categorization**: AI analyzes document content to suggest proper organization
- **Archive Intelligence**: Detects redundant archives when extracted content already exists
- **Archive Extraction Suggestions**: Identifies archives that should be extracted for better organization
- **Project Detection**: Recognizes .git folders and treats projects as single units
- **User Input Integration**: AI re-analyzes files when user provides custom specifications
- **Memory System**: Comprehensive logging of all file operations and user interactions

### Robust Error Handling ✅
- **Quota Management**: Comprehensive 429 error handling for Gemini API limits
- **User-Friendly Messaging**: Clear explanations of quota limits and actionable suggestions
- **API Error Types**: Distinguishes between quota, authentication, API, and generic errors
- **Frontend Error Display**: Rich error messages with suggestions and quota information

### Backend API Excellence ✅
- **File Organizer API**: Complete endpoints for organize, execute-action, re-analyze
- **File Operations**: Real move and delete operations with error handling
- **AI Integration**: Re-analysis with user input for custom specifications
- **Memory Logging**: Automatic logging of all operations to .homie_memory.json
- **Financial API**: Comprehensive endpoints for summary, income, expenses, construction, tax reports
- **Salt Edge Banking API**: 8 endpoints for status, providers, connections, accounts, sync, enrichment, webhooks
- **Folder Browsing**: `/api/browse-folders` - File system navigation for path selection
- **Health Monitoring**: `/api/health` - System status and endpoint availability
- **Error Standards**: Consistent HTTP status codes and structured error responses

## Architecture Highlights

### System Components
- **Core Layer**: File System Abstraction, Metadata Engine, Rules Engine, Event System
- **Service Layer**: Organization, Configuration, Monitoring, Backup services
- **Banking Layer**: Salt Edge integration, Transaction sync, AI categorization
- **Interface Layer**: Flutter UI, REST API, Plugin API

### Data Management
- **Configuration**: JSON files in `backend/config/`
- **Database**: SQLite (simple) or PostgreSQL (scale)
- **Cache**: File hashes, thumbnails, ML models
- **Banking Data**: Encrypted transaction storage with GDPR compliance

### Security & Privacy
- Local processing by default
- Optional encryption at rest
- Minimal cloud data sharing
- User consent for all integrations
- PSD2 compliant banking integration
- OAuth 2.0 secure authentication

## Current Priorities
1. **🗂️ File Organizer Optimization**: Continue perfecting AI-powered file organization
2. **💰 Financial Manager Enhancement**: Improve account management and reporting features
3. **📱 Mobile Experience**: Optimize Flutter app performance and user experience
4. **🔧 Code Quality**: Maintain clean, well-documented codebase
5. **📊 User Feedback**: Gather feedback on existing modules before expansion

## Future Commercial Opportunities
1. **🌍 DACH Expansion**: €5M+ potential with Germany/Switzerland markets (researched, documented)
2. **🏦 Banking Integration**: Complete Salt Edge implementation for automated transaction import
3. **📄 Document AI**: Expand file organization intelligence to business document management
4. **🎯 Module Monetization**: Release individual modules as standalone commercial applications

## Module-Specific Launch Architecture ✅ COMPLETED (2025-07-22)

### New Startup Scripts Available:
- **Full Dashboard**: `./start_frontend.sh`, `./start_frontend_web.sh`
- **File Organizer Only**: `./start_file_organizer.sh`, `./start_file_organizer_web.sh`
- **Financial Manager Only**: `./start_financial.sh`, `./start_financial_web.sh`

### Technical Implementation:
- **Runtime Route Arguments**: Flutter app accepts `--route=/module` arguments via `main(List<String> args)`
- **Conditional Navigation**: Back buttons hidden in standalone launches using `isStandaloneLaunch` parameter
- **Single Codebase**: No module exclusion from builds; Flutter tree-shaking optimizes unused code
- **User Experience**: Focused, single-purpose application experience for specific workflows

## Development Guidelines 📋
**See `docs/GENERAL_RULES.md` for complete development guidelines including:**
- Date management for AI assistants
- Git workflow: always add → commit → push
- Git commit message format: `TopicOfJob: Description`
- Documentation standards
- Development practices

## Technology Stack (FINALIZED)

### Backend: Python 3.12+ (New Clean Architecture)
- **Framework**: Flask + Socket.IO with **gevent** async engine for WebSocket communication
- **Async Engine**: Gevent chosen for Python 3.12 compatibility and clean signal handling (Ctrl+C works properly)
  - **Why not eventlet**: Incompatible with Python 3.12 (missing `distutils`, broken `ssl.wrap_socket`)
  - **Why not threading**: Poor signal handling, hangs on shutdown, inferior WebSocket performance
- **Architecture**: Modular event-driven design with orchestrator pattern (`main.py` → core services → app modules)
- **AI Integration**: Google Gemini 1.5 Flash for file organization and transaction categorization
- **Document Processing**: PyPDF2, python-docx, pytesseract, pillow
- **Banking Integration**: Salt Edge API v6 with PSD2 compliance
- **ML Libraries**: pandas, numpy, scikit-learn for transaction categorization
- **Testing**: pytest
- **Code Quality**: black, flake8
- **Database**: SQLite
- **Config**: .env files, JSON configuration

### Frontend: Flutter (Dart)
- **Framework**: Flutter 3.0+ for cross-platform development
- **Platforms**: Android, iOS, Windows, macOS, Linux (NO WEB)
- **State Management**: Provider pattern for reactive state updates
- **Navigation**: Go Router for declarative routing
- **HTTP Client**: Built-in Dart HTTP client for API communication
- **UI Framework**: Material Design 3 with custom dark theme
- **Testing**: Flutter test framework for widget and integration tests
- **Code Quality**: Dart analyzer with strict linting rules

## Development Guidelines
- **IMPORTANT: Work in small, incremental steps** - Always explain what you're doing and wait for user confirmation before proceeding to the next step
- Use feature branches for development
- Write comprehensive tests for file operations

## Backend Rebuild Notes (2025-08-09)
- `main.py` is orchestrator-only; knows nothing about specific apps. It initializes `AppManager`, which registers modules without starting them.
- `WebServer` (`core/web_server.py`) owns host/port and provides HTTP/WebSocket endpoints.
- `AppManager` handles `start_module`/`stop_module` on demand.
- File Organizer structure:
  - `file_organizer_app.py`: coordinates; subscribes to events
  - `path_memory_manager.py`: central memory; OWNS `drives_manager.py`
  - `drives_manager.py`: drive discovery/monitoring (internal only)
  - `ai_command_generator.py`: builds prompts; returns abstract operations
  - `file_operation_manager.py`: executes operations with pure Python
- A test GUI app will visualize connections, events, and test pass/fail (to be built later).
