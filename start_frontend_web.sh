#!/bin/bash

# Homie Frontend Web Startup Script
# This script starts the Flutter web app in Chrome

echo "🌐 Starting Homie Flutter Web App..."

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

# Enable web support if not already enabled
echo "🔧 Ensuring Flutter web support is enabled..."
flutter config --enable-web

# Start the Flutter web app in Chrome
echo "🌐 Starting Flutter web app in Chrome"
echo "💡 Tip: Use 'r' for hot reload, 'R' for hot restart, 'q' to quit"
echo "🔗 App will open at: http://localhost:33317"
flutter run -d chrome --web-hostname localhost --web-port 33317 