#!/bin/bash

# Homie Financial Manager Module Startup Script
# This script starts only the Financial Manager module of the Flutter app

echo "💰 Starting Homie Financial Manager Module..."

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

# Start the Flutter app on Linux desktop with Financial Manager module only
echo "🖥️ Starting Financial Manager module on Linux desktop"
echo "💡 Tip: Use 'r' for hot reload, 'R' for hot restart, 'q' to quit"
echo "💰 Direct route: Financial Manager module only"
flutter run -d linux --dart-entrypoint-args="--route=/financial" 