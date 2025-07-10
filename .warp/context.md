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
- Invoice tracking for Austrian tax requirements (incoming/outgoing)
- House construction cost tracking and budgeting
- Credit/loan management and payment predictions
- Future financial planning and affordability analysis
- Cash flow predictions for house construction expenses
- Flutter interface with comprehensive financial dashboard

### 📱 **Mobile-First Design** (Complete ✅)
- Primary target: Cross-platform Flutter application
- Supports Android, iOS, Web, Windows, macOS, Linux
- Touch-optimized navigation and interactions
- Dashboard with module cards and seamless navigation
- Material 3 dark theme with responsive design

## Current Status
- **Phase**: Phase 1 File Organizer - Complete ✅
- **Phase**: Phase 5 Financial Management - Complete ✅
- **Priority**: Implement file operations and preview mode for File Organizer
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
  - 🚧 Next: Add file access tracking to memory files

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
- **Folder Browsing**: `/api/browse-folders` - File system navigation for path selection
- **Health Monitoring**: `/api/health` - System status and endpoint availability
- **Error Standards**: Consistent HTTP status codes and structured error responses

## Architecture Highlights

### System Components
- **Core Layer**: File System Abstraction, Metadata Engine, Rules Engine, Event System
- **Service Layer**: Organization, Configuration, Monitoring, Backup services
- **Interface Layer**: Flutter UI, REST API, Plugin API

### Data Management
- **Configuration**: JSON files in `backend/config/`
- **Database**: SQLite (simple) or PostgreSQL (scale)
- **Cache**: File hashes, thumbnails, ML models

### Security & Privacy
- Local processing by default
- Optional encryption at rest
- Minimal cloud data sharing
- User consent for all integrations

## Current Priorities
1. **📂 File Access Tracking**: Add file open/access timestamps to memory files
2. **📦 Archive Operations**: Automatic extraction with password support
3. **🏗️ API Mobile Optimization**: Enhance endpoints for mobile app performance
4. **🔄 Batch Operations**: Implement bulk file operations with progress tracking
5. **🎬 Media Manager Module**: Begin implementation of next module

## Technology Stack (FINALIZED)

### Backend: Python 3.8+
- **Framework**: Flask with CORS support
- **AI Integration**: Google Gemini 1.5 Flash for file organization
- **Document Processing**: PyPDF2, python-docx, pytesseract, pillow
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
- Follow safety-first approach for file modifications
- Update documentation with all changes
- Check TODO.md for current sprint priorities
- Test on multiple platforms during development

## Architecture Decisions Made
- **Technology Stack**: Python 3.8+ backend + Flutter frontend
- **Frontend Framework**: Flutter for cross-platform mobile, web, and desktop support
- **State Management**: Provider pattern for reactive state updates
- **Navigation**: Go Router for declarative routing
- **Data Flow**: Scanner → Metadata → Rules Engine → Action Executor
- **Storage Strategy**: Local-first with optional cloud integration
- **Security Model**: Privacy by design, local processing
- **Error Handling**: Operation rollback, partial failure recovery, quota management
- **Performance**: Multi-threaded, incremental scanning, resource management
- **Communication**: REST API between Python and Flutter

## Important Notes
- Flutter implementation completed successfully
- Technology stack: Python backend + Flutter frontend finalized
- Cross-platform support: Single codebase for mobile, web, and desktop
- Material 3 dark theme implemented with user preferences [[memory:2570958]]
- Ready for next phase: File operations and preview mode implementation
- Safety is paramount due to file system operations
- Performance optimization is a key requirement
- User experience should prioritize control and transparency
- All file operations must be reversible
- Documentation updated to reflect Flutter implementation
