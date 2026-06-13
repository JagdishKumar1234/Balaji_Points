#!/bin/bash

# BalajiPoints Release Build Script
# Usage: ./build_release.sh
# Output: build/app/outputs/bundle/release/app-release.aab

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🚀 BalajiPoints Release Build v1.0.15                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Clean
echo -e "${BLUE}[1/4]${NC} 🧹 Cleaning build artifacts..."
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${BLUE}[2/4]${NC} 📦 Getting dependencies..."
flutter pub get
echo -e "${GREEN}✓ Dependencies updated${NC}"
echo ""

# Step 3: Verify signing config
echo -e "${BLUE}[3/4]${NC} 🔐 Verifying signing configuration..."
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

# Step 4: Build AAB
echo -e "${BLUE}[4/4]${NC} 🔨 Building Android App Bundle (Release)..."
echo "This may take a few minutes..."
echo ""

flutter build appbundle --release

echo ""
echo ""

# Check if build succeeded
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo -e "║${GREEN}         ✅ BUILD SUCCESSFUL!${NC}                               ║"
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
    echo "  Release notes for v1.0.15:"
    echo "  • Fixed decimal points display in bill approval"
    echo "  • Fixed pending bills list formatting"
    echo "  • Refactored users list into modular widgets"
    echo "  • Added clean logging configuration"
    echo "  • Improved search with keyboard handling"
    echo ""

    echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
    echo "  • Ensure version code (23) is higher than previous (22)"
    echo "  • Test on real device first before uploading to production"
    echo "  • Save SHA256 hash for verification"
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
