#!/usr/bin/env bash
# Build the app and install + launch it on a paired physical iPhone (Wi-Fi or cable).
#
# Usage: bash scripts/install-on-device.sh [Debug|Release] [device-udid]
#
# Defaults to the Debug configuration and the first paired physical iOS device
# devicectl reports (an already-connected one first; an idle one is woken on
# demand). Over Wi-Fi the phone must be unlocked, on the same network as this
# Mac, and previously paired with Xcode. In-app purchases on a
# directly installed build use the App Store sandbox (the local .storekit config
# only applies when launching from Xcode).
set -euo pipefail

CONFIG="${1:-Debug}"
UDID="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.patrickhoughton.WordPuzzle"
DERIVED="${TMPDIR:-/tmp}/wordpuzzle-device-build"

if [ -z "$UDID" ]; then
    JSON="$(mktemp)"
    xcrun devicectl list devices --json-output "$JSON" >/dev/null
    UDID=$(python3 - "$JSON" <<'EOF'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
# Any paired physical iOS device qualifies: an idle Wi-Fi phone reports tunnelState
# "disconnected" until something talks to it, and devicectl/xcodebuild open the tunnel
# on demand. Prefer one whose tunnel is already up, then iPhones over iPads.
paired = [d for d in devices
          if d.get("hardwareProperties", {}).get("reality") == "physical"
          and d.get("hardwareProperties", {}).get("platform") == "iOS"
          and d.get("connectionProperties", {}).get("pairingState") == "paired"]
paired.sort(key=lambda d: (d["connectionProperties"].get("tunnelState") != "connected",
                           d["hardwareProperties"].get("deviceType") != "iPhone"))
if paired:
    print(paired[0]["hardwareProperties"]["udid"])
EOF
)
    rm -f "$JSON"
fi
[ -n "$UDID" ] || { echo "ERROR: no paired iPhone found (pair it once in Xcode > Devices and Simulators)" >&2; exit 1; }

echo "Building $CONFIG for $UDID..."
xcodebuild build \
    -project "$ROOT/WordPuzzle/WordPuzzle.xcodeproj" \
    -scheme WordPuzzle \
    -configuration "$CONFIG" \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    -allowProvisioningUpdates \
    -quiet

APP="$DERIVED/Build/Products/$CONFIG-iphoneos/WordPuzzle.app"
xcrun devicectl device install app --device "$UDID" "$APP" >/dev/null
xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" >/dev/null
echo "Installed and launched $CONFIG build on $UDID"
