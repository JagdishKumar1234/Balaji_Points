# Build Release Guide - build_release.sh

## Overview

The `build_release.sh` script automates the entire release build process for the Balaji Points app:

1. ✅ Increments version number in `pubspec.yaml`
2. ✅ Cleans build directory
3. ✅ Builds release APK (universal)
4. ✅ Builds release AAB (App Bundle for Play Store)
5. ✅ Generates comprehensive build report
6. ✅ Commits changes to git

---

## Quick Start

### Option 1: Make Executable & Run
```bash
cd /Users/jagdishkumar/Documents/Development/ReactNative/Project/BalajiPoints/balaji_points

# Make executable (first time only)
chmod +x build_release.sh

# Run the script
./build_release.sh
```

### Option 2: Run with Bash
```bash
bash build_release.sh
```

### Option 3: Run from Any Directory
```bash
cd ~/anywhere
/Users/jagdishkumar/Documents/Development/ReactNative/Project/BalajiPoints/balaji_points/build_release.sh
```

---

## What Happens

### Step 1: Version Increment
```
Current version: 1.0.17+26
New version:     1.0.17+27
✓ Updated pubspec.yaml
```

### Step 2: Clean Build
```
✓ Removes old build artifacts
✓ Clears Flutter cache
✓ Resets build state
```

### Step 3: Build APK
```
✓ Compiles Kotlin/Java
✓ Processes resources
✓ Tree-shakes unused icons
✓ Minifies code
✓ Signs with release key
Output: build/app/outputs/flutter-apk/app-release.apk (38 MB)
```

### Step 4: Build AAB
```
✓ Creates App Bundle (optimized for Play Store)
✓ Supports dynamic feature delivery
✓ Smaller download size
✓ Signs with release key
Output: build/app/outputs/bundle/release/app-release.aab (15-20 MB)
```

### Step 5: Generate Report
```
✓ Creates BUILD_REPORT.txt
✓ Includes version, file sizes, paths
✓ Provides installation instructions
✓ Lists features included
✓ Shows next steps
```

### Step 6: Commit
```
✓ Stages pubspec.yaml changes
✓ Commits with version in message
✓ Ready for tag/push
```

---

## Output Files

After running the script, you'll have:

| File | Location | Size | Purpose |
|------|----------|------|---------|
| **APK** | `build/app/outputs/flutter-apk/app-release.apk` | 38 MB | Direct installation on devices |
| **AAB** | `build/app/outputs/bundle/release/app-release.aab` | 15-20 MB | Upload to Google Play Store |
| **Report** | `BUILD_REPORT.txt` | ~3 KB | Documentation of build |

---

## Usage Examples

### Example 1: Simple Release Build
```bash
./build_release.sh
# Follow prompts
# Answer 'y' when asked to continue
```

**Output:**
```
================================
BALAJI POINTS - RELEASE BUILD
================================
This script will:
1. Increment version in pubspec.yaml
2. Clean build directory
3. Build release APK
4. Build release AAB
5. Generate build report
6. Commit changes

Continue? (y/n) y

================================
Updating Version
================================
⚠ Current version: 1.0.17+26
✓ New version: 1.0.17+27
✓ Version updated successfully

[... building ...]

================================
BUILD COMPLETE ✓
================================
✓ All artifacts ready for distribution!
✓ APK:  build/app/outputs/flutter-apk/app-release.apk
✓ AAB:  build/app/outputs/bundle/release/app-release.aab
✓ Report: BUILD_REPORT.txt
```

### Example 2: Run Without Confirmation (for CI/CD)
```bash
# Add auto-yes flag
echo "y" | ./build_release.sh
```

### Example 3: Cancel Build
```bash
./build_release.sh
# When prompted: Continue? (y/n) n
# Output:
# ✗ Build cancelled
```

---

## Version Numbering

### Format: `X.Y.Z+B`
- **X** = Major version (app features)
- **Y** = Minor version (minor features)
- **Z** = Patch version (bug fixes)
- **B** = Build number (incremented each release)

### Examples:
```
1.0.0+1   (Initial release)
1.0.1+2   (Patch)
1.1.0+3   (Minor update)
2.0.0+4   (Major update)
```

### Incrementing:
The script automatically increments the **build number** (B):
```
Before: 1.0.17+26
After:  1.0.17+27
```

To manually change version:
```bash
# Edit pubspec.yaml directly
nano pubspec.yaml
# Change: version: 1.0.17+27
# To:     version: 1.1.0+27  (for minor update)
```

---

## Build Report

After each build, a `BUILD_REPORT.txt` is generated:

```
================================================================================
                    BALAJI POINTS - BUILD REPORT
================================================================================

Build Date & Time: 2026-07-11 07:30:45
App Version:       1.0.17+27

================================================================================
                              BUILD ARTIFACTS
================================================================================

1. APK (Universal)
   Location: /path/to/app-release.apk
   Size:     38 MB
   Type:     Release (Production Ready)
   Signing:  Enabled

2. AAB (App Bundle - for Play Store)
   Location: /path/to/app-release.aab
   Size:     18 MB
   Type:     Release (Optimized for Play Store)
   Signing:  Enabled

[... more details ...]
```

---

## Installation from APK

### Via ADB (Android Debug Bridge)
```bash
# Connect Android device with USB debugging enabled
adb devices  # Verify device is connected

# Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or reinstall if already installed
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Manual Installation
1. Transfer APK to Android device
2. Open file manager
3. Tap the APK file
4. Tap "Install"
5. Allow unknown sources if prompted
6. App appears on home screen

---

## Upload to Google Play Store

### Using AAB File (Recommended)

1. **Go to Google Play Console**
   - https://play.google.com/console

2. **Select your app** (Balaji Points)

3. **Go to Release section**
   - Left sidebar → Release → Production

4. **Create new release**
   - Click "Create new release"

5. **Upload AAB**
   - Drag & drop: `build/app/outputs/bundle/release/app-release.aab`
   - Or click to select file

6. **Add release notes**
   - Version: 1.0.17+27
   - Features:
     * Carpenter summary with expand/collapse
     * Bill history filtering
     * 12-hour time format
     * And more...

7. **Review & Submit**
   - Check app info
   - Review content rating
   - Click "Review release"
   - Click "Start rollout to Production"

8. **Wait for Approval**
   - Usually 1-3 hours
   - Watch for email notification

---

## Git Integration

The script automatically commits version bumps:

### Auto-commit
```bash
./build_release.sh
# After build completes:
# ✓ Committing version bump to 1.0.17+27
# ✓ Committed successfully
```

### Manual git operations after script
```bash
# Tag the release
git tag v1.0.17+27

# Push to remote
git push origin main
git push origin v1.0.17+27

# View commit
git log --oneline -1
# Output: abc1234 chore: bump version to 1.0.17+27 for release
```

---

## Troubleshooting

### Issue: "Command not found: flutter"
**Solution:**
```bash
# Check Flutter installation
flutter --version

# If not found, add to PATH
export PATH="$PATH:$HOME/flutter/bin"

# Or run from Flutter SDK directory
~/flutter/bin/flutter build apk --release
```

### Issue: "Permission denied"
**Solution:**
```bash
chmod +x build_release.sh
./build_release.sh
```

### Issue: "Build failed"
**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
./build_release.sh
```

### Issue: "Signing failed"
**Solution:**
```bash
# Check keystore configuration
cat android/key.properties

# If missing, create it (contact DevOps/Senior Dev)
# Ensure key.properties exists with signing key info
```

### Issue: "AAB build failed but APK succeeded"
**Solution:**
```bash
# This is ok - APK works
# AAB is optional but recommended for Play Store
# You can use APK for testing/Firebase distribution
```

---

## Best Practices

### ✅ DO:
- Run script on main branch only
- Ensure all tests pass before building
- Verify app works after each release
- Tag releases in git
- Document release notes
- Keep keystore backup

### ❌ DON'T:
- Run on experimental branches
- Build without testing
- Skip version increment
- Upload to Play Store directly without review
- Share signing key
- Forget to push tags

---

## Automated Release Workflow

### CI/CD Integration Example (GitHub Actions)

```yaml
name: Release Build

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Run build script
        run: |
          chmod +x build_release.sh
          echo "y" | ./build_release.sh
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJson: ${{ secrets.PLAY_STORE_KEY }}
          packageName: com.balaji.points
          releaseFiles: 'build/app/outputs/bundle/release/app-release.aab'
          track: production
```

---

## Script Functions Reference

### `print_header(message)`
Prints colored header for sections

### `print_success(message)`
Prints green success message

### `print_error(message)`
Prints red error message

### `print_warning(message)`
Prints yellow warning message

### `get_current_version()`
Extracts version from pubspec.yaml

### `increment_version()`
Calculates next version number

### `update_pubspec_version(version)`
Updates version in pubspec.yaml

### `clean_build()`
Runs flutter clean

### `build_apk()`
Builds release APK

### `build_aab()`
Builds release AAB

### `generate_report()`
Creates BUILD_REPORT.txt

### `commit_version_bump()`
Commits changes to git

---

## File Locations

```
balaji_points/
├── build_release.sh              ← Run this script
├── pubspec.yaml                  ← Version updated here
├── BUILD_REPORT.txt              ← Report generated here
├── build/
│  └── app/
│     └── outputs/
│        ├── flutter-apk/
│        │  └── app-release.apk   ← APK output
│        └── bundle/
│           └── release/
│              └── app-release.aab ← AAB output
└── android/
   └── key.properties             ← Signing key config
```

---

## Next Release

To do another release:

```bash
# Just run the script again
./build_release.sh

# It will:
# - Increment version 1.0.17+27 → 1.0.17+28
# - Build new APK and AAB
# - Generate new report
# - Commit new version
```

---

## Support

For issues or questions:

1. Check troubleshooting section
2. Review BUILD_REPORT.txt for details
3. Run `flutter doctor` to check environment
4. Contact development team

---

**Created:** 11 Jul 2026
**Script Location:** `build_release.sh`
**Status:** ✅ Ready for use
