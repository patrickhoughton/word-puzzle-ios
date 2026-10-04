---
phase: 09-player-stats-screen
plan: 03
subsystem: persistence
tags: [swiftdata, stats, streak]
requires: [09-01, 09-02]
provides: [PersistenceStore.playerStats(now:), longestStreak, averageScore, averageWordsPerGame, bestRank, totalPangramsFound, totalSweeps, hasFinishedRoundToday]
affects: [GameView stats wiring (later plans)]
key-files:
  modified: [WordPuzzle/WordPuzzle/Services/PersistenceStore.swift]
  created: [WordPuzzle/WordPuzzleTests/PersistenceStatsTests.swift]
requirements-completed: [P9-B]
completed: 2026-10-04
---

# Phase 9 Plan 03: PersistenceStore stat queries Summary

New read-time stat queries plus a `playerStats(now:)` aggregator on PersistenceStore, with the frozen Phase 2 API untouched.

- longestStreak is DST-safe (`byAdding: .day`) and runs over full history. playerStats takes `max(longest, current)`.
- Averages are rounded to whole numbers and are nil when there are no games.
- bestRank ignores nil rows. Pangram and sweep totals treat nil as 0 / not a sweep.
- streakAtRisk is true only when currentStreak > 0 and no GameRecord exists today.
- 13 new tests cover DST (NY spring/fall), same-day, midnight, rounding, nil rows and the aggregator states. The full WordPuzzleTests suite passes (178 tests).

## Deviations from Plan
- Both tasks were committed together in one commit (9ce9b33) because they edit the same two files.
- Tests ran on the iPhone 17e simulator, as instructed, instead of iPhone 17 Pro.

## Known Stubs
None.

## Self-Check: PASSED
