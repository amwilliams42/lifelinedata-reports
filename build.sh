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

echo "Checking build output..."
ls -la build/

echo "Deploying to nginx volume..."
# Clear nginx directory and copy directly
rm -rf /builds/* 2>/dev/null || true
cp -r build/* /builds/

echo "Verifying deployment..."
ls -la /builds/

echo "Build completed successfully at $(date)"