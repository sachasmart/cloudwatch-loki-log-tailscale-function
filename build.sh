#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$BASE_DIR/build"
ZIP_DIR="$BASE_DIR/publish"
ZIP_PATH="$ZIP_DIR/cloudwatch-loki-shipper.zip"
SRC_DIR="$BASE_DIR/src"

rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$BUILD_DIR"
mkdir -p "$ZIP_DIR"

echo "Installing dependencies..."
poetry export -f requirements.txt --without-hashes --without dev -o "$BUILD_DIR/requirements.txt"
pip install -r "$BUILD_DIR/requirements.txt" -t "$BUILD_DIR" --no-deps --upgrade

echo "Copying source code..."
cp "$SRC_DIR/main.py" "$BUILD_DIR/"
cp -r "$SRC_DIR/models" "$BUILD_DIR/"

rm -f "$BUILD_DIR/requirements.txt"

echo "Creating zip file..."

(cd "$BUILD_DIR" && zip -r9 "$ZIP_PATH" .)

echo "Lambda package created: $ZIP_PATH"
echo "Package size: $(du -h "$ZIP_PATH" | cut -f1)"
echo ""
echo "Zip file contents:"
unzip -l "$ZIP_PATH" | head -30
echo ""
echo "Verifying package structure..."
unzip -l "$ZIP_PATH" | grep -E "(main\.py|models/|pydantic|httpx|structlog)" | head -10
