---
phase: 11-first-launch-tutorial
plan: 06
subsystem: tutorial
tags: [xcuitest, accessibility, verification]
requires: [11-05]
provides:
  - End-to-end tutorial UI tests (full walk, skip, replay)
  - AX5 banner layout fix for small screens
  - Player approval of the tutorial on device
affects: []
key-files:
  created:
    - WordPuzzle/WordPuzzleUITests/TutorialUITests.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/GameTheme.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
    - WordPuzzle/WordPuzzle/Game/Views/TutorialBannerView.swift
key-decisions:
  - "AX5 banner: scroll view sized to content, capped at 20% of screen height, Skip pinned below the scrolling text"
requirements-completed: [TUT-07]
duration: n/a
completed: 2026-10-04
---

# Phase 11 Plan 06: Tutorial End-to-End Verification Summary

TutorialUITests walk all 9 steps by real taps and swipes, plus skip and Settings replay; an AX5 banner collapse bug on iPhone 17e was found and fixed; the player approved the tutorial on their iPhone.

## Tasks
1. TutorialUITests (bb3d0f7): 3 tests, all pass on a clean install.
2. AX5 check on iPhone 17e and device install (2222b26): found and fixed the banner bug below; Debug build installed on the device over Wi-Fi.
3. On-device human verify: player typed "approved".

## Deviations from Plan

**1. [Rule 1 - Bug] AX5 tutorial banner collapsed and overflowed on iPhone 17e**
- **Found during:** Task 2
- **Issue:** At accessibility-extra-extra-extra-large the banner collapsed or overflowed and pushed the honeycomb.
- **Fix:** The scroll view is sized to its content, the cap is derived from UIScreen height, and the Skip link is pinned below the scrolling text. `GameTheme.tutorialBannerMaxHeightFraction` went from 0.4 to 0.2. At 0.2 the instruction text scrolls or truncates on the first screen at AX5; Skip and the honeycomb stay visible.
- **Files:** GameTheme.swift, GameView.swift, TutorialBannerView.swift
- **Commit:** 2222b26

**2. [Environment] Simulator issues**
- The simulator drifted into landscape, which made AppStoreScreenshotTests fail ("Failed to scroll to visible" on Finish Round, frame x=634). Rebooting the simulator to portrait fixed it. There were also hangs that needed reboots. Neither is an app bug.

**3. [Test ordering] Free tier**
- Stats UI tests consume the 3 free daily rounds, so TutorialUITests runs separately from StatsPresentationUITests, each on a clean install (uninstall first).

## Verification (re-run after fix 2222b26)
- TutorialUITests: 3 tests, 0 failures, TEST SUCCEEDED (clean install).
- StatsPresentationUITests + WordPuzzleUITests + LaunchTests: 7 tests, 0 failures, TEST SUCCEEDED (clean install).
- AppStoreScreenshotTests: TEST SUCCEEDED, 3 screenshots written to a temp dir (after rebooting the simulator to portrait; the first attempt failed due to landscape).
- WordPuzzleTests: TEST SUCCEEDED; Swift Testing 250 tests in 28 suites passed, plus 7 XCTest (3 skipped), 0 failures.
- scripts/compliance-guards.sh: all guards passed.
- Device: player approved on iPhone.

## Follow-up (pre-existing, not Phase 11)
At AX5 on iPhone 17e the score card clips at the top and Finish Round clips at the bottom of the screen. This is the normal game layout and predates the tutorial. Logged for a future accessibility pass.

## Known Stubs
None.

## Self-Check: PASSED
