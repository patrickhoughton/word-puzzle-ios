---
phase: 09-player-stats-screen
plan: 05
subsystem: ui
tags: [swiftui, stats, gameview, xcuitest]
requires: [09-03, 09-04]
provides: [GameView stats wiring: top-bar icon, top-bar sheet, round-over sheet inside cover, Settings snapshot]
key-files:
  modified: [WordPuzzle/WordPuzzle/Game/Views/GameView.swift]
  created: [WordPuzzle/WordPuzzleUITests/StatsPresentationUITests.swift]
requirements-completed: [P9-D, P9-E]
completed: 2026-10-04
---

# Phase 9 Plan 05: GameView stats wiring Summary

GameView now opens StatsView from three entry points (top-bar chart icon, round-over "Best · Streak" line, Settings row), each from a snapshot refreshed via `persistenceStore.playerStats()` at open time. The round-over sheet is attached inside the fullScreenCover content, so it presents over the cover and dismisses back to it. The paywall branch is untouched.

## Commits
- 0ae1beb feat(09-05): wire stats icon, sheets and snapshot refresh into GameView
- d51a091 test(09-05): XCUITest for stats entry points incl. sheet over round-over cover

## Verification
- WordPuzzleTests: TEST SUCCEEDED (Swift Testing: 185 tests in 21 suites passed; XCTest 7 executed, 3 skipped, 0 failures).
- StatsPresentationUITests (fresh install, iPhone 17 Pro sim): 1 test, 0 failures. This proves the sheet-over-cover case (Research Open Question 2), dismissal back to round-over, and the Settings push, all with fresh data ("Games played, 1" after one round).
- scripts/compliance-guards.sh exits 0.

## Deviations from Plan
None. The UI test passed unmodified on the first run. The top-bar button was hittable in the Simulator, so nothing is deferred to the 09-06 device check beyond its normal re-check.

## Known Stubs
None.

## Self-Check: PASSED
