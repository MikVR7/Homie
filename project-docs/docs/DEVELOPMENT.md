# Development Guide

## Environment Setup

### Required Environment Variables
Create a `.env` file in the `backend/` directory:

```bash
# Google Gemini API Key (required for AI-powered file organization)
GEMINI_API_KEY=your_gemini_api_key_here

# Raiffeisen Bank API (optional, for financial features)
RAIFFEISEN_CLIENT_ID=your_raiffeisen_client_id
RAIFFEISEN_CLIENT_SECRET=your_raiffeisen_client_secret
```

### Getting API Keys

#### Google Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add it to your `.env` file as `GEMINI_API_KEY`

#### Raiffeisen Bank API (Optional)
1. Register at [Raiffeisen Developer Portal](https://developer.raiffeisen.at/)
2. Create a new application
3. Add the credentials to your `.env` file

## Backend Development

### Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Running the Backend
```bash
# Start the orchestrator (starts core services and web server)
python main.py

# The server will be available at http://localhost:8000 (configured in `core/web_server.py`)
```

### Testing
```bash
# Run all tests
python -m pytest

# Run specific test
python test_file_organizer_database.py
python test_module_databases.py
```

## Frontend Development

### Setup
```bash
cd mobile_app
flutter pub get
```

### Running the Frontend

#### Web (Recommended for Development)
```bash
# Start Flutter web server
flutter run -d chrome

# The app will be available at:
# http://localhost:8080
```

#### Linux Desktop (Wayland recommended)
> IMPORTANT: Hot reload is NOT supported for the File Organizer app on Linux desktop. Do not use `--hot-reload` for development; prefer full runs via the script below.
```bash
# Recommended: run via Wayland script for stable rendering
./start_file_organizer.sh            # normal build/run

# Hot reload (experimental): may differ from release behavior
./start_file_organizer.sh --hot-reload

# Environment variables honored by scripts
#  - FLUTTER_FULLSCREEN=true  → native GTK maximize
#  - HOMIE_ROUTE, HOMIE_SOURCE, HOMIE_DESTINATION → initial route/paths
```

#### Mobile
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

## Known Issues

### Flutter Linux Desktop Notes
- Wayland scripts are provided; prefer `./start_file_organizer.sh` for desktop runs.
- Hot reload is NOT supported for this app on Linux desktop; use full restart instead of `--hot-reload`.

### Development Recommendations
1. **Use Flutter Web**: Most stable for development
2. **Test on Mobile**: Final testing should be on actual devices
3. **Backend First**: Test backend functionality before frontend integration

## API Endpoints

### File Organizer
- `POST /api/file-organizer/organize` - AI analyzes and returns abstract operations
- `POST /api/file-organizer/execute-operations` - Execute abstract operations (pure Python)
- Additional module endpoints may be exposed via `core/web_server.py`

### Financial Manager
- `GET /api/financial/summary` - Financial summary
- `GET/POST /api/financial/income` - Income management
- `GET/POST /api/financial/expenses` - Expense management
- `GET/POST /api/financial/construction` - Construction budget
- `GET /api/financial/tax-report` - Tax reporting
- `POST /api/financial/import-csv` - CSV import

### System
- `GET /api/health` - Health check
- `GET /api/status` - System status

## Database Architecture

### Module-Specific Databases
Each module has its own database file for complete isolation:

```
backend/data/
├── homie_users.db              # User management and authentication
└── modules/
    ├── homie_file_organizer.db    # File organization and destination memory
    ├── homie_financial_manager.db # Financial data and transactions
    ├── homie_media_manager.db     # Media library and watch history
    └── homie_document_manager.db  # Document management and OCR
```

### Testing Database Features
```bash
# Test module database architecture
python test_module_databases.py

# Test File Organizer database functionality
python test_file_organizer_database.py

# Test File Organizer learning (requires API key)
python test_file_organizer_learning.py

# Test SIMPLE USB drive recognition
python test_simple_usb.py

# Test centralized memory system (no more folder .json files)
python test_centralized_memory.py
```

## Development Workflow

### 1. Backend Development
1. **Start with tests**: Write tests for new features
2. **Database first**: Design database schema for new modules
3. **API endpoints**: Create REST endpoints for frontend
4. **Integration testing**: Test with real files/data

### 2. Frontend Development
1. **UI/UX design**: Create mockups and wireframes
2. **State management**: Design data flow with Provider
3. **Icons and assets**: Check Material Icons first, use ICONS_AND_ASSETS.md for custom needs
4. **API integration**: Connect to backend endpoints
5. **Testing**: Widget and integration tests

### 3. Integration Testing
1. **End-to-end testing**: Test complete workflows
2. **Real data testing**: Test with actual files and data
3. **Performance testing**: Ensure scalability
4. **User acceptance**: Get feedback from real users

## Code Quality

### Python Backend
- **Type hints**: Use type annotations
- **Docstrings**: Document all functions and classes
- **Error handling**: Comprehensive exception handling
- **Security**: Input validation and SQL injection prevention

### Flutter Frontend
- **Material Design 3**: Follow design guidelines
- **State management**: Use Provider pattern
- **Error handling**: Graceful error handling
- **Performance**: Optimize for mobile devices

## Deployment

### Local Development
```bash
# Backend
cd backend && python main.py

# Frontend
cd mobile_app && flutter run -d chrome
```

### Production Considerations
- **Database backups**: Regular backups of module databases
- **Security**: HTTPS, authentication, authorization
- **Monitoring**: Logging and error tracking
- **Scalability**: Load balancing and caching

## Troubleshooting

### Common Issues

#### API Key Issues
```bash
# Check if API key is loaded
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('GEMINI_API_KEY:', bool(os.getenv('GEMINI_API_KEY')))"
```

#### Database Issues
```bash
# Check database files
ls -la data/
ls -la data/modules/
```

#### Flutter Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

### Getting Help
1. **Check logs**: Look at console output for errors
2. **Test components**: Test individual parts separately
3. **Documentation**: Check this file and architecture docs
4. **Git history**: Look at recent changes for issues