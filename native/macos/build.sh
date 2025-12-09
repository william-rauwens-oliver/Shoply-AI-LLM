#!/bin/bash

echo "Building LLM Chat for macOS..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"

mkdir -p "$BUILD_DIR"

xcodebuild \
    -scheme LLMChat \
    -configuration Release \
    -arch arm64 \
    -derivedDataPath "$DERIVED_DATA" \
    -resultBundlePath "$BUILD_DIR/LLMChat.xcresult" \
    build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    APP_PATH="$DERIVED_DATA/Build/Products/Release/LLMChat.app"
    if [ -d "$APP_PATH" ]; then
        echo "Opening app..."
        open "$APP_PATH"
    fi
else
    echo "Build failed!"
    exit 1
fi
