# Development Guide

## Setup Instructions

### Prerequisites
- Python 3.8+ (with venv support)
- Flutter SDK 3.0+ (https://flutter.dev/docs/get-started/install)
- Google Gemini API key (for AI-powered organization)

## 🚨 **CRITICAL: Flutter Linux Desktop Issues**

### Known Flutter Linux Problems
**Flutter on Linux desktop (especially Linux Mint) has severe rendering issues that affect production readiness:**

#### Primary Issues Discovered:
1. **UI Flickering**: Constant visual flickering during animations and state updates
2. **Black Popup Dialogs**: Dialogs render as black screens with missing input fields
3. **RenderShrinkWrappingViewport Errors**: `semantics.parentDataDirty` cascading rendering failures
4. **Widget Tree Corruption**: State updates during build cycles cause widget corruption
5. **Debug Flag Interference**: `debugRepaintRainbowEnabled` and similar flags cause additional flickering
6. **ListView.builder Issues**: `RenderShrinkWrappingViewport` errors in scrollable content
7. **Dialog State Management**: Provider context conflicts during dialog lifecycle

#### Error Messages Encountered:
```
RenderShrinkWrappingViewport object was given an infinite size during layout.
The relevant error-causing widget was: ListView
semantics.parentDataDirty
════════ Exception caught by widgets library ════════
setState() called during build.
```

#### Attempted Fixes (FAILED):
- ✗ Disabling all debug flags (`debugRepaintRainbowEnabled = false`)
- ✗ Wrapping with `RepaintBoundary` widgets
- ✗ Disabling semantics (`Semantics(enabled: false)`)
- ✗ Replacing `ListView.builder` with `Column` widgets
- ✗ Simplifying dialog structures
- ✗ Adding `mounted` checks and proper state management
- ✗ Isolating Provider context in dialogs
- ✗ Using callbacks instead of direct Provider access

#### Workaround: Flutter Web Development
**SOLUTION: Use Flutter Web for development on Linux:**
```bash
# Use web instead of Linux desktop
./start_frontend_web.sh
# or manually:
cd mobile_app && flutter run -d chrome
```

### Flutter Tab Structure Issues

#### Critical Tab Configuration Problem:
**User requirement**: Financial Manager should ONLY have "Overview" and "Construction" tabs
**Problem**: Mistakenly added "Securities" tab causing user frustration

#### Correct Tab Structure:
```dart
TabController(length: 2, vsync: this);  // ONLY 2 TABS!

tabs: const [
  Tab(text: 'Overview'),     // Tab 0
  Tab(text: 'Construction'), // Tab 1
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

#### Securities Functionality Location:
- **Add Security Button**: Located in Overview tab, not separate tab
- **Design**: Blue gradient button after "Manage Accounts" button
- **Function**: Calls `_showAddSecurityDialog()` method

### Add Security Dialog Issues

#### Black Popup Problem:
**Primary Issue**: Dialog renders as black screen when AI response arrives

#### Root Causes Identified:
1. **State Updates During Build**: `setState()` called during widget build cycle
2. **Provider Double Notifications**: Multiple `notifyListeners()` calls
3. **Dialog Context Corruption**: Provider context conflicts during dialog lifecycle
4. **Missing Error Handling**: Exceptions during AI lookup corrupt widget tree
5. **Complex Layout Structures**: Nested scrollable widgets cause rendering failures

#### Attempted Fixes:
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

#### Current Status:
- Black popup still occurs on both Linux desktop AND web
- AI lookup triggers rendering corruption
- Input fields disappear when AI response arrives
- Error persists across all attempted fixes

### Development Recommendations

#### Platform Strategy:
1. **Primary Development**: Use Flutter Web (`flutter run -d chrome`)
2. **Testing**: Test on actual mobile devices (Android/iOS)
3. **Linux Desktop**: Avoid for development until Flutter engine fixes
4. **Production**: Target mobile platforms primarily

#### Debug Configuration:
```dart
// main.dart - DISABLE ALL DEBUG FLAGS
void main() {
  // debugRepaintRainbowEnabled = false; // KEEP DISABLED
  // debugPrintRebuildDirtyWidgets = false; // KEEP DISABLED
  // debugProfileBuildsEnabled = false; // KEEP DISABLED
  runApp(const HomieApp());
}
```

#### Dialog Best Practices:
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

### Flutter Web Setup Script
**Created**: `start_frontend_web.sh` for web development
```bash
#!/bin/bash
cd mobile_app
flutter run -d chrome
```

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

# Frontend only (WEB - recommended for Linux)
./start_frontend_web.sh

# Frontend only (Desktop - problematic on Linux)
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
  - `GET /api/financial/account-balances` - Get all account balances
  - `POST /api/financial/accounts` - Create new user account
  - `DELETE /api/financial/accounts/{id}` - Delete user account
  - `GET /api/financial/accounts` - Get all user accounts
  - `POST /api/financial/accounts/{type}/balance` - Set account balance with optional date tracking
  - `POST /api/financial/transfer` - Transfer money between accounts
  - `POST /api/financial/import-csv` - Import CSV transactions with date filtering
  - `GET /api/financial/securities` - Get securities portfolio
  - `POST /api/financial/securities` - Add new security to portfolio
- **System**:
  - `GET /api/health` - System health check
  - `GET /api/status` - API status and version

### Flutter Architecture

#### State Management
- **Provider Pattern**: Used for reactive state management
- **Providers**:
  - `AppState`: Global application state
  - `FileOrganizerProvider`: File organization data and operations
  - `FinancialProvider`: Financial data and operations with account management

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
│           └── account_management_dialog.dart  # Comprehensive account management
├── test/                           # Widget and integration tests
└── pubspec.yaml                    # Dependencies and configuration
```

## New Features - Account Management

### Backend Enhancements
- **AccountBalance**: Enhanced with `manual_balance_date` field for CSV import filtering
- **UserAccount**: New dataclass for user-created accounts with id, name, type, balance, timestamps
- **Security**: New dataclass for investment tracking with symbol, quantity, prices, gain/loss
- **Enhanced FinancialManager**: Account CRUD operations, balance setting with dates, transfers, securities management
- **CSV Import Logic**: Date-based filtering to only process transactions after manual balance date

### Frontend Features
- **AccountManagementDialog**: Comprehensive dialog for all account operations
- **User Account Section**: Create/delete custom accounts with type selection
- **Legacy Account Section**: Enhanced controls with popup menus (Set Balance, Import CSV, View Transactions, Transfer)
- **Balance Setting**: Radio buttons for Set/Add/Subtract with date picker and live preview
- **Securities Section**: Add/view investment portfolio
- **Transfer Functionality**: Between accounts with validation

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