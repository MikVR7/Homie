# Project Overview

Welcome to the Homie project! Homie is your intelligent home management ecosystem, designed as a mobile-first application suite that evolves from a smart file organizer into a complete personal management platform.

## Infrastructure Overview

Homie is designed to run as a self-hosted home server with a cross-platform mobile frontend, providing:
- Personal cloud storage with mobile and web interface
- File synchronization across devices
- Media streaming capabilities
- Remote access and sharing
- Financial management with Austrian tax compliance
- Document organization and management

### AWS Integration

While Homie runs primarily on your home server, AWS services may be utilized for:
- **Connection brokering**: AWS services to facilitate secure external connections
- **TURN/STUN services**: For WebRTC connections when direct P2P isn't possible
- **DNS management**: Route53 for dynamic DNS updates
- **CDN services**: CloudFront for optimized content delivery when needed
- **Backup services**: S3 for optional cloud backup integration

**Note**: AWS CLI is available and configured for any service integrations that may enhance the home server experience.

## ✨ AI-Powered File Organization

Homie features intelligent file organization powered by Google Gemini AI! 

### What Makes It Smart?
- **Content-aware analysis**: Understands file content, not just extensions
- **Existing structure awareness**: Respects your current folder organization
- **Intelligent suggestions**: Proposes new folders when needed
- **Safe preview mode**: Shows what it WOULD do without moving files
- **Confidence scoring**: AI provides reasoning and confidence for each suggestion

### Key Features
🤖 **AI Analysis**: Uses Google Gemini to intelligently categorize files
📊 **Smart Metadata**: Extracts file size, type, and content hints
🎯 **Context Aware**: Understands your existing folder structure
💡 **New Folder Suggestions**: Proposes logical new categories
📁 **Project Detection**: Recognizes .git folders and treats projects as single units
📄 **Content Reading**: Analyzes PDF, DOC, and TXT file content for better categorization
✅ **Real Operations**: Actually moves and deletes files with user confirmation
🎛️ **User Control**: Accept, Specify custom path, or Delete for each file
📝 **Memory System**: Logs all operations to .homie_memory.json files
⏰ **Action Tracking**: Completed actions section with timestamps and status
🔄 **AI Re-analysis**: Re-analyzes files when user provides custom specifications
🔒 **Privacy Focused**: Only sends metadata to AI, never actual file content

## 📱 Mobile-First Design

Homie is built as a **Flutter cross-platform application** that works seamlessly on:
- **Android** smartphones and tablets
- **iOS** devices (iPhone and iPad)
- **Web browsers** (desktop and mobile)
- **Desktop** applications (Windows, macOS, Linux)

### Current Modules
- **📁 File Organizer**: AI-powered file organization with real operations and memory tracking
- **💰 Financial Manager**: Austrian tax-compliant financial tracking
- **🏠 Media Manager**: Coming soon - Netflix-style media library
- **📄 Document Manager**: Coming soon - Austrian business document management

## Quick Start

### 🚀 Easy Startup (Recommended)

**Start Everything:**
```bash
./start_homie.sh
```
This starts both backend and frontend services automatically!

**Individual Services:**
```bash
# Backend only
./start_backend.sh

# Frontend only  
./start_frontend.sh
```

### Manual Startup Commands

**Backend (Python API):**
```bash
cd backend && source venv/bin/activate && python api_server.py
```

**Frontend (Flutter App):**
```bash
cd mobile_app && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

### Access Points
- **🌐 Flutter Web App**: http://localhost:3000
- **🔗 Backend API**: http://localhost:8000
- **📱 Mobile**: Run `flutter run` for device deployment

### For Developers

#### Backend Setup
1. Clone the repository
2. Follow setup instructions in DEVELOPMENT.md
3. Get your Google Gemini API key from https://makersuite.google.com/app/apikey
4. Set up the backend:
   ```bash
   cd backend
   python setup_env.py
   # Edit .env file with your API key
   python test_smart_organizer.py
   ```

#### Flutter Frontend Setup
1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Set up the mobile app:
   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```

### For Users
- **📱 Mobile App**: Run the Flutter app on your device
- **🌐 Web Interface**: Access via web browser when backend is running
- **🖥️ Desktop App**: Use the Flutter desktop build

For more detailed information, check the other documentation files.
