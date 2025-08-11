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

# Kill any previous server on 3000
if command -v fuser &> /dev/null; then
  fuser -k 3000/tcp >/dev/null 2>&1 || true
fi

# Start the test client server in background
echo "🌐 Starting test client server on http://localhost:3000"
echo "💡 This will test your Homie backend connection and events"
echo "📡 Make sure your backend is running on port 8000"
python3 server.py &
SERVER_PID=$!

# Ensure server stops on script exit
trap "echo ''; echo '🛑 Stopping test client server...'; kill $SERVER_PID 2>/dev/null; exit 0" INT TERM EXIT

# Give the server a moment to start
sleep 1

# Try to open the browser automatically (Linux)
if command -v xdg-open &> /dev/null; then
  echo "🌐 Opening browser at http://localhost:3000"
  xdg-open http://localhost:3000 >/dev/null 2>&1 || true
elif command -v sensible-browser &> /dev/null; then
  echo "🌐 Opening browser at http://localhost:3000"
  sensible-browser http://localhost:3000 >/dev/null 2>&1 || true
else
  echo "ℹ️  Please open your browser to: http://localhost:3000"
fi

# Keep foreground attached to server logs
wait $SERVER_PID