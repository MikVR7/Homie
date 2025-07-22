# AI Agent Context - Homie

## Project Purpose
Homie is your comprehensive intelligent home management ecosystem that evolves from a smart file organizer into a complete personal management suite. It includes multiple integrated modules:

### 🗂️ **File Organizer** (Phase 1 - Complete ✅)
- Intelligently organizes files using AI with Google Gemini integration
- Real file operations: move, delete, and organize with user confirmation
- Project detection with .git folder recognition (no deep scanning)
- PDF/DOC/TXT content reading for better AI categorization
- User-controlled actions with "Accept", "Specify", and "Delete" options
- Completed actions tracking with timestamps and status icons
- Memory/log system tracking all operations in both source and destination folders
- Safe preview mode with individual file control
- Flutter cross-platform interface with Material 3 design

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

## 🚨 **CRITICAL: Flutter Linux Desktop Issues**

### **SEVERE RENDERING PROBLEMS ON LINUX MINT**
**Flutter on Linux desktop has fundamental rendering issues affecting production readiness:**

#### **Primary Issues Discovered:**
1. **UI Flickering**: Constant visual flickering during animations and UI updates
2. **Black Popup Dialogs**: Dialogs render completely black with missing input fields
3. **RenderShrinkWrappingViewport Errors**: Cascading `semantics.parentDataDirty` rendering failures
4. **Widget Tree Corruption**: State updates during build cycles corrupt the entire widget tree
5. **Debug Flag Interference**: Flutter debug flags cause additional visual artifacts
6. **ListView.builder Failures**: Scrollable content triggers infinite layout errors
7. **Dialog State Management**: Provider context conflicts destroy dialog functionality

#### **Error Messages Encountered:**
```
RenderShrinkWrappingViewport object was given an infinite size during layout.
The relevant error-causing widget was: ListView
semantics.parentDataDirty
════════ Exception caught by widgets library ════════
setState() called during build.
```

#### **ALL ATTEMPTED FIXES FAILED:**
- ✗ Disabling all debug flags (`debugRepaintRainbowEnabled = false`)
- ✗ Wrapping widgets with `RepaintBoundary`
- ✗ Disabling semantics (`Semantics(enabled: false)`)
- ✗ Replacing `ListView.builder` with `Column` widgets
- ✗ Simplifying dialog structures and layouts
- ✗ Adding `mounted` checks and proper state management
- ✗ Isolating Provider context in dialogs with Consumer widgets
- ✗ Using callback patterns instead of direct Provider access
- ✗ Removing nested scrollable widgets
- ✗ Adding explicit error handling in async operations

#### **WORKAROUND: Use Flutter Web**
**SOLUTION: Development must use Flutter Web on Linux:**
```bash
# Use this instead of flutter run -d linux
./start_frontend_web.sh
cd mobile_app && flutter run -d chrome
```

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
  // NEVER add Securities tab here!
]
```

#### **Add Security Dialog Black Popup Issue:**
**PERSISTENT PROBLEM**: Dialog becomes black screen when AI response arrives
- **Occurs on**: Both Linux desktop AND Flutter web
- **Trigger**: AI lookup response from backend causes widget corruption
- **Symptoms**: Input fields disappear, dialog becomes black, rendering errors
- **Status**: UNRESOLVED despite multiple fix attempts

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
- Supports Android, iOS, Web, Windows, macOS, Linux
- Touch-optimized navigation and interactions
- Dashboard with module cards and seamless navigation
- Material 3 dark theme with responsive design

## Current Status
- **Phase**: Phase 6 Salt Edge Open Banking Integration - Setting up credentials 🚧
- **Priority**: Complete Salt Edge API credentials setup and test bank connection
- **Location**: `/home/mikele/Projects/Homie`
- **Target Platform**: Flutter cross-platform application
- **Easy Startup**: Use `./start_homie.sh` to launch both services
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
  - 🚧 Current: Get Salt Edge API credentials and configure authentication

## 🚀 Easy Startup Commands

### All Services
```bash
./start_homie.sh          # Starts both backend and frontend
```

### Individual Services
```bash
./start_backend.sh        # Python API server (localhost:8000)
./start_frontend.sh       # Flutter app (localhost:3000)
```

### Manual Commands
```bash
# Backend
cd backend && source venv/bin/activate && python api_server.py

# Frontend
cd mobile_app && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

## Key Architecture Principles
1. **Non-destructive by default** - Always suggest moves, never delete without explicit permission
2. **User control** - Users can configure automation level and override any decision
3. **Performance-first** - Designed to handle large file sets efficiently
4. **Extensible** - Modular design for easy feature additions
5. **Mobile-first** - Cross-platform Flutter app with responsive design
6. **Cross-platform compatibility** - Single codebase for all platforms

## Recent Technical Achievements

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
- **Cross-Platform Support**: Android, iOS, Web, Desktop from single codebase
- **State Management**: Provider pattern for reactive state updates
- **Navigation**: Go Router for declarative routing system
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
1. **🏦 Salt Edge API Setup**: Get API credentials from Salt Edge dashboard
2. **🔑 Authentication Configuration**: Set up private/public keys and environment variables
3. **🧪 Bank Connection Testing**: Test connection with Austrian bank
4. **📱 Frontend Banking UI**: Integrate banking features into Flutter app
5. **🔄 Transaction Sync**: Implement automatic daily transaction import

## Technology Stack (FINALIZED)

### Backend: Python 3.8+
- **Framework**: Flask with CORS support
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
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux
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
