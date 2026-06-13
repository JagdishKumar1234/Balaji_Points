.PHONY: help run run-clean run-release run-profile run-web logs-errors logs-dart logs-all clean

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)🚀 BalajiPoints - Build Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  make run          - Flutter run with clean logs (RECOMMENDED)"
	@echo "  make run-clean    - Flutter run, filtering all noisy logs"
	@echo "  make run-release  - Flutter run in release mode"
	@echo "  make run-profile  - Flutter run in profile mode"
	@echo ""
	@echo "$(GREEN)Logging:$(NC)"
	@echo "  make logs-errors  - Show only errors and important messages"
	@echo "  make logs-dart    - Show only Dart/Flutter logs"
	@echo "  make logs-all     - Show all logs (unfiltered)"
	@echo ""
	@echo "$(GREEN)Maintenance:$(NC)"
	@echo "  make clean        - Clean build files"
	@echo "  make help         - Show this help message"

# Main run commands
run: run-clean

run-clean:
	@echo "$(BLUE)🧹 Running Flutter with clean logs...$(NC)"
	@flutter run 2>&1 | grep -vE \
		"W/m\.balaji\.points|W/FlagStore|W/FlagRegistrar|E/GoogleApiManager|D/nativeloader|D/ApplicationLoaders|D/WindowOnBackDispatcher|D/WindowLayoutComponentImpl|D/VRI|W/UiContextUtils|W/HWUI|V/NativeCrypto|hiddenapi|Verification of|Suspending all|Background.*GC|Skipped.*frames" || true

run-release:
	@echo "$(YELLOW)⚡ Running Flutter in RELEASE mode...$(NC)"
	@flutter run --release 2>&1 | grep -vE \
		"W/m\.balaji\.points|W/FlagStore|W/FlagRegistrar|E/GoogleApiManager|hiddenapi" || true

run-profile:
	@echo "$(YELLOW)📊 Running Flutter in PROFILE mode...$(NC)"
	@flutter run --profile 2>&1 | grep -vE \
		"W/m\.balaji\.points|W/FlagStore|W/FlagRegistrar|hiddenapi" || true

# Logging commands
logs-errors:
	@echo "$(RED)❌ Showing only errors and important messages...$(NC)"
	@flutter run 2>&1 | grep -E "^E/|^I/flutter|Exception|Error|FAILED|✗" || true

logs-dart:
	@echo "$(BLUE)📱 Showing only Dart/Flutter logs...$(NC)"
	@flutter run 2>&1 | grep "^I/flutter" || true

logs-all:
	@echo "$(YELLOW)📋 Showing ALL logs (unfiltered)...$(NC)"
	@flutter run

# Maintenance
clean:
	@echo "$(YELLOW)🧹 Cleaning build files...$(NC)"
	@flutter clean
	@echo "$(GREEN)✓ Clean complete$(NC)"

.DEFAULT_GOAL := help
