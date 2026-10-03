#!/usr/bin/env bash
# Capture the three raw App Store screenshots by driving real gameplay with a UI test.
#
# Usage: bash scripts/capture-app-store-screenshots.sh [iphone|ipad]
#
# Boots the matching Simulator, resets the app (uninstall — the paywall shot needs a
# fresh day with 0 puzzles played), sets default Dynamic Type and a clean 9:41 status
# bar, then runs AppStoreScreenshotTests, which plays a round, finishes it, uses up
# the free daily limit and writes:
#   Marketing/screenshots/raw/[ipad/]01-gameplay.png
#   Marketing/screenshots/raw/[ipad/]02-round-end.png
#   Marketing/screenshots/raw/[ipad/]03-paywall.png
# Every output is checked against the App Store slot size before the script succeeds.
# The UI test runs under the scheme's Test action, which loads WordPuzzle.storekit,
# so the paywall shows a real price. Finals: see Marketing/screenshots/README.md.
set -euo pipefail

DEVICE="${1:-iphone}"
case "$DEVICE" in
    iphone) SIM_NAME="iPhone 17 Pro Max"; EXPECTED="1320x2868"; SUBDIR="" ;;
    ipad)   SIM_NAME="iPad Pro 13-inch (M5)"; EXPECTED="2064x2752"; SUBDIR="ipad/" ;;
    *) echo "Usage: bash scripts/capture-app-store-screenshots.sh [iphone|ipad]" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/Marketing/screenshots/raw/$SUBDIR"
BUNDLE_ID="com.patrickhoughton.WordPuzzle"
mkdir -p "$OUT_DIR"

UDID=$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | head -1 | grep -oE '[0-9A-F-]{36}')
[ -n "$UDID" ] || { echo "ERROR: no available '$SIM_NAME' Simulator" >&2; exit 1; }

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl ui "$UDID" content_size large
xcrun simctl ui "$UDID" appearance light
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --cellularBars 4 --wifiBars 3 --dataNetwork wifi

TEST_RUNNER_SCREENSHOT_DIR="$OUT_DIR" xcodebuild test \
    -project "$ROOT/WordPuzzle/WordPuzzle.xcodeproj" \
    -scheme WordPuzzle \
    -destination "platform=iOS Simulator,id=$UDID" \
    -only-testing:WordPuzzleUITests/AppStoreScreenshotTests \
    -quiet

for name in 01-gameplay 02-round-end 03-paywall; do
    f="$OUT_DIR$name.png"
    [ -f "$f" ] || { echo "ERROR: $f was not written" >&2; exit 1; }
    W=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
    H=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
    [ "${W}x${H}" = "$EXPECTED" ] || { echo "ERROR: $f is ${W}x${H}, expected $EXPECTED" >&2; exit 1; }
    echo "OK $f (${W}x${H})"
done
