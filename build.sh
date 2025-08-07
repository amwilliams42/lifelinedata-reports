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
npm run sources

npm run build:strict

# Use atomic move to prevent serving partial updates
echo "Copying build output..."
BUILD_TIMESTAMP=$(date +%s)
TEMP_DIR="/builds/temp-$BUILD_TIMESTAMP"

# Create temporary directory and copy files
mkdir -p "$TEMP_DIR"
cp -r build/* "$TEMP_DIR/"

# Atomic move - this ensures nginx doesn't serve partial updates
echo "Deploying new build..."
rm -rf /builds/old 2>/dev/null || true
# Move existing files to backup
if [ -d "/builds" ] && [ "$(ls -A /builds 2>/dev/null)" ]; then
    mkdir -p /builds-backup
    mv /builds/* /builds-backup/ 2>/dev/null || true
fi
# Move new files directly to /builds
mv "$TEMP_DIR"/* /builds/
rmdir "$TEMP_DIR"

# Clean up backup
rm -rf /builds-backup 2>/dev/null || true

# Signal nginx to reload (optional)
# docker exec nginx-reports nginx -s reload 2>/dev/null || true

echo "Build completed successfully at $(date)"