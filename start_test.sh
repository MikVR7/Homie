#!/bin/bash

# Homie Backend Test Client Startup Script
# This script starts the test client to verify backend functionality

echo "🧪 Starting Homie Backend Test Client..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python3 first:"
    echo "   sudo apt install python3 python3-pip"
    exit 1
fi

# Change to test client directory
cd test_client

# Check if the test client exists
if [ ! -f "index.html" ]; then
    echo "❌ Test client files not found in test_client directory"
    exit 1
fi

# Start the test client server
echo "🌐 Starting test client server on http://localhost:3000"
echo "💡 This will test your Homie backend connection and events"
echo "📡 Make sure your backend is running on port 8000"
echo "🛑 Press Ctrl+C to stop"
python3 server.py