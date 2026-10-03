#!/usr/bin/env bash
# Capture an App Store screenshot from the booted Simulator (UX-04 / D-09).
#
# Usage: bash scripts/capture-screenshot.sh <output-path.png> [iphone|ipad]
#
# Device sizes (App Store Connect rejects any other dimensions at upload):
#   iphone (default) — 6.9" slot, 1320x2868, requires the "iPhone 17 Pro Max" Simulator
#   ipad             — 13" slot,  2064x2752, requires the "iPad Pro 13-inch (M5)" Simulator
#
# Asserts the captured file's pixel dimensions match the requested slot, so a
# capture taken on the wrong Simulator fails here rather than at upload time.
# Does NOT boot, install or drive the app — reaching a screen is a human step.
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: bash scripts/capture-screenshot.sh <output-path.png> [iphone|ipad]" >&2
    exit 1
fi

OUT="$1"
DEVICE="${2:-iphone}"

case "$DEVICE" in
    iphone) EXPECTED_W=1320; EXPECTED_H=2868; SIM_NAME="iPhone 17 Pro Max" ;;
    ipad)   EXPECTED_W=2064; EXPECTED_H=2752; SIM_NAME="iPad Pro 13-inch (M5)" ;;
    *) echo "ERROR: unknown device '$DEVICE' — expected 'iphone' or 'ipad'" >&2; exit 1 ;;
esac

if ! xcrun simctl list devices booted | grep -q "(Booted)"; then
    echo "ERROR: no Simulator is booted. Boot the $SIM_NAME Simulator first:" >&2
    echo "  xcrun simctl boot \"$SIM_NAME\" && open -a Simulator" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUT")"
xcrun simctl io booted screenshot --type=png "$OUT"

W=$(sips -g pixelWidth "$OUT" | awk '/pixelWidth/{print $2}')
H=$(sips -g pixelHeight "$OUT" | awk '/pixelHeight/{print $2}')

if [ "$W" != "$EXPECTED_W" ] || [ "$H" != "$EXPECTED_H" ]; then
    echo "ERROR: captured ${W}x${H}, expected ${EXPECTED_W}x${EXPECTED_H} for the $DEVICE slot." >&2
    echo "  This size requires the \"$SIM_NAME\" Simulator in portrait orientation." >&2
    exit 1
fi

echo "Captured $OUT (${W}x${H}, $DEVICE)"
