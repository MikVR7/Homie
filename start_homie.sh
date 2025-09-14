#!/bin/bash

# Homie Complete Startup Script
# This script starts both backend and frontend services using Wayland by default
# Usage: ./start_homie.sh [--x11]

echo "🏠 Starting Homie - Intelligent Home Management System"
echo "======================================================"

# Check for X11 option (Wayland is now default)
USE_WAYLAND=true
if [[ "$1" == "--x11" ]]; then
    USE_WAYLAND=false
    echo "🔧 Using legacy X11 desktop (may have rendering issues)"
else
    echo "🔧 Using Wayland compositor for Linux desktop (default)"
fi

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
if [ "$USE_WAYLAND" = true ]; then
    # Check if backend is already running (don't kill existing backend!)
    echo "🔍 Checking for existing backend..."
    if ! curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
        echo "❌ Backend is not running! Please start the backend first with:"
        echo "  cd backend && source venv/bin/activate && python main.py"
        exit 1
    fi
    
    echo "✅ Backend is running on http://localhost:8000"
    
    # Start Flutter app with Wayland
    echo ""
    echo "📱 Starting Full Homie App with Wayland compositor..."
    
    # Check if Flutter app needs rebuilding
    NEEDS_REBUILD=false
    BUILD_PATH="mobile_app/build/linux/x64/release/bundle/homie_app"
    
    if [ ! -f "$BUILD_PATH" ]; then
        echo "🔧 Flutter Linux release build not found."
        NEEDS_REBUILD=true
    else
        echo "🔍 Checking if source code has changed..."
        
        # Find the newest source file in the Flutter app
        NEWEST_SOURCE=$(find mobile_app/lib -name "*.dart" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ -n "$NEWEST_SOURCE" ]; then
            # Compare modification times
            if [ "$NEWEST_SOURCE" -nt "$BUILD_PATH" ]; then
                echo "⚠️ Source code is newer than build. Rebuild needed."
                echo "📝 Changed file: $(basename "$NEWEST_SOURCE")"
                NEEDS_REBUILD=true
            else
                echo "✅ Build is up-to-date with source code"
            fi
        else
            echo "⚠️ Could not check source files. Forcing rebuild."
            NEEDS_REBUILD=true
        fi
    fi
    
    if [ "$NEEDS_REBUILD" = true ]; then
        echo "🔧 Building Flutter Linux release..."
        cd mobile_app
        flutter build linux --release
        cd ..
        echo "✅ Flutter Linux build completed"
    fi
    
    # Check if Wayland dependencies are installed
    if ! command -v weston &> /dev/null; then
        echo "🔧 Installing Wayland dependencies..."
        sudo apt update
        sudo apt install -y weston wayland-protocols libwayland-dev
    fi
    
    # Set up Wayland environment
    export XDG_RUNTIME_DIR=/tmp
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    
    # Kill any existing Weston processes
    pkill -f "weston" || true
    
    # Start Weston compositor
    echo "🔧 Starting Wayland compositor..."
    weston --backend=x11-backend.so --width=1400 --height=900 &
    WESTON_PID=$!
    
    # Wait for Weston to initialize
    sleep 5
    
    # Auto-detect the Wayland display
    WAYLAND_SOCKET=""
    for socket in /tmp/wayland-*; do
        if [[ -S "$socket" && "$socket" =~ wayland-[0-9]+$ ]]; then
            WAYLAND_SOCKET=$(basename "$socket")
            break
        fi
    done
    
    if [ -z "$WAYLAND_SOCKET" ]; then
        echo "❌ No Wayland socket found!"
        kill $WESTON_PID 2>/dev/null || true
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    
    echo "✅ Found Wayland display: $WAYLAND_SOCKET"
    
    # Launch full Homie app with Wayland (no route arguments = main menu)
    cd mobile_app
    export WAYLAND_DISPLAY="$WAYLAND_SOCKET"
    unset DISPLAY  # Force disable X11 display
    
    echo "🚀 Launching Full Homie App..."
    env WAYLAND_DISPLAY="$WAYLAND_SOCKET" GDK_BACKEND=wayland QT_QPA_PLATFORM=wayland XDG_RUNTIME_DIR=/tmp ./build/linux/x64/release/bundle/homie_app &
    FRONTEND_PID=$!
    cd ..
    
    echo ""
    echo "🎉 Homie is starting up with Wayland!"
    echo "📍 Backend API: http://localhost:8000"
    echo "📍 Flutter App: Running in Wayland compositor"
    echo ""
    echo "💡 Press Ctrl+C to stop all services"
    
    # Function to cleanup Wayland processes (leave backend running)
    cleanup_wayland() {
        echo ""
        echo "🛑 Shutting down Homie services..."
        kill $FRONTEND_PID 2>/dev/null || true
        kill $WESTON_PID 2>/dev/null || true
        # Note: We don't kill the backend - it was already running
        echo "✅ Frontend and compositor stopped (backend left running)"
        exit 0
    }
    
    # Override cleanup function for Wayland
    trap cleanup_wayland SIGINT SIGTERM
    
    # Wait for processes
    wait
else
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
fi 