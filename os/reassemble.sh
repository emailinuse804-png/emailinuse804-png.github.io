#!/bin/bash
# ============================================================================
# CursorOS - ISO Reassembly Script
# ============================================================================
# Downloads were split into parts due to GitHub's 2GB file limit.
# Run this script in the same folder as the .part files to reassemble.
#
# Usage: bash reassemble.sh
# ============================================================================

echo ""
echo "  Reassembling CursorOS-3.0.0-amd64.iso..."
echo ""

# Check that all parts exist
MISSING=0
for part in CursorOS-3.0.0-amd64.iso.part00 CursorOS-3.0.0-amd64.iso.part01 CursorOS-3.0.0-amd64.iso.part02; do
    if [ ! -f "$part" ]; then
        echo "  ERROR: Missing $part"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "  Download all .part files from the GitHub Release first!"
    exit 1
fi

# Reassemble
cat CursorOS-3.0.0-amd64.iso.part00 \
    CursorOS-3.0.0-amd64.iso.part01 \
    CursorOS-3.0.0-amd64.iso.part02 \
    > CursorOS-3.0.0-amd64.iso

echo "  Reassembled: CursorOS-3.0.0-amd64.iso ($(du -h CursorOS-3.0.0-amd64.iso | cut -f1))"
echo ""

# Verify checksum if sha256sum is available
if command -v sha256sum &>/dev/null; then
    echo "  Verifying checksum..."
    EXPECTED="f632b42ac96c2aaf3d2420341668a03b2cc5c8dcc2f43f0e7f117b816d075cf4"
    ACTUAL=$(sha256sum CursorOS-3.0.0-amd64.iso | cut -d' ' -f1)
    if [ "$ACTUAL" = "$EXPECTED" ]; then
        echo "  SHA256: OK"
    else
        echo "  SHA256: MISMATCH (file may be corrupted)"
        echo "  Expected: $EXPECTED"
        echo "  Got:      $ACTUAL"
        exit 1
    fi
fi

echo ""
echo "  Done! You can now:"
echo "    - Run in QEMU:  qemu-system-x86_64 -cdrom CursorOS-3.0.0-amd64.iso -m 4G -enable-kvm -smp 2"
echo "    - Write to USB:  sudo dd if=CursorOS-3.0.0-amd64.iso of=/dev/sdX bs=4M status=progress"
echo ""
echo "  You can delete the .part files now."
echo ""
