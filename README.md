# Homie - Intelligent Home Management Ecosystem

> **🎉 BREAKTHROUGH: Flutter Linux Desktop Issues SOLVED with Wayland!**  
> Native Linux desktop support is now fully functional using Wayland compositor.

Homie is your comprehensive intelligent home management platform that evolves from a smart file organizer into a complete personal management suite. Built with AI-powered automation and cross-platform compatibility.

## 🚀 Quick Start

### Linux Desktop (Recommended - NEW!)
```bash
# One-time setup: Install Wayland dependencies
./install_wayland_deps.sh

# Launch full Homie application with Wayland
./start_wayland_desktop.sh

# Or launch File Organizer module only
./start_file_organizer_wayland.sh
```

### Web Version (Universal)
```bash
# Start backend and web frontend
./start_homie.sh

# Or just web frontend
./start_frontend_web.sh
```

### All Platforms
```bash
# Traditional startup (all platforms)
./start_backend.sh    # Python API server
./start_frontend.sh   # Flutter desktop app
```

## ✨ Features

### 🗂️ File Organizer (Phase 1 - Complete)
- **AI-Powered Organization**: Google Gemini integration for intelligent file categorization
- **Abstract Operations Architecture**: Platform-agnostic operations with pure Python execution
- **Centralized Memory System**: SQLite database tracks all file operations and destination mappings
- **USB Drive Recognition**: Hardware-based identification with persistent memory
- **Multi-Drive Support**: Local, network (NAS), cloud, and USB drives
- **Content Analysis**: PDF/DOC/TXT content reading for enhanced AI categorization
- **User-Controlled Actions**: Preview AI-generated operations before execution

### 💰 Financial Manager (Phase 2 - Complete)
- **Account Management**: Create, delete, and manage multiple account types
- **CSV Import with Date Filtering**: Import transactions with intelligent date filtering
- **Securities Portfolio**: Investment tracking with real-time gain/loss calculations
- **Austrian Tax Compliance**: Specialized features for Austrian tax requirements
- **Construction Budget Tracking**: House construction cost tracking and budgeting
- **Inter-Account Transfers**: Money transfers between accounts with validation

### 🎬 Media Manager (Phase 3 - Planned)
- Netflix-like interface for personal movie/TV show collection
- Watch history tracking and AI-powered recommendations
- IMDB integration for ratings and metadata

### 📄 Document Management (Phase 4 - Planned)
- OCR support for scanned documents
- Automatic categorization for business documents
- Austrian business document management (Zeiterfassung, Lohnzettel, Rechnungen)

## 🖥️ Platform Support

### ✅ **Linux Desktop - SOLVED with Wayland**
**BREAKTHROUGH: All Flutter Linux desktop issues resolved!**

Previous issues (now fixed):
- ❌ UI Flickering → ✅ Stable rendering
- ❌ Black Popup Dialogs → ✅ Working dialogs
- ❌ Widget Tree Corruption → ✅ Proper state management
- ❌ XCB Threading Issues → ✅ Wayland bypass

**Solution**: Uses Wayland compositor to bypass XCB/X11 threading bugs entirely.

### Cross-Platform Support
- **Linux**: Native desktop (Wayland) + Web
- **Windows**: Native desktop + Web
- **macOS**: Native desktop + Web
- **iOS**: Native mobile app (planned)
- **Android**: Native mobile app (planned)
- **Web**: Progressive Web App with offline support

## 🏗️ Architecture

### Backend (Python 3.12+)
- **Framework**: Flask + Socket.IO with gevent async engine
- **AI Integration**: Google Gemini 1.5 Flash for file organization
- **Database**: SQLite with module-specific isolation
- **Security**: bcrypt, SQL injection prevention, audit logging

### Frontend (Flutter/Dart)
- **Framework**: Flutter 3.0+ for cross-platform development
- **UI**: Material Design 3 with dark theme
- **State Management**: Enhanced Provider architecture
- **Real-time**: WebSocket integration for live updates

### Database Architecture
```
backend/data/
├── homie_users.db              # User management
└── modules/
    ├── homie_file_organizer.db    # File organization
    ├── homie_financial_manager.db # Financial data
    ├── homie_media_manager.db     # Media library
    └── homie_document_manager.db  # Document management
```

## 🛠️ Installation

### Prerequisites
- **Python 3.12+** with pip and venv
- **Flutter 3.0+** (for native apps)
- **Node.js** (for web development)
- **Linux**: Wayland support (Ubuntu 22.04+ recommended)

### Setup Steps

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd Homie
   ```

2. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   # or venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   ```

3. **Environment Configuration**
   ```bash
   # Create .env file in backend directory
   echo "GEMINI_API_KEY=your_api_key_here" > backend/.env
   ```

4. **Flutter Setup** (for native apps)
   ```bash
   cd mobile_app
   flutter pub get
   flutter build linux --release  # or windows/macos
   ```

5. **Linux Desktop Setup** (recommended)
   ```bash
   # Install Wayland dependencies
   ./install_wayland_deps.sh
   ```

## 🚀 Usage

### Quick Launch Commands

```bash
# Linux Desktop with Wayland (RECOMMENDED)
./start_wayland_desktop.sh

# Web Version (Universal)
./start_frontend_web.sh

# Traditional Desktop (legacy)
./start_frontend.sh

# Module-Specific Launches
./start_file_organizer_wayland.sh  # File Organizer only (Wayland)
./start_file_organizer_web.sh      # File Organizer only (Web)
```

### Manual Launch

```bash
# 1. Start Backend
cd backend && source venv/bin/activate && python main.py

# 2. Start Frontend (choose one)
cd mobile_app && flutter run -d linux     # Native desktop
cd mobile_app && flutter run -d chrome    # Web version

# 3. For Wayland (Linux)
export WAYLAND_DISPLAY=wayland-0
export GDK_BACKEND=wayland
weston --backend=x11-backend.so --width=1400 --height=900 &
./mobile_app/build/linux/x64/release/bundle/homie_app
```

## 📊 Development Status

### ✅ Completed Modules
- **File Organizer**: AI-powered file organization with abstract operations
- **Financial Manager**: Complete Austrian tax-compliant financial management
- **Backend Infrastructure**: Flask + Socket.IO + SQLite architecture
- **Flutter Frontend**: Cross-platform Material Design 3 interface
- **Wayland Solution**: Linux desktop rendering issues completely resolved

### 🚧 In Progress
- Enhanced UI/UX improvements
- Performance optimizations
- Cross-platform testing

### 📋 Planned
- Media Manager module
- Document Management module
- Mobile app releases (iOS/Android)
- Cloud synchronization

## 🧪 Testing

### Run Tests
```bash
# Backend Tests
cd backend && python -m pytest

# Frontend Tests
cd mobile_app && flutter test

# Integration Tests
./start_test.sh
```

### Test Coverage
- **Backend**: Comprehensive API and database testing
- **Frontend**: Widget tests, integration tests, accessibility tests
- **Cross-Platform**: Tested on Linux, Windows, macOS

## 📚 Documentation

### Architecture Documentation
- [Core Architecture](project-docs/docs/ARCHITECTURE.md)
- [Abstract Command System](project-docs/docs/ABSTRACT_COMMAND_SYSTEM.md)
- [Centralized Memory System](project-docs/docs/CENTRALIZED_MEMORY.md)
- [Wayland Linux Solution](project-docs/docs/WAYLAND_LINUX_SOLUTION.md)

### Module Documentation
- [Modern File Organizer Frontend](project-docs/docs/MODERN_FILE_ORGANIZER_FRONTEND.md)
- [Development Guidelines](project-docs/docs/GENERAL_RULES.md)
- [USB Drive Memory Details](project-docs/docs/USB_DRIVE_MEMORY_DETAILS.md)

### Diagrams
- [System Architecture Diagrams](project-docs/diagrams/)
- [Module Dependencies](project-docs/diagrams/module_lifecycle_dependencies.xml)
- [Database Schema](project-docs/diagrams/database_architecture.xml)

## 🔧 Configuration

### Environment Variables
```bash
# Required
GEMINI_API_KEY=your_google_gemini_api_key

# Optional
HOMIE_DATA_DIR=backend/data  # Database location
HOMIE_HOST=localhost         # Server host
HOMIE_PORT=8000             # Server port
```

### Wayland Configuration
```bash
# Wayland environment (Linux)
export WAYLAND_DISPLAY=wayland-0
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
```

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make changes following the coding standards
4. Run tests and ensure they pass
5. Submit a pull request

### Coding Standards
- **Python**: PEP 8, type hints, comprehensive docstrings
- **Dart/Flutter**: Official Dart style guide, widget testing
- **Documentation**: Clear, comprehensive documentation for all features

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Google Gemini**: AI-powered file organization
- **Flutter Team**: Cross-platform framework
- **Wayland Community**: Modern Linux display server
- **Open Source Community**: Various libraries and tools

## 🎯 Key Achievements

- ✅ **Solved Flutter Linux Desktop Issues**: Complete Wayland solution
- ✅ **AI-Powered File Organization**: Intelligent, context-aware file management
- ✅ **Cross-Platform Compatibility**: Single codebase for all platforms
- ✅ **Austrian Tax Compliance**: Specialized financial management features
- ✅ **Modern Architecture**: Scalable, maintainable, secure design
- ✅ **Comprehensive Testing**: High test coverage with accessibility compliance

---

**Status**: Production Ready  
**Version**: 2025.09  
**Last Updated**: September 10, 2025

🚀 **Ready to revolutionize your home management with AI-powered automation!**


