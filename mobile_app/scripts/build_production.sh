#!/bin/bash

# Production Build Script for Homie File Organizer
# Optimizes and builds the Flutter app for production deployment

set -e  # Exit on any error

echo "🚀 Starting production build for Homie File Organizer..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="build/web"
BACKUP_DIR="build/backup_$(date +%Y%m%d_%H%M%S)"
DART_DEFINES=""

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
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the mobile_app directory."
    exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backend-url)
            BACKEND_URL="$2"
            DART_DEFINES="$DART_DEFINES --dart-define=BACKEND_URL=$2"
            shift 2
            ;;
        --analytics-key)
            ANALYTICS_KEY="$2"
            DART_DEFINES="$DART_DEFINES --dart-define=ANALYTICS_KEY=$2"
            shift 2
            ;;
        --sentry-dsn)
            SENTRY_DSN="$2"
            DART_DEFINES="$DART_DEFINES --dart-define=SENTRY_DSN=$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --backend-url URL     Backend API URL (default: http://localhost:8000)"
            echo "  --analytics-key KEY   Analytics tracking key"
            echo "  --sentry-dsn DSN      Sentry error reporting DSN"
            echo "  --version VERSION     App version (e.g., 1.2.0)"
            echo "  --build-number NUM    Build number"
            echo "  --clean               Clean build (remove previous build artifacts)"
            echo "  --help                Show this help message"
            exit 0
            ;;
        *)
            print_warning "Unknown option: $1"
            shift
            ;;
    esac
done

# Set defaults if not provided
BACKEND_URL=${BACKEND_URL:-"http://localhost:8000"}
VERSION=${VERSION:-"1.0.0"}
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%s)}

print_status "Build configuration:"
echo "  Backend URL: $BACKEND_URL"
echo "  Version: $VERSION"
echo "  Build Number: $BUILD_NUMBER"
echo "  Clean Build: ${CLEAN_BUILD:-false}"

# Step 1: Clean previous build if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_status "Cleaning previous build artifacts..."
    flutter clean
    rm -rf $BUILD_DIR
    print_success "Build artifacts cleaned"
fi

# Step 2: Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Step 3: Run code generation if needed
if [ -f "build.yaml" ] || grep -q "build_runner" pubspec.yaml; then
    print_status "Running code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Step 4: Backup existing build if it exists
if [ -d "$BUILD_DIR" ]; then
    print_status "Backing up existing build..."
    mkdir -p build
    mv "$BUILD_DIR" "$BACKUP_DIR"
    print_success "Backup created at $BACKUP_DIR"
fi

# Step 5: Copy production HTML template
print_status "Preparing production HTML template..."
if [ -f "web/production.html" ]; then
    cp web/production.html web/index_backup.html
    cp web/production.html web/index.html
    print_success "Production HTML template applied"
else
    print_warning "Production HTML template not found, using default"
fi

# Step 6: Build for web with optimizations
print_status "Building Flutter web app for production..."

BUILD_COMMAND="flutter build web \
    --release \
    --web-renderer html \
    --tree-shake-icons \
    --source-maps \
    --dart2js-optimization O4 \
    --build-name $VERSION \
    --build-number $BUILD_NUMBER \
    $DART_DEFINES"

if [ -n "$ANALYTICS_KEY" ]; then
    print_status "Analytics integration enabled"
fi

if [ -n "$SENTRY_DSN" ]; then
    print_status "Error reporting integration enabled"
fi

echo "Executing: $BUILD_COMMAND"
eval $BUILD_COMMAND

# Step 7: Restore original HTML
if [ -f "web/index_backup.html" ]; then
    mv web/index_backup.html web/index.html
fi

# Step 8: Post-build optimizations
print_status "Applying post-build optimizations..."

# Update service worker cache version
if [ -f "$BUILD_DIR/sw.js" ]; then
    CACHE_VERSION="v$(date +%s)"
    sed -i.bak "s/CACHE_VERSION = '[^']*'/CACHE_VERSION = '$CACHE_VERSION'/g" "$BUILD_DIR/sw.js"
    rm -f "$BUILD_DIR/sw.js.bak"
    print_success "Service worker cache version updated to $CACHE_VERSION"
fi

# Optimize images (if tools are available)
if command -v optipng &> /dev/null; then
    print_status "Optimizing PNG images..."
    find "$BUILD_DIR" -name "*.png" -exec optipng -o2 {} \;
    print_success "PNG images optimized"
fi

if command -v jpegoptim &> /dev/null; then
    print_status "Optimizing JPEG images..."
    find "$BUILD_DIR" -name "*.jpg" -o -name "*.jpeg" -exec jpegoptim --max=85 {} \;
    print_success "JPEG images optimized"
fi

# Generate build info
print_status "Generating build information..."
cat > "$BUILD_DIR/build_info.json" << EOF
{
  "version": "$VERSION",
  "buildNumber": "$BUILD_NUMBER",
  "buildTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "gitCommit": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "buildEnvironment": "production",
  "backendUrl": "$BACKEND_URL"
}
EOF

# Step 9: Security headers file for web servers
print_status "Creating security headers configuration..."
cat > "$BUILD_DIR/.htaccess" << 'EOF'
# Security Headers for Apache
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
    
    # Content Security Policy
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' ws: wss: https:;"
</IfModule>

# Cache Control
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    
    # Don't cache HTML and service worker
    ExpiresByType text/html "access plus 0 seconds"
    ExpiresByType application/javascript "access plus 0 seconds" env=service_worker
</IfModule>

# Compression
<IfModule mod_deflate.c>
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png|ico)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</IfModule>

# Handle Flutter web routing
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^.*$ /index.html [L]
EOF

# Step 10: Create deployment package
print_status "Creating deployment package..."
cd build
tar -czf "homie-file-organizer-${VERSION}-${BUILD_NUMBER}.tar.gz" web
cd ..

# Step 11: Build summary
print_success "Production build completed successfully!"
echo ""
echo "📊 Build Summary:"
echo "  Version: $VERSION"
echo "  Build Number: $BUILD_NUMBER"
echo "  Build Time: $(date)"
echo "  Build Size: $(du -sh $BUILD_DIR | cut -f1)"
echo "  Output Directory: $BUILD_DIR"
echo "  Deployment Package: build/homie-file-organizer-${VERSION}-${BUILD_NUMBER}.tar.gz"
echo ""
echo "🚀 Deployment Instructions:"
echo "  1. Extract the deployment package to your web server"
echo "  2. Configure your web server to serve the files"
echo "  3. Ensure the backend is accessible at: $BACKEND_URL"
echo "  4. Test the application thoroughly"
echo ""
echo "📋 Next Steps:"
echo "  • Test the build locally: cd $BUILD_DIR && python -m http.server 8080"
echo "  • Run lighthouse audit for performance validation"
echo "  • Deploy to staging environment for testing"
echo "  • Configure monitoring and analytics"
echo ""

if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo "💾 Previous build backed up to: $BACKUP_DIR"
fi

print_success "Build script completed!"
