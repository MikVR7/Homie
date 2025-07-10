#!/bin/bash

# Homie Backend Startup Script
# This script starts the Python API server for Homie

echo "🚀 Starting Homie Backend..."

# Change to backend directory
cd backend

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run setup first:"
    echo "   cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
echo "📦 Activating virtual environment..."
source venv/bin/activate

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Running setup..."
    python3 setup_env.py
    echo "📝 Please edit .env file and add your Google Gemini API key, then run this script again."
    exit 1
fi

# Start the API server
echo "🌟 Starting API server on http://localhost:8000"
python api_server.py 