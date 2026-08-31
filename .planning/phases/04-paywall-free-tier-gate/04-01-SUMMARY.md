---
phase: 04-paywall-free-tier-gate
plan: 01
subsystem: database
tags: [swiftdata, persistence, storekit-adjacent, testing]

# Dependency graph
requires:
  - phase: 02-persistence-entitlements
    provides: "Frozen PersistenceStore API (makeContainer, record, puzzlesPlayedToday, totalGamesPlayed, bestScore, totalWordsFound, currentStreak) that this plan extends without breaking"
provides:
  - "RoundStartRecord insert-only SwiftData model tracking round STARTS independent of finish"
  - "puzzlesPlayedToday() now counts started rounds (D-02), decoupling the daily free-tier limit from lifetime stats"
  - "todayTotalScore(), todayTotalWordsFound(), nextResetDate() query methods for the paywall's stats block and countdown (D-07, D-06)"
affects: [04-02, 04-03, 04-04, paywall-ui, free-tier-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared private todayBounds(now:) helper returns [startOfDay, startOfNextDay) half-open interval, reused by all four day-scoped queries so the boundary can never drift between callers"
    - "Insert-only SwiftData model (RoundStartRecord) mirrors GameRecord's file style exactly (single init with default, no mutation methods) to keep two structurally distinct counters unambiguous"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Services/RoundStartRecord.swift
  modified:
    - WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
    - WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift
    - WordPuzzle/WordPuzzleTests/AppWiringTests.swift

key-decisions:
  - "puzzlesPlayedToday() is repointed at RoundStartRecord (started rounds) while totalGamesPlayed()/bestScore()/totalWordsFound()/currentStreak() remain GameRecord-based (finished rounds only) — the daily free-tier limit and lifetime stats are now two structurally different counters, per D-02"
  - "currentStreak() deliberately left unchanged (GameRecord-based) — a streak rewards actually playing, not starting and quitting; no CONTEXT instruction to change it"
  - "todayTotalScore()/todayTotalWordsFound() sum only finished rounds (GameRecord) for today, so an abandoned round contributes 0 to the paywall's stats block while still consuming a free puzzle"
  - "nextResetDate() reuses the exact same todayBounds() boundary as puzzlesPlayedToday(), preventing the paywall countdown from diverging from the daily-limit reset across DST or long sessions"

requirements-completed: [MON-01]

# Metrics
duration: ~8min
completed: 2026-08-31
---

# Phase 4 Plan 1: Round-Start Tracking & Today's-Totals Queries Summary

**Insert-only RoundStartRecord SwiftData model splits the daily free-tier limit (started rounds) from lifetime stats (finished rounds), plus three new today-scoped query methods for the paywall.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-08-31T20:22:00Z (approx)
- **Completed:** 2026-08-31T20:24:00Z (approx)
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- New `RoundStartRecord` SwiftData model, registered in both in-memory and on-disk `ModelContainer`, tracks every round start independent of whether it's finished
- `puzzlesPlayedToday()` now counts started rounds — an abandoned round still consumes one of the day's three free puzzles (D-02)
- Three new query methods (`todayTotalScore()`, `todayTotalWordsFound()`, `nextResetDate()`) give the paywall the data it needs for its stats block and countdown (D-07, D-06), all sharing a single `todayBounds()` day-boundary helper
- Full test coverage: 3 pre-existing tests updated for the new semantics, 4 new tests added, plus a production-schema smoke test proving `RoundStartRecord` is registered on-disk

## Task Commits

Each task was committed atomically:

1. **Task 1: Add RoundStartRecord model and extend PersistenceStore, updating the three existing tests broken by the semantics change** - `48db0d1` (feat)
2. **Task 2: Add test coverage for the D-02 split and the D-07 today-totals queries** - `6e1b644` (test)

**Plan metadata:** (this commit, pending)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Services/RoundStartRecord.swift` - New insert-only `@Model` tracking round starts, mirrors `GameRecord.swift`'s style
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` - Registers `RoundStartRecord` in `makeContainer`; adds `recordRoundStarted()`, repoints `puzzlesPlayedToday()` at `RoundStartRecord`, adds `todayTotalScore()`, `todayTotalWordsFound()`, `nextResetDate()`, and the shared `todayBounds()` helper
- `WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift` - Updated 3 existing tests for the new semantics; added 4 new tests covering the started-vs-finished split and today-totals queries
- `WordPuzzle/WordPuzzleTests/AppWiringTests.swift` - Extended the launch-path smoke test to exercise the 3 new query methods; added `testRoundStartRecordIsRegisteredInProductionSchema` proving the new entity is in the production (on-disk) schema

## Decisions Made
- See `key-decisions` in frontmatter. No decisions deviated from the plan's explicit instructions — all four decisions were specified by the plan itself and are recorded here for STATE.md/PROJECT.md traceability.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Both tasks' xcodebuild verification runs passed on the first attempt (8/8 tests in Task 1, 16/16 tests in Task 2 including the AppWiringTests suite).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `PersistenceStore` now exposes everything the paywall (04-02/04-03/04-04) needs: `recordRoundStarted()` for `GameViewModel.startNewRound(with:)` to call, `puzzlesPlayedToday()` for the daily-limit gate, and `todayTotalScore()`/`todayTotalWordsFound()`/`nextResetDate()` for the paywall's stats block and countdown.
- No blockers. `GameViewModel.startNewRound(with:)` itself is not yet wired to call `recordRoundStarted()` — that wiring is expected in a later 04-0X plan per the phase's task breakdown, since this plan's scope was the persistence layer only.

---
*Phase: 04-paywall-free-tier-gate*
*Completed: 2026-08-31*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Services/RoundStartRecord.swift
- FOUND: WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
- FOUND: WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift
- FOUND: WordPuzzle/WordPuzzleTests/AppWiringTests.swift
- FOUND commit: 48db0d1
- FOUND commit: 6e1b644
