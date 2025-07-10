# Development Guide

## Setup Instructions

### Prerequisites
- Python 3.8+ (with venv support)
- Flutter SDK 3.0+ (https://flutter.dev/docs/get-started/install)
- Google Gemini API key (for AI-powered organization)

### Quick Setup & Start

#### 🚀 Easy Way (Recommended)
```bash
# Start everything at once
./start_homie.sh
```

#### 🔧 Individual Services
```bash
# Backend only
./start_backend.sh

# Frontend only
./start_frontend.sh
```

### Manual Setup (First Time)

#### Backend Setup
1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd Homie/backend
   ```

2. Create and activate virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Linux/Mac
   # or venv\Scripts\activate  # Windows
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment configuration:
   ```bash
   python3 setup_env.py
   nano .env  # Add your Gemini API key
   ```

5. Test the AI organization system:
   ```bash
   python3 test_smart_organizer.py
   ```

6. Start the backend API server:
   ```bash
   python3 api_server.py
   ```

#### Flutter Frontend Setup
1. Install Flutter SDK:
   - Follow the official Flutter installation guide: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. Navigate to mobile app directory:
   ```bash
   cd ../mobile_app
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   # For web (development)
   flutter run -d chrome

   # For mobile device (with device connected)
   flutter run

   # For desktop (Linux/Windows/macOS)
   flutter run -d linux    # or windows/macos
   ```

5. Build for production:
   ```bash
   # Android APK
   flutter build apk

   # iOS (requires macOS and Xcode)
   flutter build ios

   # Web
   flutter build web

   # Desktop
   flutter build linux    # or windows/macos
   ```

### Mobile App Features ✅
- **Cross-Platform**: Runs on Android, iOS, Web, and Desktop
- **Dark Theme**: Modern dark design with Material 3
- **Responsive Design**: Optimized for all screen sizes
- **Real-time Updates**: Provider pattern for reactive state management
- **API Integration**: Seamless communication with Python backend
- **Module Navigation**: Dashboard with File Organizer and Financial Manager

## Backend Architecture

### API Endpoints
- **File Organizer**:
  - `POST /api/file-organizer/organize` - AI-powered file organization analysis
  - `POST /api/file-organizer/execute-action` - Execute file operations (move, delete)
  - `POST /api/file-organizer/re-analyze` - Re-analyze files with user input
  - `POST /api/file-organizer/discover` - Discover files and folders
  - `POST /api/file-organizer/browse-folders` - Browse file system
- **Financial Manager**:
  - `GET /api/financial/summary` - Get financial overview
  - `GET /api/financial/income` - List income entries
  - `GET /api/financial/expenses` - List expenses
  - `GET /api/financial/construction` - Get construction budget
  - `GET /api/financial/tax-report` - Get tax report
- **System**:
  - `GET /api/health` - System health check
  - `GET /api/status` - API status and version

### Flutter Architecture

#### State Management
- **Provider Pattern**: Used for reactive state management
- **Providers**:
  - `AppState`: Global application state
  - `FileOrganizerProvider`: File organization data and operations
  - `FinancialProvider`: Financial data and operations

#### Navigation
- **Go Router**: Declarative routing system
- **Routes**:
  - `/` - Dashboard screen
  - `/file-organizer` - File organizer module
  - `/financial` - Financial manager module

#### Project Structure
```
mobile_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── theme/
│   │   └── app_theme.dart          # Material 3 dark theme
│   ├── providers/                   # State management
│   │   ├── app_state.dart
│   │   ├── file_organizer_provider.dart
│   │   └── financial_provider.dart
│   ├── services/
│   │   └── api_service.dart        # HTTP client for backend API
│   ├── models/                     # Data models with JSON serialization
│   │   ├── file_organizer_models.dart
│   │   └── financial_models.dart
│   ├── screens/                    # Main application screens
│   │   ├── dashboard_screen.dart
│   │   ├── file_organizer/
│   │   └── financial/
│   └── widgets/                    # Reusable UI components
│       ├── module_card.dart
│       ├── file_organizer/
│       └── financial/
├── test/                           # Widget and integration tests
└── pubspec.yaml                    # Dependencies and configuration
```

## Development Workflow

### Daily Development
```bash
# Start everything
./start_homie.sh

# Or start services individually
./start_backend.sh    # Backend API
./start_frontend.sh   # Flutter app
```

### Backend Development
1. Make changes to Python code
2. Test with `python test_smart_organizer.py`
3. Restart API server if needed
4. Test API endpoints with Flutter app

### Flutter Development
1. Make changes to Dart code
2. Hot reload with `r` in Flutter console
3. Test on multiple platforms
4. Run tests with `flutter test`

### Testing
- **Backend**: Run `pytest` in backend directory
- **Frontend**: Run `flutter test` in mobile_app directory
- **Integration**: Test API connectivity between backend and Flutter app

## Deployment

### Backend Deployment
- Deploy Python Flask app to your preferred hosting service
- Ensure all environment variables are configured
- Set up SSL/TLS for secure API communication

### Flutter Deployment
- **Web**: Deploy built web files to static hosting
- **Mobile**: Publish to App Store/Google Play Store
- **Desktop**: Distribute platform-specific builds

## Troubleshooting

### Common Issues
- **Flutter Doctor**: Run `flutter doctor` to check for setup issues
- **API Connection**: Ensure backend is running and accessible
- **CORS Issues**: Backend includes CORS headers for web development
- **Hot Reload**: Use `R` for hot restart if hot reload isn't working

### Startup Script Issues
- **Permission Denied**: Run `chmod +x *.sh` to make scripts executable
- **Backend Won't Start**: Check if virtual environment exists and .env is configured
- **Flutter Not Found**: Ensure Flutter SDK is installed and in PATH