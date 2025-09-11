#!/bin/bash

# Homie File Organizer - Wayland Launcher
# Launches the File Organizer (or full app) using Wayland to avoid XCB/X11 display issues

set -e

# Configuration
FULL_APP=false

# Hardcoded test paths for File Organizer
SOURCE_PATH="/media/mikele/ca305bd0-fafb-43b3-8aa4-a596350bb34b/home/mikele/TestingHomie/Source"
DESTINATION_PATH="/media/mikele/ca305bd0-fafb-43b3-8aa4-a596350bb34b/home/mikele/TestingHomie/Destination"

# Check for --full-app argument only
if [[ "$1" == "--full-app" ]]; then
    FULL_APP=true
    echo "🚀 Starting Full Homie App with Wayland..."
else
    echo "🗂️ Starting File Organizer Module with Wayland..."
    echo "📁 Using hardcoded test paths:"
    echo "   Source: $SOURCE_PATH"
    echo "   Destination: $DESTINATION_PATH"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "mobile_app/pubspec.yaml" ]; then
    print_error "Please run this script from the Homie project root directory"
    exit 1
fi

# Check if Wayland dependencies are installed
print_status "Checking Wayland dependencies..."
if ! command -v weston &> /dev/null; then
    print_warning "Weston (Wayland compositor) not found. Installing..."
    sudo apt update
    sudo apt install -y weston wayland-protocols libwayland-dev
    print_success "Wayland dependencies installed"
else
    print_success "Wayland dependencies found"
fi

# Check if Flutter app is built
if [ ! -f "mobile_app/build/linux/x64/release/bundle/homie_app" ]; then
    print_warning "Flutter Linux release build not found. Building..."
    cd mobile_app
    flutter build linux --release
    cd ..
    print_success "Flutter Linux build completed"
else
    print_success "Flutter Linux build found"
fi

# Check if backend is already running
print_status "Checking for existing backend..."
if ! curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
    print_error "Backend is not running! Please start the backend first with:"
    print_error "  cd backend && source venv/bin/activate && python main.py"
    exit 1
fi

print_success "Backend is running on http://localhost:8000"

# Kill any existing Weston processes (but leave backend alone)
pkill -f "weston" || true

# Set up Wayland environment
print_status "Setting up Wayland environment..."
export XDG_RUNTIME_DIR=/tmp
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland

# Start Weston compositor in background
print_status "Starting Weston compositor..."
weston --backend=x11-backend.so --width=1400 --height=900 &
WESTON_PID=$!

# Wait for Weston to initialize
sleep 3

# Check if Weston is running
if ! pgrep -x "weston" > /dev/null; then
    print_error "Weston failed to start"
    exit 1
fi

# Wait for Wayland to be fully ready
print_status "Waiting for Wayland compositor to be ready..."
sleep 3

# Auto-detect the Wayland display
WAYLAND_SOCKET=""
for socket in /tmp/wayland-*; do
    if [[ -S "$socket" && "$socket" =~ wayland-[0-9]+$ ]]; then
        WAYLAND_SOCKET=$(basename "$socket")
        break
    fi
done

if [ -z "$WAYLAND_SOCKET" ]; then
    print_error "No Wayland socket found!"
    print_status "Available sockets:"
    ls -la /tmp/wayland-* 2>/dev/null || echo "None found"
    kill $WESTON_PID 2>/dev/null || true
    exit 1
fi

export WAYLAND_DISPLAY="$WAYLAND_SOCKET"
print_success "Found Wayland display: $WAYLAND_DISPLAY"

# Prepare launch arguments
if [ "$FULL_APP" = true ]; then
    print_status "Launching Full Homie App with Wayland..."
    LAUNCH_ARGS=""
    SUCCESS_MSG="🎉 Full Homie App launched successfully with Wayland!"
else
    print_status "Launching File Organizer module with Wayland..."
    LAUNCH_ARGS="--route=/file-organizer --source=$SOURCE_PATH --destination=$DESTINATION_PATH"
    SUCCESS_MSG="🎉 File Organizer module launched successfully with Wayland!"
fi

cd mobile_app

# Set Wayland environment variables and disable X11
export WAYLAND_DISPLAY="$WAYLAND_SOCKET"
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export XDG_RUNTIME_DIR=/tmp
unset DISPLAY  # Force disable X11 display

print_status "Launching with Wayland display: $WAYLAND_DISPLAY"

# Launch with explicit Wayland environment and proper runtime directory
env WAYLAND_DISPLAY="$WAYLAND_SOCKET" GDK_BACKEND=wayland QT_QPA_PLATFORM=wayland XDG_RUNTIME_DIR=/tmp ./build/linux/x64/release/bundle/homie_app $LAUNCH_ARGS &
FLUTTER_PID=$!
cd ..

print_success "$SUCCESS_MSG"
print_status "Weston PID: $WESTON_PID"
print_status "Flutter PID: $FLUTTER_PID"

# Function to cleanup on exit
cleanup() {
    print_status "Shutting down File Organizer..."
    kill $FLUTTER_PID 2>/dev/null || true
    kill $WESTON_PID 2>/dev/null || true
    # Note: We don't kill the backend - it was already running
    print_success "File Organizer processes terminated (backend left running)"
}

# Set up signal handlers
trap cleanup EXIT INT TERM

print_status "Press Ctrl+C to stop all services"
print_status "Backend available at: http://localhost:8000"
if [ "$FULL_APP" = true ]; then
    print_status "Full Homie App running in Wayland compositor"
else
    print_status "File Organizer module running in Wayland compositor"
fi

# Wait for user to stop
wait 