---
phase: 09-player-stats-screen
plan: 06
subsystem: verification
tags: [swiftdata, migration, on-device, uat]
requires: [09-05]
provides: [on-device migration proof, Patrick's approval of the stats screen]
key-files:
  created: []
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
requirements-completed: [P9-A, P9-D, P9-E]
completed: 2026-10-04
---

# Phase 9 Plan 06: On-device verification Summary

**Real on-device history survived the schema change with zero loss. One device-only bug, stats sheets showing all 0 / —, was found, fixed, and approved.**

## Task 1: Store migration diff (Patrick's iPhone, install-over, no uninstall)

| Metric | Before (old schema) | After (Phase 9 build) |
|--------|--------------------|-----------------------|
| GameRecord rows | 45 | 45 |
| MAX(score) | 1169 | 1169 |
| SUM(wordsFoundCount) | 760 | 760 |
| MIN(date) | 809907270.884099 | 809907270.884099 |
| ZRANKRAW / ZPANGRAMSFOUND / ZHADSWEEP | absent | present |
| Rows with all new fields NULL | n/a | 45 (= every legacy row) |

- The store was copied off the device with `xcrun devicectl device copy from --domain-type appDataContainer`. The copies stay in the session scratchpad and are not committed.
- compliance-guards.sh exits 0. The full WordPuzzleTests suite passed (185 tests).

## Task 2: Human verification

- **First pass, failed:** every stat showed 0 or "—" on the device.
  - Diagnosis: a throwaway Swift Testing probe was run against copies of the real before and after stores. It returned correct stats in both cases (45 games, 1169 best, 760 words, averages 78 and 17). So the store and the queries were fine.
  - Cause: GameView set a `@State statsSnapshot` in the same tap that flipped `.sheet(isPresented:)`. On the device the sheet content captured the stale `.empty` value.
- **Fix (0bdc3bd):** removed `statsSnapshot` and `refreshStatsSnapshot()`. Every stats sheet now reads `persistenceStore.playerStats()` in its content through a computed `freshStats`, so each one is still fresh when it opens (Pitfall 4 is still satisfied).
  - After the fix: WordPuzzleTests passed (185), StatsPresentationUITests passed (fresh simulator install), and the app was reinstalled over the existing one on the device.
- **Second pass:** Patrick approved ("looks good").

## Deviations

- [Rule 1 - Bug] Stale sheet snapshot on device, described above. It was missed in the simulator, where the UI test passed with the snapshot approach.
- StatsPresentationUITests needs `xcrun simctl uninstall <sim> com.patrickhoughton.WordPuzzle` before each run. Otherwise it fails with "board never loaded".

## Self-Check: PASSED
