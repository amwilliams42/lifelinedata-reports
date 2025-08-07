#!/bin/bash
set -e

echo "Starting Evidence build process..."

# Navigate to the source directory
cd /source/current

# Install dependencies if needed
if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules/.package-lock.json" ]; then
    echo "Installing dependencies..."
    npm ci --production=false
fi

echo "Building Evidence project..."
npm run build

# Use atomic move to prevent serving partial updates
echo "Copying build output..."
BUILD_TIMESTAMP=$(date +%s)
TEMP_DIR="/builds/temp-$BUILD_TIMESTAMP"

# Copy to temporary directory first
mkdir -p "$TEMP_DIR"
cp -r build/* "$TEMP_DIR/"

# Atomic move - this ensures nginx doesn't serve partial updates
echo "Deploying new build..."
rm -rf /builds/current-old 2>/dev/null || true
mv /builds/current /builds/current-old 2>/dev/null || true
mv "$TEMP_DIR" /builds/current

# Clean up old build
rm -rf /builds/current-old 2>/dev/null || true

# Signal nginx to reload (optional)
# docker exec nginx-reports nginx -s reload 2>/dev/null || true

echo "Build completed successfully at $(date)"