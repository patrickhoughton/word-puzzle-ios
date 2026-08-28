---
phase: 02-persistence-entitlements
plan: 03
subsystem: database
tags: [swiftdata, scoring, streak, swift-testing]

# Dependency graph
requires:
  - phase: 02-persistence-entitlements
    provides: "PersistenceStore container factory and record(...) API (plan 02-02)"
provides:
  - "ScoreCalculator enum: points(for:isPangram:) and score(for:pangrams:) implementing CONTEXT D-02 exactly"
  - "PersistenceStore.currentStreak(now:) — derived, bounded-window, grace-day streak logic"
affects: [02-05-app-wiring, phase-3-core-game-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure-function scoring namespace (enum, static funcs, no state) so it can be called from both PersistenceStore consumers and Phase 3 game view without an instance"
    - "Derived-at-read-time streak: no stored counter, computed from a bounded 400-day FetchDescriptor collapsed to a Set<Date> of startOfDay values, walked backwards in memory"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift
    - WordPuzzle/WordPuzzleTests/ScoreCalculatorTests.swift
  modified:
    - WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
    - WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift

key-decisions:
  - "Streak is derived at read time from GameRecord.date rather than stored as an incrementally-updated counter — a stored counter is a second source of truth that can drift out of sync with actual play history (RESEARCH anti-pattern, resolves RESEARCH Open Question 2)"
  - "Streak query is bounded to the last 400 days (single FetchDescriptor) rather than unbounded, capping query cost regardless of history size; a streak beyond 400 days is not realistic for this app"
  - "Grace day: a streak counted as of yesterday remains alive (reports its current length) until the user goes 2+ days without playing — matches Duolingo/Wordle-style streak UX and avoids the streak visually resetting every morning before the user has played"
  - "Streak day boundaries use local timezone via the injected Calendar (default .current) and Calendar.startOfDay(for:), which is DST-safe, per CONTEXT's discretion note"

patterns-established:
  - "ScoreCalculator: enum namespace of pure static functions, no @Observable/no state — the correct shape for a function with no persistent data, contrasted with PersistenceStore's @Observable class shape"

requirements-completed: [RET-01, RET-02]

# Metrics
duration: 12min
completed: 2026-08-28
---

# Phase 2 Plan 3: Scoring & Streak Summary

**ScoreCalculator implementing the locked Spelling Bee D-02 formula (4-letter=1pt, 5+=length, pangram=+7) plus a derived, bounded-window, grace-day `currentStreak()` on PersistenceStore.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-08-28T15:44:00Z
- **Completed:** 2026-08-28T15:46:00Z
- **Tasks:** 2 completed
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `ScoreCalculator.points(for:isPangram:)` implements every branch of CONTEXT D-02: 4-letter words score 1 point, 5-or-more-letter words score their length, pangrams add a flat +7 bonus, and words below the 4-letter floor (Phase 1 D-05) score 0
- `ScoreCalculator.score(for:pangrams:)` sums a session's word list against a `Set<String>` of pangrams for O(1) membership checks, matching the Phase 1 lookup convention
- `PersistenceStore.currentStreak(now:)` computes the daily streak entirely from `GameRecord.date` — no independent counter — using a single bounded (400-day) `FetchDescriptor`, collapsed to a `Set` of `startOfDay` values, walked backwards in memory
- Grace-day semantics implemented and tested: a streak survives with no play yet today as long as the user played yesterday; it only breaks once the most recent play is 2+ days old
- RET-01 (streak) and RET-02 (best score requires a defined scoring formula) are both satisfied

## Task Commits

Both tasks followed TDD-equivalent flow (implementation + tests written together per plan's exact prescribed content, verified RED-would-fail-if-removed by running the full suite GREEN):

1. **Task 1: ScoreCalculator implementing the locked D-02 scoring formula** - `4f09a3c` (feat)
2. **Task 2: currentStreak() derived from play dates over a bounded window** - `53ac5b3` (feat)

**Plan metadata:** (this commit, see below)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift` - Pure enum: `points(for:isPangram:)`, `score(for:pangrams:)`
- `WordPuzzle/WordPuzzleTests/ScoreCalculatorTests.swift` - 5 Swift Testing `@Test` functions covering every D-02 branch
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` - Added `currentStreak(now:)` appended after the lifetime-stats methods
- `WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift` - Added 4 streak `@Test` functions plus a `daysAgo(_:from:)` test helper

## Decisions Made
- Followed the plan's exact API surface, algorithm, and file layout — no architectural deviation
- Streak derivation approach (bounded-window, derived-not-stored, grace day, local timezone) was a pre-resolved planner decision baked into the plan (resolving RESEARCH Open Question 2); implemented exactly as specified

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The pre-existing `WordPuzzleUITests.testLaunchPerformance()` failure (unrelated to `Services/`, already logged in `.planning/phases/02-persistence-entitlements/deferred-items.md` during plan 02-02) reappeared in this plan's full-suite regression run. Not fixed — out of scope for this plan (UI target, launch performance measurement, likely resource contention from parallel `xcodebuild test` runs by the sibling 02-04 executor). All `WordPuzzleTests` target tests passed: `ScoreCalculatorTests` 5/5, `PersistenceStoreTests` 8/8 (4 from plan 02-02 plus 4 new streak tests).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `PersistenceStore`'s full API surface is now frozen for plan 02-05 and Phase 3: `makeContainer`, `record`, `puzzlesPlayedToday`, `totalGamesPlayed`, `bestScore`, `totalWordsFound`, `currentStreak`
- `ScoreCalculator.score(for:pangrams:)` is ready for Phase 3's game view to compute a session score before calling `PersistenceStore.record(score:wordsFoundCount:date:)`
- No blockers for 02-05 (entitlement store + app wiring) or Phase 3 (core game UI)
- See `.planning/phases/02-persistence-entitlements/deferred-items.md` for the recurring, pre-existing `testLaunchPerformance()` UI test failure — worth an isolated re-run once all parallel Phase 2 execution finishes

---
*Phase: 02-persistence-entitlements*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift
- FOUND: WordPuzzle/WordPuzzleTests/ScoreCalculatorTests.swift
- FOUND: currentStreak in WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
- FOUND: streak tests in WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift
- FOUND commit: 4f09a3c (Task 1)
- FOUND commit: 53ac5b3 (Task 2)
