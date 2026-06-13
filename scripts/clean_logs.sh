#!/bin/bash

# Clean Flutter Logs Script
# Filters out noisy logs and shows only informative messages
# Usage: ./scripts/clean_logs.sh

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Flutter Clean Logs Runner${NC}"
echo "Filtering out verbose/debug logs, showing only important messages..."
echo ""

# Run flutter with filtered output
flutter run "$@" 2>&1 | grep -vE \
  "^W/m\.balaji\.points|
^W/FlagStore|
^W/FlagRegistrar|
^E/GoogleApiManager|
^D/nativeloader|
^D/ApplicationLoaders|
^D/WindowOnBackDispatcher|
^D/WindowLayoutComponentImpl|
^D/VRI\[MainActivity\]|
^D/CompatChangeReporter|
^D/WindowExtensionsImpl|
^D/InsetsController|
^D/compat|
^W/UiContextUtils|
^W/HWUI|
^W/Firestore|
^W/ProviderInstaller|
^V/NativeCrypto|
^I/ImeTracker|
^I/Choreographer|
^I/Surface|
^I/m\.balaji\.points|
^I/SQLiteConnection|
^I/Compiler|
^I/HWUI|
^I/FLT|
^I/DynamiteModule|
^I/DynamiteModule|
hiddenapi|
Verification of|
Suspending all|
Loading /data|
Returning zygote|
Configuring clns|
Long db operation|
Background.*GC|
Skipped.*frames"
