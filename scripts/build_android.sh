#!/bin/bash
set -e

# Slay-The-Robot Android Build Script
# Usage: ./scripts/build_android.sh [debug|release]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/android-sdk}"

# Build type: debug or release (default: debug)
BUILD_TYPE="${1:-debug}"

echo "=== Slay-The-Robot Android Build ==="
echo "Project: $PROJECT_DIR"
echo "Build type: $BUILD_TYPE"
echo "Android SDK: $ANDROID_SDK_ROOT"

# Check Android SDK
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "ERROR: Android SDK not found at $ANDROID_SDK_ROOT"
    echo ""
    echo "To install Android SDK, run:"
    echo "  mkdir -p ~/android-sdk/cmdline-tools"
    echo "  cd ~/android-sdk/cmdline-tools"
    echo "  curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
    echo "  unzip commandlinetools.zip && mv cmdline-tools latest"
    echo "  yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses"
    echo "  ~/android-sdk/cmdline-tools/latest/bin/sdkmanager platform-tools platforms;android-34 build-tools;34.0.0"
    exit 1
fi

# Set environment variables
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# Check required SDK components
echo ""
echo "Checking Android SDK components..."
if [ -d "$ANDROID_SDK_ROOT/platforms/android-34" ]; then
    echo "✓ Android Platform 34"
else
    echo "✗ Android Platform 34 not found"
    echo "  Run: $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager platforms;android-34"
fi

if [ -d "$ANDROID_SDK_ROOT/build-tools/34.0.0" ]; then
    echo "✓ Build Tools 34.0.0"
else
    echo "✗ Build Tools 34.0.0 not found"
    echo "  Run: $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager build-tools;34.0.0"
fi

cd "$PROJECT_DIR"

# Create builds directory if not exists
mkdir -p builds

# Check export presets
if [ ! -f "export_presets.cfg" ]; then
    echo ""
    echo "ERROR: export_presets.cfg not found!"
    echo "Please ensure export_presets.cfg exists in the project root."
    exit 1
fi

# Build command
echo ""
if [ "$BUILD_TYPE" = "release" ]; then
    echo "Building Android Release..."
    echo "Output: builds/android_release.apk"
    godot --headless --export-release "Android Release" builds/android_release.apk
else
    echo "Building Android Debug..."
    echo "Output: builds/android_debug.apk"
    godot --headless --export-debug "Android Debug" builds/android_debug.apk
fi

echo ""
echo "=== Build Complete ==="
ls -lh builds/*.apk 2>/dev/null || echo "No APK files found"
echo ""
echo "APK generated successfully!"

# Print troubleshooting info if build failed
if [ $? -ne 0 ]; then
    echo ""
    echo "=== Troubleshooting ==="
    echo "If build failed, please check:"
    echo "1. Android SDK is properly configured"
    echo "2. Java is installed (java -version)"
    echo "3. Godot export templates are installed"
    echo "4. project.godot configuration is correct"
    echo ""
    echo "See docs/BUILD_ANDROID.md for detailed troubleshooting guide."
fi
