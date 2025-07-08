# Architecture

## System Overview

Homie is designed to intelligently organize files based on content, metadata, and user preferences, eventually growing into a comprehensive home media server with an intuitive interface for your media needs.

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
- Command-line interface for automation
- Configuration management
- Progress reporting and logging

## Technology Stack

### Backend (Core Logic)
- **Language**: Python 3.8+
- **Database**: SQLite for metadata and organization history
- **Configuration**: YAML/TOML files in `~/.config/homie/`
- **Testing**: pytest with comprehensive file operation tests
- **Code Quality**: black (formatting), flake8 (linting)

### Frontend (Web Interface)
- **Framework**: Svelte/SvelteKit for the web UI
- **Package Manager**: npm
- **Styling**: Svelte scoped CSS with CSS custom properties
- **Testing**: vitest for component and integration tests
- **Code Quality**: prettier (formatting), eslint (linting)
- **Build System**: Vite (integrated with SvelteKit)

### Architecture Pattern
- **Backend**: Modular Python services with clear separation of concerns
- **Frontend**: Component-based Svelte architecture
- **Communication**: REST API between Python backend and Svelte frontend
- **Data Flow**: Event-driven with WebSocket for real-time updates

## Design Decisions

### Key Principles
1. Non-destructive operations by default
2. User control over automation level
3. Extensible rule system
4. Performance-first for large file sets

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

### Data Storage

#### Configuration Storage
- **Format**: YAML/TOML for human readability
- **Location**: `~/.config/homie/` or `./config/`
- **Contents**: Rules, preferences, connection settings

#### Metadata Database
- **Type**: SQLite for simplicity, PostgreSQL for scale
- **Schema**: Files, metadata, organization history, user actions
- **Indexes**: Content hashes, file paths, metadata fields

#### Cache Layer
- **File Hashes**: Content-based deduplication
- **Thumbnails**: Generated previews for media files
- **ML Models**: Local models for content classification

### Security Architecture

#### Data Protection
- **Encryption at Rest**: Optional for sensitive file metadata
- **Secure Communications**: TLS for all network operations
- **Access Control**: Role-based permissions for shared access

#### Privacy by Design
- **Local Processing**: Content analysis happens locally
- **Minimal Cloud Data**: Only connection metadata goes to cloud
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

## Current Implementation (Phase 1 Complete)

### Integrated AI-Powered System ✅

**Backend Architecture:**
```
backend/
├── src/homie/
│   ├── smart_organizer.py     # 🤖 Google Gemini AI integration
│   ├── api_server.py          # Original backend API  
│   ├── discover.py            # Folder discovery system
│   └── main.py               # Core backend logic
├── api_server.py             # 🌐 Flask REST API server
├── test_smart_organizer.py   # 🧪 AI system testing
├── .env                      # 🔑 Environment configuration
└── venv/                     # Python virtual environment
```

**Frontend Integration:**
- Svelte/SvelteKit web interface
- REST API communication with backend
- Real-time file organization preview
- Folder selection and path management

**AI Integration Features:**
- **Smart Analysis**: Content-aware file categorization using Google Gemini
- **Context Awareness**: Understands existing folder structure
- **Metadata Extraction**: File type, size, content hints
- **Safe Preview**: Shows suggestions without moving files
- **Fallback Logic**: Rule-based organization if AI fails
- **Privacy Focus**: Only metadata sent to AI, never file content

**API Endpoints:**
- `GET /api/health` - System health check
- `POST /api/discover` - Basic folder discovery (legacy)
- `POST /api/organize` - AI-powered organization analysis

## Implementation Phases

### Phase 1: Core Foundation ✅ COMPLETE
- [x] Basic file scanning and metadata extraction
- [x] AI-powered intelligent organization
- [x] Web interface for user operations  
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
