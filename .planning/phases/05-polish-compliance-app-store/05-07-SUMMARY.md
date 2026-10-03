---
phase: 05-polish-compliance-app-store
plan: 07
subsystem: marketing
tags: [app-store, screenshots, xcuitest, imagerenderer, simctl]

# Dependency graph
requires:
  - phase: 05-03
    provides: Shipping app icon and the ImageRenderer script pattern (GenerateAppIcon.swift)
  - phase: 05-04
    provides: device-family-keep-ipad decision (iPad 13" screenshot set in scope)
  - phase: 05-05
    provides: Settings gear in the game screen chrome
provides:
  - Six upload-ready captioned screenshots (3x iPhone 6.9" 1320x2868, 3x iPad 13" 2064x2752) under Marketing/screenshots/final/
  - Fully automated, reproducible capture pipeline (UI test + wrapper script), no human gameplay required
  - DEBUG-only -ScreenshotPuzzle launch argument for pinning rounds to a known puzzle
affects: [05-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "App Store screenshots are driven by XCUITest (AppStoreScreenshotTests), skipped unless SCREENSHOT_DIR is set, so normal test runs are unaffected"
    - "DEBUG-only launch arguments (read via UserDefaults argument domain) as test seams for staging app state; guarded by #if DEBUG and verified absent from the Release binary"

key-files:
  created:
    - scripts/capture-screenshot.sh
    - scripts/FrameScreenshot.swift
    - scripts/capture-app-store-screenshots.sh
    - WordPuzzle/WordPuzzleUITests/AppStoreScreenshotTests.swift
    - Marketing/screenshots/README.md
    - Marketing/screenshots/final/01-gameplay.png
    - Marketing/screenshots/final/02-round-end.png
    - Marketing/screenshots/final/03-paywall.png
    - Marketing/screenshots/final/ipad/01-gameplay.png
    - Marketing/screenshots/final/ipad/02-round-end.png
    - Marketing/screenshots/final/ipad/03-paywall.png
  modified:
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzle/PuzzleEngine/PuzzleGenerator.swift

key-decisions:
  - "Automated capture via XCUITest instead of the plan's human-plays/Claude-captures checkpoint -- Patrick asked Claude to drive it; the UI test runs under the scheme's Test action, which loads WordPuzzle.storekit, so the paywall shows a real $2.99"
  - "Staged puzzle HARMONY / center R (56 words, one everyday pangram): the first random-puzzle capture landed on an X-center puzzle showing SEXI/sexes/sexing -- unacceptable marketing content, so the puzzle is now pinned via a DEBUG-only -ScreenshotPuzzle launch argument"
  - "Test submits a curated 12-word list (including mammary/moron so they never appear in the round-end missed list) and leaves HARMO assembled, hinting at the pangram"
  - "FrameScreenshot sizes the canvas from the raw capture, and uses a 0.03 width-relative corner radius on iPad (0.07 on iPhone) -- the iPhone ratio clipped the iPad status bar"

patterns-established:
  - "Screenshot refresh = bash scripts/capture-app-store-screenshots.sh {iphone,ipad} then the README's compositor loop"

requirements-completed: [UX-04]

# Metrics
duration: ~60min
completed: 2026-10-03
---

# Phase 05 Plan 07: App Store Screenshots Summary

**Six captioned App Store screenshots (iPhone 6.9" + iPad 13") of real gameplay, generated end-to-end by a UI test on a staged HARMONY puzzle**

## Accomplishments

- `Marketing/screenshots/final/` — 01-gameplay, 02-round-end, 03-paywall at **1320x2868** (iPhone 17 Pro Max)
- `Marketing/screenshots/final/ipad/` — same three at **2064x2752** (iPad Pro 13-inch (M5)); required because 05-04 chose `device-family-keep-ipad`
- Frozen 05-UI-SPEC taglines rendered verbatim in #F5B800 gold; tagline 3 shows `$2.99` (verified visually)
- Round-end shot shows the **harmony ✓ Pangram** badge fully in view; paywall shows a real `$2.99`, not a dash
- All captures at default Dynamic Type, light mode, 9:41 status bar

## Deviations from Plan

1. **[User request] Task 2 automated instead of a human checkpoint.** Patrick asked Claude to drive the captures. Added `AppStoreScreenshotTests` + `scripts/capture-app-store-screenshots.sh`; the plan's `capture-screenshot.sh` is still provided for manual one-off captures.
2. **[Rule 2 – content quality] Staged puzzle.** Random puzzles can surface crude-adjacent words; added DEBUG-only `stagedPuzzle(spec:from:)` + `-ScreenshotPuzzle` hook. Release build verified: 0 occurrences of `ScreenshotPuzzle` in the binary.
3. **Recaptures:** (a) round-end pangram row not found — `MissedWordsView`'s LazyVStack doesn't materialise off-screen rows; test now scrolls until it exists; (b) pangram row clipped at list edge — test now settles at the bottom; (c) scroll indicator visible — wait 3s before capture; (d) iPad bezel clipped the status bar — smaller iPad corner radius.

## Issues Encountered

- **Xcode 27.0 (27A266a) replaced Simulator.app with DeviceHub.app** (`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`, bundle id `com.apple.dt.Devices`). `open -a Simulator` no longer works.
- **Xcode 27 `simctl status_bar --time` accepts only a plain string like `9:41`** — ISO dates are rejected (`NSPOSIXErrorDomain code=22`), so the iPad status bar shows the real capture date.
- **The 05-06 "gear doesn't render in the Simulator" quirk is gone** on Xcode 27 — the gear renders in all captures.
- **iPad layout is sparse** (fixed 70pt hex geometry in a 13" canvas). Screenshots honestly reflect it; an iPad layout pass is a candidate post-launch improvement.
- Full unit suite: 88 passed, 3 skipped, 1 failed — `WordListTests.testWordSetLookupIsO1` (8.0s vs 0.5s budget) on a freshly booted Simulator; passes in isolation both with these changes and on unchanged `main` → load-timing flake, not a regression.

## Self-Check: PASSED
