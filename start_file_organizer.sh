#!/bin/bash

# Homie File Organizer Module Startup Script
# This script starts only the File Organizer module of the Flutter app

echo "📁 Starting Homie File Organizer Module..."

# Change to mobile app directory
cd mobile_app

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if dependencies are installed
if [ ! -d ".dart_tool" ]; then
    echo "📦 Installing Flutter dependencies..."
    flutter pub get
fi

# Start the Flutter app on Linux desktop with File Organizer module only
echo "🖥️ Starting File Organizer module on Linux desktop"
echo "💡 Tip: Use 'r' for hot reload, 'R' for hot restart, 'q' to quit"
echo "📁 Direct route: File Organizer module only"
flutter run -d linux --dart-entrypoint-args="--route=/file-organizer" 