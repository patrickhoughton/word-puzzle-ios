#!/usr/bin/env bash
#
# compliance-guards.sh
#
# Re-checks every Phase 5 SOURCE and CONFIG-level compliance invariant in one
# command. This script checks source and config invariants ONLY -- it does not
# and cannot verify runtime behaviour. Airplane Mode behaviour (UX-01), AX5
# Dynamic Type rendering (UX-03), and audible SFX (UX-02) are manual checks
# owned by plan 05-06. This script exists so the source-level half of those
# invariants (no networking APIs, the encryption declaration, the device
# family decision, and the Font.system(size:) exception list) can never drift
# silently between now and submission.
#
# Usage: bash scripts/compliance-guards.sh
# Run from the repo root. Exits 0 if every guard passes, non-zero otherwise.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

PBXPROJ="WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj"
APP_SRC="WordPuzzle/WordPuzzle"

FAILURES=0

# --- Guard 1: no networking APIs anywhere in the app target (UX-01) --------
#
# The app must work fully offline. StoreKit's Transaction.currentEntitlements
# and AppStore.sync() (used in Services/EntitlementStore.swift) read/refresh
# StoreKit's local transaction cache and are NOT network APIs themselves, so
# they are not part of this grep pattern and need no exemption.
NETWORK_HITS=$(grep -rnE "URLSession|URLRequest|NSURLConnection|CFNetwork|NWConnection|NWPathMonitor" "$APP_SRC" --include="*.swift" || true)
if [ -n "$NETWORK_HITS" ]; then
  echo "FAIL: Guard 1 (no networking APIs)"
  echo "UX-01 regression: the app must have zero network dependencies. Found networking API usage above."
  echo "$NETWORK_HITS"
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: Guard 1 (no networking APIs) -- zero matches for URLSession/URLRequest/NSURLConnection/CFNetwork/NWConnection/NWPathMonitor"
fi

# --- Guard 2: encryption export compliance declared (UX-05) ----------------
#
# There is no physical Info.plist in this project (GENERATE_INFOPLIST_FILE =
# YES synthesizes it from INFOPLIST_KEY_* build settings) -- the key lives
# only here, in project.pbxproj, on both app-target configurations.
ENCRYPTION_COUNT=$(grep -c "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;" "$PBXPROJ" || true)
if [ "$ENCRYPTION_COUNT" != "2" ]; then
  echo "FAIL: Guard 2 (encryption export compliance)"
  echo "UX-05 regression: expected INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO; on both app-target"
  echo "configurations in $PBXPROJ (no physical Info.plist exists -- this is a build setting, not a plist"
  echo "entry). Found $ENCRYPTION_COUNT occurrence(s), expected 2."
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: Guard 2 (encryption export compliance) -- INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO; present exactly 2 times"
fi

# --- Guard 3: targeted device family is the confirmed value (UX-04 scope) --
#
# Decision id: device-family-keep-ipad (05-04, Task 1). Patrick chose to keep
# TARGETED_DEVICE_FAMILY = "1,2" (iPhone + iPad) rather than restrict to
# iPhone-only, accepting that plan 05-07 must add a 13" iPad (2064x2752)
# screenshot set and that an iPad layout smoke test is now in scope. If this
# guard ever fails, the pbxproj value drifted from that deliberate decision.
DEVICE_FAMILY_VALUE='1,2'
DEVICE_FAMILY_COUNT=$(grep -c "TARGETED_DEVICE_FAMILY = \"${DEVICE_FAMILY_VALUE}\";" "$PBXPROJ" || true)
if [ "$DEVICE_FAMILY_COUNT" != "6" ]; then
  echo "FAIL: Guard 3 (targeted device family)"
  echo "UX-04 regression: expected TARGETED_DEVICE_FAMILY = \"${DEVICE_FAMILY_VALUE}\"; to appear 6 times"
  echo "in $PBXPROJ (app target x2, WordPuzzleTests x2, WordPuzzleUITests x2), per the"
  echo "device-family-keep-ipad decision (05-04). Found $DEVICE_FAMILY_COUNT occurrence(s)."
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: Guard 3 (targeted device family) -- TARGETED_DEVICE_FAMILY = \"${DEVICE_FAMILY_VALUE}\"; present exactly 6 times (device-family-keep-ipad)"
fi

# --- Guard 4: Dynamic Type font rule (UX-03) --------------------------------
#
# HexTileView.swift is the one sanctioned exception (D-05 clamp): its letter
# glyph uses Font.system(size:) clamped to 40pt so the 70pt hexagon never
# overflows at AX1-AX5 Dynamic Type sizes. Every other view must use a
# GameTheme text-style token instead.
FONT_SYSTEM_FILES=$(grep -rl "Font.system(size:" "$APP_SRC" --include="*.swift" || true)
FONT_SYSTEM_FILE_COUNT=$(echo "$FONT_SYSTEM_FILES" | grep -c . || true)
EXPECTED_FONT_FILE="WordPuzzle/WordPuzzle/Game/Views/HexTileView.swift"
if [ "$FONT_SYSTEM_FILE_COUNT" != "1" ] || [ "$FONT_SYSTEM_FILES" != "$EXPECTED_FONT_FILE" ]; then
  echo "FAIL: Guard 4 (Dynamic Type font rule)"
  echo "UX-03 regression: Font.system(size:) never scales with Dynamic Type. Use a"
  echo "GameTheme text-style token. HexTileView is the only sanctioned exception (D-05 clamp)."
  echo "Files found using Font.system(size:):"
  echo "$FONT_SYSTEM_FILES"
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: Guard 4 (Dynamic Type font rule) -- Font.system(size:) used only in HexTileView.swift"
fi

# --- Summary -----------------------------------------------------------------
echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "COMPLIANCE GUARDS: $FAILURES failure(s)"
else
  echo "COMPLIANCE GUARDS: all guards passed"
fi

exit $((FAILURES > 0))
