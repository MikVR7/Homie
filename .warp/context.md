# AI Agent Context - Homie

## Project Purpose
Homie is your intelligent home file companion that evolves from a smart file organizer into a complete home media server. It intelligently organizes files, detects duplicates, and ultimately becomes a personal Netflix-like interface for your home server/NAS setup.

## Current Status
- **Phase**: Phase 1 implementation complete - Web interface working and tested ✅
- **Priority**: Modernize UI design and integrate AI organization features
- **Location**: `/home/mikele/Projects/Homie`
- **Recent Progress**: 
  - ✅ AI-powered file organization with Google Gemini integration
  - ✅ Complete backend system with smart file analysis
  - ✅ Environment configuration with .env setup
  - ✅ Flask API server connecting frontend ↔ backend
  - ✅ Integrated system architecture (not separate AI service)
  - ✅ Web interface with folder selection and quick paths working
  - ✅ Fixed frontend crashes and connection issues
  - 🚧 Next: Modernize UI design, integrate AI organization endpoint

## Key Architecture Principles
1. **Non-destructive by default** - Always suggest moves, never delete without explicit permission
2. **User control** - Users can configure automation level and override any decision
3. **Performance-first** - Designed to handle large file sets efficiently
4. **Extensible** - Modular design for easy feature additions

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

## Project Evolution (4 Phases)

### Phase 1: Intelligent File Organization
- Analyze unsorted folders and discover sorted folder structures
- Create persistent folder maps to avoid re-scanning
- Intelligently move files from unsorted to appropriate sorted locations
- Implement undo/rollback functionality for safety

### Phase 2: Duplicate Detection & Management
- Scan for duplicate files across all directories (content-based hashing)
- Detect files with different names but identical content (books, etc.)
- Provide user interface for duplicate management (delete/keep/rename/move)

### Phase 3: Remote Access
- REST API development
- Web interface for configuration
- Cloud service integrations
- Mobile companion app

### Phase 4: Advanced Features
- Plugin system architecture
- Multi-user support
- Enterprise features (LDAP, SSO)
- Advanced media server capabilities
- Netflix-like interface for movies, books, assets
- Media metadata integration (IMDB ratings, descriptions, thumbnails)

## Current Priorities
1. **Set up project structure**: Create backend and frontend directories
2. **Python Backend Setup**: Initialize virtual environment, dependencies, project structure
3. **Svelte Frontend Setup**: SvelteKit project with prettier, eslint, vitest
4. **Phase 1 Implementation**: Core foundation development
   - Basic file scanning and metadata extraction
   - Simple rule-based organization
   - CLI interface for manual operations
   - Local configuration management

## Technology Stack (FINALIZED)

### Backend: Python 3.8+
- **Testing**: pytest
- **Code Quality**: black, flake8
- **Database**: SQLite
- **Config**: YAML/TOML

### Frontend: Svelte/SvelteKit
- **Package Manager**: npm
- **Styling**: Svelte scoped CSS (no Tailwind)
- **Testing**: vitest
- **Code Quality**: prettier, eslint
- **Selected Tools**: prettier, eslint, vitest (NO tailwindcss)

## Documentation Structure
- `docs/README.md` - Project overview and quick start
- `docs/ARCHITECTURE.md` - Technical architecture and design decisions
- `docs/DEVELOPMENT.md` - Development setup and guidelines
- `docs/HISTORY.md` - Project timeline and major changes
- `docs/TODO.md` - Current tasks and future plans
- `.warp/context.md` - This file (AI agent context)

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
- **Error Handling**: Operation rollback, partial failure recovery
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
