#!/bin/bash

# Homie Backend Startup Script
# This script starts the new clean architecture backend

echo "🏠 Starting Homie Backend (New Architecture)..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python3 first:"
    echo "   sudo apt install python3 python3-pip"
    exit 1
fi

# Change to backend directory
cd backend

# Check if requirements are installed
if [ ! -d "../backend_old/venv" ]; then
    echo "📦 Installing Python dependencies..."
    pip3 install -r requirements.txt
else
    echo "📦 Using existing virtual environment..."
    source ../backend_old/venv/bin/activate
fi

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
python3 main.py