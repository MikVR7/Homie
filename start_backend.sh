#!/bin/bash
set -euo pipefail

# Homie Backend Startup Script
# This script starts the new clean architecture backend

echo "🏠 Starting Homie Backend (New Architecture)..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python3 first:"
    echo "   sudo apt install python3 python3-pip"
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Ensure project venv exists and is used
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
  echo "📦 Creating project virtual environment (.venv)..."
  python3 -m venv "$PROJECT_ROOT/.venv"
fi

echo "📦 Activating project virtual environment (.venv)"
source "$PROJECT_ROOT/.venv/bin/activate"

# Free port 8000 if occupied
if command -v fuser &> /dev/null; then
  fuser -k 8000/tcp >/dev/null 2>&1 || true
elif command -v lsof &> /dev/null; then
  lsof -ti:8000 | xargs -r kill -9 >/dev/null 2>&1 || true
fi

# Change to backend directory
cd "$PROJECT_ROOT/backend"

# Install requirements into project venv
echo "📦 Installing Python dependencies into .venv..."
python -m pip install --upgrade pip >/dev/null 2>&1
python -m pip install -r requirements.txt --no-input | cat

# Verify critical deps
python -c "import flask_socketio, flask, socketio; print('✅ Deps OK')" >/dev/null 2>&1 || {
  echo "❌ Missing critical Python packages. Attempting reinstall..."
  python -m pip install flask==3.0.0 flask-cors==4.0.0 flask-socketio==5.3.6 python-socketio==5.10.0 --no-input | cat
}

# Check if .env file exists
if [ ! -f "../.env" ]; then
    echo "⚠️  .env file not found. Make sure to configure GEMINI_API_KEY"
    echo "   Copy from backend_old/.env if it exists"
fi

# Start the main orchestrator
echo "🚀 Starting Homie Backend Orchestrator..."
echo "🌐 Backend will be available at: http://localhost:8000"
echo "🧪 Test with: ./start_test.sh"
echo "🛑 Press Ctrl+C to stop"
export PYTHONUNBUFFERED=1
python main.py