#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$BASE_DIR/build"
ZIP_PATH="$BASE_DIR/cloudwatch-loki-shipper.zip"
SRC_DIR="$BASE_DIR/src"

# Clean up previous builds
rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$BUILD_DIR"

echo "Installing dependencies..."
poetry export -f requirements.txt --without-hashes --without dev -o "$BUILD_DIR/requirements.txt"

pip install -r "$BUILD_DIR/requirements.txt" -t "$BUILD_DIR" --platform manylinux2014_x86_64 --no-deps

echo "Copying source code..."
cp -r "$SRC_DIR"/* "$BUILD_DIR/"

rm "$BUILD_DIR/requirements.txt"

echo "Creating zip file..."
cd "$BUILD_DIR"
zip -r9 "$ZIP_PATH" .

echo "Lambda package created: $ZIP_PATH"

echo "Zip file contents:"
unzip -l "$ZIP_PATH" | head -20