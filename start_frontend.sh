#!/bin/bash

# Homie Frontend Startup Script
# This script starts the Flutter mobile app

echo "📱 Starting Homie Flutter App..."

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

# Start the Flutter app on Linux desktop
echo "🖥️ Starting Flutter app on Linux desktop"
echo "💡 Tip: Use 'r' for hot reload, 'R' for hot restart, 'q' to quit"
flutter run -d linux 