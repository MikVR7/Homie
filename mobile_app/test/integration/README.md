# Backend Integration Tests

This directory contains comprehensive integration tests for the Homie backend server. These tests validate the complete frontend-backend communication and ensure robust error handling.

## Test Categories

### 1. Backend Integration Tests (`backend_integration_test.dart`)
- **Health and Status Endpoints**: Validates `/api/health` and `/api/status`
- **File Organizer API**: Tests organize, execute-operations, and drives endpoints
- **AI Integration**: Tests AI connection and capabilities
- **Error Handling**: Invalid requests, non-existent endpoints, path traversal protection
- **CORS and Headers**: Cross-origin resource sharing validation
- **Performance and Load**: Concurrent requests and large operation handling
- **Data Validation**: Operation types and parameter validation

### 2. Data Consistency Tests (`data_consistency_test.dart`)
- **API Response Structure**: Validates response format consistency
- **Error Response Structure**: Consistent error handling across endpoints
- **File Operation Models**: Frontend model compatibility with backend responses
- **Frontend-Backend Compatibility**: Model mapping validation
- **API Service Integration**: Service layer consistency
- **Data Type Validation**: Date/time, boolean, and numeric field validation

### 3. WebSocket Integration Tests (`websocket_integration_test.dart`)
- **Basic Communication**: Connection establishment and message exchange
- **File Organizer Events**: Module switching and drive status events
- **WebSocket Provider Integration**: Provider lifecycle and event handling
- **Real-time Scenarios**: File operation progress and module notifications
- **Connection Stability**: Reconnection and timeout handling

### 4. Error Recovery Tests (`error_recovery_test.dart`)
- **Network Error Handling**: Offline detection, timeouts, DNS failures
- **API Error Responses**: HTTP 500/404 errors, malformed JSON
- **WebSocket Error Scenarios**: Connection failures, parsing errors
- **File Operation Errors**: Invalid paths, permission denied scenarios
- **Recovery Mechanisms**: Retry logic, reconnection, graceful degradation
- **Data Integrity**: Corrupted responses, unexpected structures

### 5. Integration Test Suite (`integration_test_suite.dart`)
- **Environment Validation**: Backend health, endpoint availability
- **Orchestrated Test Execution**: Coordinated test running
- **Performance Validation**: Response times and load handling
- **Comprehensive Reporting**: Test summary and issue identification

## Prerequisites

### Backend Server
The backend server must be running for integration tests:

```bash
cd backend
source venv/bin/activate  # On Windows: venv\Scripts\activate
python main.py
```

The server should be available at `http://localhost:8000`.

### Environment Configuration
For complete testing, configure the backend `.env` file:

```bash
# backend/.env
GEMINI_API_KEY=your_gemini_api_key_here
```

Without the AI key, some tests will skip AI-dependent features.

## Running Integration Tests

### Individual Test Files
Run specific test categories:

```bash
# Backend API tests
flutter test test/integration/backend_integration_test.dart

# Data consistency tests
flutter test test/integration/data_consistency_test.dart

# WebSocket tests
flutter test test/integration/websocket_integration_test.dart

# Error recovery tests
flutter test test/integration/error_recovery_test.dart
```

### Complete Integration Suite
Run the comprehensive test suite:

```bash
flutter test test/integration/integration_test_suite.dart
```

### All Integration Tests
Run all integration tests:

```bash
flutter test test/integration/
```

## Test Behavior

### Backend Availability Detection
- Tests automatically detect if the backend is running
- If backend is unavailable, tests are marked as skipped with helpful messages
- No tests fail due to backend unavailability

### Graceful Degradation
- AI-dependent tests handle missing API keys gracefully
- WebSocket tests work even if WebSocket server is unavailable
- Error tests validate proper error handling

### Test Data Management
- Tests create temporary directories and files as needed
- All test data is automatically cleaned up after tests
- Tests do not modify existing files or directories

## Expected Test Results

### With Backend Running
- **Backend Integration**: All tests should pass
- **Data Consistency**: All tests should pass
- **WebSocket Integration**: Most tests should pass (some may timeout)
- **Error Recovery**: All tests should pass
- **Integration Suite**: Should provide comprehensive health report

### Without Backend Running
- All tests are skipped with informative messages
- No test failures due to missing backend
- Helpful setup instructions are displayed

## Troubleshooting

### Backend Connection Issues
```
❌ Backend server is not available: SocketException
💡 Please start the backend server with: cd backend && python main.py
```

**Solution**: Start the backend server and ensure it's listening on port 8000.

### AI Configuration Issues
```
⚠️ AI integration not configured: No API key
```

**Solution**: Add `GEMINI_API_KEY` to `backend/.env` file.

### WebSocket Connection Issues
```
❌ WebSocket server is not available
```

**Solution**: Ensure the backend server is running with WebSocket support enabled.

### Permission Issues
```
❌ Permission denied scenarios handled
```

**Solution**: This is expected behavior - tests verify proper permission error handling.

## Test Coverage

### API Endpoints Tested
- ✅ `GET /api/health`
- ✅ `GET /api/status`
- ✅ `POST /api/file-organizer/organize`
- ✅ `POST /api/file-organizer/execute-operations`
- ✅ `GET /api/file_organizer/drives`
- ✅ `POST /api/test-ai`

### WebSocket Events Tested
- ✅ Connection establishment
- ✅ Module switching
- ✅ Drive status events
- ✅ Message exchange
- ✅ Error handling

### Error Scenarios Tested
- ✅ Network failures
- ✅ Timeout handling
- ✅ Invalid requests
- ✅ Permission errors
- ✅ Malformed data
- ✅ Recovery mechanisms

## Continuous Integration

These tests are designed for continuous integration environments:

1. **Environment Detection**: Automatically adapts to available services
2. **Non-Destructive**: No modification of existing data
3. **Comprehensive Reporting**: Detailed success/failure reporting
4. **Graceful Degradation**: Handles missing dependencies

### CI/CD Integration
Add to your CI pipeline:

```yaml
# Example GitHub Actions
- name: Start Backend Server
  run: |
    cd backend
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    python main.py &
    sleep 5  # Wait for server to start

- name: Run Integration Tests
  run: |
    cd mobile_app
    flutter test test/integration/
```

## Contributing

When adding new integration tests:

1. **Follow the Pattern**: Use the existing test structure
2. **Handle Backend Unavailability**: Always check `backendAvailable` flag
3. **Clean Up Resources**: Ensure proper cleanup in `tearDown`
4. **Document Test Purpose**: Add clear descriptions
5. **Test Error Cases**: Include both success and failure scenarios

## Test Statistics

- **Total Test Files**: 5
- **Backend API Tests**: 25+
- **WebSocket Tests**: 15+
- **Error Scenario Tests**: 20+
- **Data Consistency Tests**: 15+
- **Integration Suite Tests**: 10+

**Total Integration Tests**: 85+ comprehensive tests covering all aspects of backend integration.
