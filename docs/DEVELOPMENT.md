# Development Guide

## Setup Instructions

### Prerequisites
- Python 3.8+ (with venv support)
- Node.js 16+ and npm (for frontend development)
- Google Gemini API key (for AI-powered organization)

### Backend Setup
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

### Frontend Setup
1. Navigate to frontend directory:
   ```bash
   cd ../frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Open http://localhost:3000 in your browser

### Web Interface Features ✅
- **Folder Selection**: Browse button and quick access paths
- **Real-time Status**: Live updates during folder discovery
- **Error Handling**: Connection status and health checks
- **Activity Log**: Detailed logging of all operations

## Backend Architecture

### Integrated System Structure
```