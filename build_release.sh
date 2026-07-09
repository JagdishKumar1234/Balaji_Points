#!/bin/bash

# BalajiPoints Release Build Script
# Usage: ./build_release.sh
# Output: build/app/outputs/bundle/release/app-release.aab
# Version: 1.0.17 (Build 26)

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🚀 BalajiPoints Release Build v1.0.17 (Build 26)         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Clean
echo -e "${BLUE}[1/5]${NC} 🧹 Cleaning build artifacts..."
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${BLUE}[2/5]${NC} 📦 Getting dependencies..."
flutter pub get
echo -e "${GREEN}✓ Dependencies updated${NC}"
echo ""

# Step 3: Verify signing config
echo -e "${BLUE}[3/5]${NC} 🔐 Verifying signing configuration..."
if [ ! -f "android/app/key.properties" ]; then
    echo -e "${RED}✗ Error: android/app/key.properties not found!${NC}"
    echo ""
    echo "Please ensure your signing configuration is set up:"
    echo "  android/app/key.properties should contain:"
    echo "    storeFile=..."
    echo "    storePassword=..."
    echo "    keyAlias=..."
    echo "    keyPassword=..."
    exit 1
fi
echo -e "${GREEN}✓ Signing configuration found${NC}"
echo ""

# Step 4: Check for uncommitted changes
echo -e "${BLUE}[4/5]${NC} 📋 Checking git status..."
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️  Warning: Uncommitted changes found${NC}"
    echo "It's recommended to commit all changes before building"
else
    echo -e "${GREEN}✓ All changes committed${NC}"
fi
echo ""

# Step 5: Build AAB
echo -e "${BLUE}[5/5]${NC} 🔨 Building Android App Bundle (Release)..."
echo "This may take 2-5 minutes..."
echo ""

flutter build appbundle \
    --release \
    --target-platform=android-arm64 \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

echo ""
echo ""

# Check if build succeeded
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo -e "║${GREEN}         ✅ BUILD SUCCESSFUL! v1.0.17 (26)${NC}                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Show file info
    echo -e "${GREEN}📦 Output File:${NC}"
    ls -lh build/app/outputs/bundle/release/app-release.aab
    echo ""

    # Calculate checksum
    echo -e "${GREEN}🔐 SHA256:${NC}"
    shasum -a 256 build/app/outputs/bundle/release/app-release.aab
    echo ""

    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "  1. Go to Google Play Console"
    echo "  2. Select BalajiPoints app"
    echo "  3. Go to Release → Production"
    echo "  4. Click 'Create new release'"
    echo "  5. Upload: build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "  📝 Release notes for v1.0.17:"
    echo "  • Bill form enhancements - mandatory site name field"
    echo "  • Duplicate bill prevention (frontend + backend validation)"
    echo "  • 5-layer validation architecture"
    echo "  • Enhanced admin display with site name context"
    echo "  • Comprehensive logging for monitoring"
    echo ""

    echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
    echo "  • Version: 1.0.17 (Build Code: 26)"
    echo "  • Test on real device first before uploading to production"
    echo "  • Save SHA256 hash for verification"
    echo "  • Enable on Play Store when ready"
    echo ""

else
    echo -e "${RED}❌ BUILD FAILED!${NC}"
    echo ""
    echo "Check the error messages above for details."
    echo "Common issues:"
    echo "  • Missing or invalid signing configuration"
    echo "  • Outdated dependencies (run flutter pub get)"
    echo "  • Compilation errors (check your code)"
    exit 1
fi
