#!/usr/bin/env bash
# Build the app and install + launch it on a paired physical iPhone (Wi-Fi or cable).
#
# Usage: bash scripts/install-on-device.sh [Debug|Release] [device-udid]
#
# Defaults to the Debug configuration and the first paired, connected physical
# device that devicectl reports. Over Wi-Fi the phone must be unlocked, on the same
# network as this Mac, and previously paired with Xcode. In-app purchases on a
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
for d in devices:
    conn = d.get("connectionProperties", {})
    if d.get("hardwareProperties", {}).get("reality") == "physical" and conn.get("pairingState") == "paired" \
            and conn.get("tunnelState") == "connected":
        print(d["hardwareProperties"]["udid"])
        break
EOF
)
    rm -f "$JSON"
fi
[ -n "$UDID" ] || { echo "ERROR: no paired, connected iPhone found (unlock it and keep it on the same Wi-Fi)" >&2; exit 1; }

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
