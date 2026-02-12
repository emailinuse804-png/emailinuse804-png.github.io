# ============================================================================
# CursorOS - Build System
# ============================================================================
#
# Targets:
#   make iso           - Build the full CursorOS Linux desktop ISO
#   make bare-metal    - Build the original bare-metal kernel ISO
#   make clean         - Clean all build artifacts
#   make help          - Show this help
#
# The Linux ISO requires root (use: sudo make iso)
# The bare-metal kernel builds without root
# ============================================================================

.PHONY: iso bare-metal clean help

help:
	@echo ""
	@echo "  CursorOS Build System"
	@echo "  ====================="
	@echo ""
	@echo "  make iso           Build CursorOS desktop ISO (Linux-based)"
	@echo "                     Requires: sudo, ~10GB disk, ~30min"
	@echo ""
	@echo "  make bare-metal    Build bare-metal kernel ISO (educational)"
	@echo "                     Requires: nasm, gcc, grub-mkrescue"
	@echo ""
	@echo "  make clean         Remove all build artifacts"
	@echo ""

iso: build.sh
	@echo ""
	@echo "Building CursorOS Desktop ISO..."
	@echo "This requires root privileges and takes 20-40 minutes."
	@echo ""
	@sudo bash build.sh

bare-metal:
	@$(MAKE) -C bare-metal

clean:
	@echo "Cleaning all build artifacts..."
	@sudo rm -rf build-distro 2>/dev/null || true
	@rm -f CursorOS-*.iso 2>/dev/null || true
	@$(MAKE) -C bare-metal clean 2>/dev/null || true
	@echo "Clean complete."
