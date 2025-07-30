#!/bin/sh
# build.sh - Place this file in your Evidence git repository root

set -e

echo "Starting Evidence build process..."

# Copy source from git-sync volume to working directory
echo "Copying source code..."
cp -r /source/current/. /app/
cd /app

# Generate timestamp for this build
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BUILD_DIR="/builds/build-$TIMESTAMP"

echo "Building into: $BUILD_DIR"

# Install dependencies
echo "Installing dependencies..."
npm install

# Run Evidence build commands
echo "Running npm run sources..."
npm run sources

echo "Running npm run build:strict with custom outDir..."
npm run build:strict -- --outDir="$BUILD_DIR"

# Create/update the current symlink (atomic operation)
echo "Updating symlink..."
cd /builds
ln -sfn "build-$TIMESTAMP" current

# Clean up old builds (keep last 3)
echo "Cleaning up old builds..."
ls -t | grep "^build-" | tail -n +4 | xargs rm -rf 2>/dev/null || true

echo "Build completed successfully!"
echo "Build directory: $BUILD_DIR"
echo "Active build: /builds/current -> build-$TIMESTAMP"#!/bin/sh
# build.sh - Place this inside the evidence-builder container

set -e

echo "Starting Evidence build process..."

# Copy source from git-sync volume
echo "Copying source code..."
cp -r /source/current/. /app/

# Generate timestamp for this build
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BUILD_DIR="/builds/build-$TIMESTAMP"

echo "Building into: $BUILD_DIR"

# Create build directory
mkdir -p "$BUILD_DIR"

# Install dependencies
echo "Installing dependencies..."
npm install

# Run Evidence build commands
echo "Running npm run sources..."
npm run sources

echo "Running npm run build:strict with custom outDir..."
npm run build:strict -- --outDir="$BUILD_DIR"

# Create/update the current symlink (atomic operation)
echo "Updating symlink..."
cd /builds
ln -sfn "build-$TIMESTAMP" current

# Clean up old builds (keep last 3)
echo "Cleaning up old builds..."
ls -t | grep "^build-" | tail -n +4 | xargs rm -rf 2>/dev/null || true

echo "Build completed successfully!"
echo "Build directory: $BUILD_DIR"
echo "Active build: /builds/current -> build-$TIMESTAMP"