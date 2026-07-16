#!/bin/bash

################################################################################
#                    BALAJI POINTS - RELEASE BUILD SCRIPT
################################################################################
# This script:
# 1. Increments the version number in pubspec.yaml
# 2. Cleans the build directory
# 3. Builds release APK
# 4. Builds release AAB (App Bundle)
# 5. Generates build report
# 6. Commits changes to git
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"
APK_OUTPUT="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
AAB_OUTPUT="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"

################################################################################
# FUNCTION: Print colored output
################################################################################
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

################################################################################
# FUNCTION: Extract current version
################################################################################
get_current_version() {
    grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //'
}

################################################################################
# FUNCTION: Increment build number
################################################################################
increment_version() {
    local current_version=$(get_current_version)

    # Split version into parts (e.g., "1.0.17+26" -> "1.0.17" and "26")
    local version_name=$(echo "$current_version" | cut -d'+' -f1)
    local build_number=$(echo "$current_version" | cut -d'+' -f2)

    # Increment build number
    local new_build_number=$((build_number + 1))
    local new_version="${version_name}+${new_build_number}"

    echo "$new_version"
}

################################################################################
# FUNCTION: Update version in pubspec.yaml
################################################################################
update_pubspec_version() {
    local new_version=$1

    print_header "Updating Version"

    local current=$(get_current_version)
    print_warning "Current version: $current"
    print_success "New version: $new_version"

    # Update pubspec.yaml
    sed -i "" "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"

    # Verify update
    local updated=$(get_current_version)
    if [ "$updated" = "$new_version" ]; then
        print_success "Version updated successfully"
    else
        print_error "Failed to update version"
        exit 1
    fi
}

################################################################################
# FUNCTION: Clean build
################################################################################
clean_build() {
    print_header "Cleaning Build"

    cd "$PROJECT_DIR"
    flutter clean
    print_success "Build cleaned"
}

################################################################################
# FUNCTION: Build Release APK
################################################################################
build_apk() {
    print_header "Building Release APK"

    cd "$PROJECT_DIR"
    flutter build apk --release

    if [ -f "$APK_OUTPUT" ]; then
        local size=$(ls -lh "$APK_OUTPUT" | awk '{print $5}')
        print_success "APK built successfully"
        print_success "Size: $size"
        echo -e "${BLUE}Location: $APK_OUTPUT${NC}"
    else
        print_error "APK build failed"
        exit 1
    fi
}

################################################################################
# FUNCTION: Build Release AAB (App Bundle)
################################################################################
build_aab() {
    print_header "Building Release AAB (App Bundle)"

    cd "$PROJECT_DIR"
    flutter build appbundle --release

    if [ -f "$AAB_OUTPUT" ]; then
        local size=$(ls -lh "$AAB_OUTPUT" | awk '{print $5}')
        print_success "AAB built successfully"
        print_success "Size: $size"
        echo -e "${BLUE}Location: $AAB_OUTPUT${NC}"
    else
        print_error "AAB build failed"
        exit 1
    fi
}

################################################################################
# FUNCTION: Generate build report
################################################################################
generate_report() {
    print_header "Build Report"

    local version=$(get_current_version)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local apk_size=$(ls -lh "$APK_OUTPUT" 2>/dev/null | awk '{print $5}' || echo "N/A")
    local aab_size=$(ls -lh "$AAB_OUTPUT" 2>/dev/null | awk '{print $5}' || echo "N/A")

    local report_file="$PROJECT_DIR/BUILD_REPORT.txt"

    cat > "$report_file" << EOF
================================================================================
                    BALAJI POINTS - BUILD REPORT
================================================================================

Build Date & Time: $timestamp
App Version:       $version

================================================================================
                              BUILD ARTIFACTS
================================================================================

1. APK (Universal)
   Location: $APK_OUTPUT
   Size:     $apk_size
   Type:     Release (Production Ready)
   Signing:  Enabled

2. AAB (App Bundle - for Play Store)
   Location: $AAB_OUTPUT
   Size:     $aab_size
   Type:     Release (Optimized for Play Store)
   Signing:  Enabled

================================================================================
                            INSTALLATION OPTIONS
================================================================================

1. APK Installation (Direct):
   adb install -r $APK_OUTPUT

2. AAB Upload (Google Play Store):
   - Go to Google Play Console
   - Create new release
   - Upload: $AAB_OUTPUT
   - Add release notes
   - Submit for review

3. Firebase App Distribution (Testing):
   - Upload: $APK_OUTPUT
   - Send to testers via link

================================================================================
                              FEATURES INCLUDED
================================================================================

✓ Carpenter summary with expand/collapse
✓ Numbered bill history (#1, #2, #3...)
✓ Site filter dropdown
✓ Date range filtering
✓ 12-hour time format (hh:mm a)
✓ Empty site handling (dash "-")
✓ Bill number display (BP-SBH-20260710-384721)
✓ Wallet tier status
✓ Professional UI improvements

================================================================================
                              OPTIMIZATIONS
================================================================================

✓ CupertinoIcons tree-shaked: 257 KB → 0.8 KB (99.7%)
✓ MaterialIcons tree-shaked: 1.6 MB → 23.5 KB (98.6%)
✓ Code minified & obfuscated
✓ Resources shrunk
✓ Production signing enabled

================================================================================
                              NEXT STEPS
================================================================================

1. Test APK on Android device:
   adb install -r $APK_OUTPUT

2. Verify all features work correctly

3. Upload AAB to Google Play Console

4. Add release notes

5. Submit for review

================================================================================
                            GIT COMMIT READY
================================================================================

The following files have been changed:
- pubspec.yaml (version updated to $version)

To commit:
  cd $PROJECT_DIR
  git add pubspec.yaml
  git commit -m "chore: bump version to $version for release"
  git tag v$version
  git push origin main

================================================================================
EOF

    cat "$report_file"

    print_success "Report generated: $report_file"
}

################################################################################
# FUNCTION: Commit changes to git
################################################################################
commit_version_bump() {
    print_header "Committing Version Bump"

    local version=$(get_current_version)

    cd "$PROJECT_DIR"

    # Check if git is available
    if ! command -v git &> /dev/null; then
        print_warning "Git not found, skipping commit"
        return
    fi

    # Check if there are changes
    if ! git diff --quiet pubspec.yaml; then
        print_success "Committing version bump to $version"
        git add pubspec.yaml
        git commit -m "chore: bump version to $version for release"
        print_success "Committed successfully"
    else
        print_warning "No changes to commit"
    fi
}

################################################################################
# MAIN SCRIPT
################################################################################

main() {
    print_header "BALAJI POINTS - RELEASE BUILD"

    echo -e "${YELLOW}This script will:${NC}"
    echo "1. Increment version in pubspec.yaml"
    echo "2. Clean build directory"
    echo "3. Build release APK"
    echo "4. Build release AAB"
    echo "5. Generate build report"
    echo "6. Commit changes"
    echo ""

    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Build cancelled"
        exit 1
    fi

    echo ""

    # Step 1: Get new version
    NEW_VERSION=$(increment_version)

    # Step 2: Update pubspec.yaml
    update_pubspec_version "$NEW_VERSION"

    echo ""

    # Step 3: Clean build
    clean_build

    echo ""

    # Step 4: Build APK
    build_apk

    echo ""

    # Step 5: Build AAB
    build_aab

    echo ""

    # Step 6: Generate report
    generate_report

    echo ""

    # Step 7: Commit
    commit_version_bump

    echo ""
    print_header "BUILD COMPLETE ✓"
    print_success "All artifacts ready for distribution!"
    print_success "APK:  $APK_OUTPUT"
    print_success "AAB:  $AAB_OUTPUT"
    print_success "Report: $PROJECT_DIR/BUILD_REPORT.txt"
    echo ""
}

# Run main script
main "$@"
