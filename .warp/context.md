# AI Agent Context - Homie

## Project Purpose
Homie is your comprehensive intelligent home management ecosystem that evolves from a smart file organizer into a complete personal management suite. It includes multiple integrated modules:

### 🗂️ **File Organizer** (Phase 1 - Current)
- Intelligently organizes files using AI
- Detects duplicates and suggests optimal folder structures
- Safe preview mode with rollback capabilities

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

### 💰 **Financial Management** (Phase 5)
- Invoice tracking for Austrian tax requirements (incoming/outgoing)
- House construction cost tracking and budgeting
- Credit/loan management and payment predictions
- Future financial planning and affordability analysis
- Cash flow predictions for house construction expenses

### 📱 **Mobile-First Design**
- Primary target: Smartphone application
- Responsive web interface that works perfectly on mobile
- Touch-optimized navigation and interactions
- Dashboard with mini-views of all sections

## Current Status
- **Phase**: Phase 1 File Organizer - Web interface working and tested ✅
- **Priority**: Create main dashboard and mobile-optimized navigation
- **Location**: `/home/mikele/Projects/Homie`
- **Target Platform**: Mobile-first responsive web app
- **Recent Progress**: 
  - ✅ AI-powered file organization with Google Gemini integration
  - ✅ Complete backend system with smart file analysis
  - ✅ Environment configuration with .env setup
  - ✅ Flask API server connecting frontend ↔ backend
  - ✅ Modern dark theme glassmorphism UI [[memory:2570958]]
  - ✅ Web interface with folder selection and quick paths working
  - ✅ Fixed frontend crashes and connection issues
  - ✅ Smart duplicate/redundant archive detection and suggestions
  - ✅ Document content analysis (OCR, PDF text extraction, Word docs)
  - ✅ Smart document categorization based on content analysis
  - ✅ Quota error handling for Gemini API with user-friendly messages
  - ✅ Enhanced error handling across frontend and backend
  - 🚧 Next: Create main dashboard with module navigation

## Key Architecture Principles
1. **Non-destructive by default** - Always suggest moves, never delete without explicit permission
2. **User control** - Users can configure automation level and override any decision
3. **Performance-first** - Designed to handle large file sets efficiently
4. **Extensible** - Modular design for easy feature additions

## Recent Technical Achievements

### Smart AI Analysis System ✅
- **Document Processing**: OCR support for scanned PDFs, text extraction from Word docs
- **Content-Based Categorization**: AI analyzes document content to suggest proper organization
- **Archive Intelligence**: Detects redundant archives when extracted content already exists
- **Archive Extraction Suggestions**: Identifies archives that should be extracted for better organization

### Robust Error Handling ✅
- **Quota Management**: Comprehensive 429 error handling for Gemini API limits
- **User-Friendly Messaging**: Clear explanations of quota limits and actionable suggestions
- **API Error Types**: Distinguishes between quota, authentication, API, and generic errors
- **Frontend Error Display**: Rich error messages with suggestions and quota information

### Backend API Excellence ✅
- **Folder Discovery**: `/api/discover` - Recursive directory scanning with performance metrics
- **AI Organization**: `/api/organize` - Smart file organization with confidence scores
- **Folder Browsing**: `/api/browse-folders` - File system navigation for path selection
- **Health Monitoring**: `/api/health` - System status and endpoint availability
- **Error Standards**: Consistent HTTP status codes and structured error responses

## Architecture Highlights

### System Components
- **Core Layer**: File System Abstraction, Metadata Engine, Rules Engine, Event System
- **Service Layer**: Organization, Configuration, Monitoring, Backup services
- **Interface Layer**: CLI, REST API, WebSocket, Plugin API

### Data Management
- **Configuration**: YAML/TOML in `~/.config/homie/`
- **Database**: SQLite (simple) or PostgreSQL (scale)
- **Cache**: File hashes, thumbnails, ML models

### Security & Privacy
- Local processing by default
- Optional encryption at rest
- Minimal cloud data sharing
- User consent for all integrations

## Current Priorities
1. **📱 Main Dashboard Creation**: Mobile-first layout with module cards and navigation
2. **🔧 Complete File Organizer Safety**: Preview mode, confirmation, rollback system
3. **📦 Archive Operations**: Automatic extraction with password support
4. **🏗️ API Mobile Optimization**: Design endpoints for future mobile app compatibility
5. **🔄 File Operations**: Implement actual move operations with safety checks

## Technology Stack (FINALIZED)

### Backend: Python 3.8+
- **Framework**: Flask with CORS support
- **AI Integration**: Google Gemini 1.5 Flash for file organization
- **Document Processing**: PyPDF2, python-docx, pytesseract, pillow
- **Testing**: pytest
- **Code Quality**: black, flake8
- **Database**: SQLite
- **Config**: .env files, JSON configuration

### Frontend: Svelte/SvelteKit
- **Package Manager**: npm
- **Styling**: Svelte scoped CSS with glassmorphism design
- **Testing**: vitest
- **Code Quality**: prettier, eslint
- **API Communication**: Fetch API with comprehensive error handling

## Development Guidelines
- **IMPORTANT: Work in small, incremental steps** - Always explain what you're doing and wait for user confirmation before proceeding to the next step
- Use feature branches for development
- Write comprehensive tests for file operations
- Follow safety-first approach for file modifications
- Update documentation with all changes
- Check TODO.md for current sprint priorities

## Architecture Decisions Made
- **Technology Stack**: Python 3.8+ backend + Svelte/SvelteKit frontend
- **Frontend Tools**: prettier, eslint, vitest (NO tailwindcss for CSS simplicity)
- **Data Flow**: Scanner → Metadata → Rules Engine → Action Executor
- **Storage Strategy**: Local-first with optional cloud integration
- **Security Model**: Privacy by design, local processing
- **Error Handling**: Operation rollback, partial failure recovery, quota management
- **Performance**: Multi-threaded, incremental scanning, resource management
- **Communication**: REST API between Python and Svelte, WebSocket for real-time updates

## Important Notes
- Architecture design and technology selection completed
- Technology stack: Python backend + Svelte frontend finalized
- Svelte setup: prettier, eslint, vitest selected (NO tailwindcss)
- Ready to begin Phase 1 implementation
- Safety is paramount due to file system operations
- Performance optimization is a key requirement
- User experience should prioritize control and transparency
- All file operations must be reversible
