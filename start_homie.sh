#!/bin/bash

# Homie Complete Startup Script
# This script starts both backend and frontend services

echo "🏠 Starting Homie - Intelligent Home Management System"
echo "======================================================"

# Function to cleanup background processes on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down Homie services..."
    jobs -p | xargs -r kill
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Make scripts executable
chmod +x start_backend.sh
chmod +x start_frontend.sh

# Start backend in background
echo "🚀 Starting backend API server..."
./start_backend.sh &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Check if backend started successfully
if ! ps -p $BACKEND_PID > /dev/null; then
    echo "❌ Backend failed to start. Please check the logs above."
    exit 1
fi

echo "✅ Backend started successfully (PID: $BACKEND_PID)"

# Start frontend
echo ""
echo "📱 Starting Flutter frontend..."
./start_frontend.sh &
FRONTEND_PID=$!

echo ""
echo "🎉 Homie is starting up!"
echo "📍 Backend API: http://localhost:8000"
echo "📍 Flutter App: http://localhost:3000"
echo ""
echo "💡 Press Ctrl+C to stop all services"

# Wait for both processes
wait 