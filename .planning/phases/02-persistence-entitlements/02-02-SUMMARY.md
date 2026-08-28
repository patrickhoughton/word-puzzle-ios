---
phase: 02-persistence-entitlements
plan: 02
subsystem: database
tags: [swiftdata, persistence, observable, fetchcount, swift-testing]

# Dependency graph
requires:
  - phase: 01-word-engine-puzzle-generation
    provides: "@Observable class convention (WordList), Swift Testing @Suite convention, PBXFileSystemSynchronizedRootGroup project mechanics"
provides:
  - "GameRecord SwiftData @Model (date, score, wordsFoundCount)"
  - "PersistenceStore @Observable service: makeContainer(inMemory:url:), record(score:wordsFoundCount:date:), puzzlesPlayedToday(now:), totalGamesPlayed(), bestScore(), totalWordsFound()"
  - "SwiftData test pattern proving on-disk persistence survives container teardown/reopen"
affects: [02-03-streak-scoring, 02-05-app-wiring, phase-3-core-game-ui, phase-4-paywall]

# Tech tracking
tech-stack:
  added: [SwiftData]
  patterns:
    - "@Observable final class service wrapping a ModelContainer/ModelContext, matching Phase 1's WordList convention"
    - "Container factory (makeContainer) taking inMemory/url params so prod (on-disk default), unit tests (in-memory), and restart-persistence tests (temp-file on-disk) share one code path"
    - "fetchCount(descriptor) for COUNT queries; sortBy + fetchLimit=1 for MAX; fetch+reduce in Swift for SUM (SwiftData has no SUM/AVG pushdown)"
    - "#Predicate captures local `let` constants (startOfDay/startOfNextDay) computed before the macro body — cannot call calendar methods inside #Predicate"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Services/GameRecord.swift
    - WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
    - WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift
  modified: []

key-decisions:
  - "PersistenceStore API frozen exactly as specified in the plan: makeContainer(inMemory:url:), record(score:wordsFoundCount:date:), puzzlesPlayedToday(now:), totalGamesPlayed(), bestScore(), totalWordsFound() — plan 02-03 and 02-05 depend on these signatures unchanged"
  - "Reworded one code comment to avoid the literal text '#Expression' (the plan's own action-block sample code included it in a comment, which then violated the plan's own acceptance criterion 'contains NO occurrence of #Expression') — explanatory content preserved, just reworded"

patterns-established:
  - "GameRecord: exactly 3 stored properties (date, score, wordsFoundCount) — CONTEXT D-01 explicitly excludes word lists/letter sets to keep the store small; future plans must not add fields without an explicit decision"
  - "PersistenceStoreTests: @MainActor @Suite struct (Testing framework), matching PuzzleGeneratorTests style but MainActor-annotated because PersistenceStore is MainActor-isolated by the app target's SWIFT_DEFAULT_ACTOR_ISOLATION setting"

requirements-completed: [RET-02]

# Metrics
duration: 12min
completed: 2026-08-28
---

# Phase 2 Plan 2: SwiftData Persistence Foundation Summary

**SwiftData `GameRecord`/`PersistenceStore` service with `fetchCount`-backed daily/lifetime stats queries, proven to survive on-disk container teardown and reopen.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-08-28T19:22:00Z
- **Completed:** 2026-08-28T19:34:00Z
- **Tasks:** 2 completed
- **Files modified:** 3 (2 created source, 1 created test)

## Accomplishments
- `GameRecord` SwiftData model persisting exactly `date`, `score`, `wordsFoundCount` (CONTEXT D-01)
- `PersistenceStore` `@Observable` service with a container factory supporting in-memory, default on-disk, and temp-file on-disk configurations from one code path
- `puzzlesPlayedToday()` counts only the current local calendar day via a `fetchCount` + `#Predicate` date-range query (SQLite COUNT pushdown, no model objects instantiated)
- Three lifetime stats — `totalGamesPlayed()` (COUNT), `bestScore()` (sort + `fetchLimit=1`, MAX pushdown), `totalWordsFound()` (fetch + `reduce`, since SwiftData has no SUM pushdown)
- Proved ROADMAP SC-1 ("persists across app restarts") with a real on-disk SQLite store: records written, container released, a NEW container reopened at the same URL, and both `puzzlesPlayedToday()` and `totalGamesPlayed()` still return correct values

## Task Commits

Each task followed TDD (RED → GREEN), with an additional RED/GREEN pair for Task 2's forward-referenced test:

1. **Task 1: GameRecord model, PersistenceStore container factory, record() and puzzlesPlayedToday()**
   - `a581bcb` test(02-02): add failing tests for PersistenceStore daily count and restart persistence (RED)
   - `a65b44c` feat(02-02): implement GameRecord model and PersistenceStore container/record/puzzlesPlayedToday (GREEN)
2. **Task 2: Lifetime stats — totalGamesPlayed, bestScore, totalWordsFound**
   - `284b9e8` test(02-02): add failing test for lifetime stats accumulation (RED)
   - `f0d14c1` feat(02-02): implement lifetime stats — totalGamesPlayed, bestScore, totalWordsFound (GREEN)

**Plan metadata:** (this commit, see below)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Services/GameRecord.swift` - SwiftData `@Model` with `date: Date`, `score: Int`, `wordsFoundCount: Int`
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` - `@Observable final class` with `makeContainer`, `record`, `puzzlesPlayedToday`, `totalGamesPlayed`, `bestScore`, `totalWordsFound`
- `WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift` - 4 Swift Testing `@Test` functions covering daily count, day-boundary exclusion, on-disk restart persistence, and lifetime stat accumulation

## Decisions Made
- Followed the plan's exact API surface and file layout — no architectural deviation
- The plan's Task 1 test file forward-references `totalGamesPlayed()` (implemented in Task 2). Per the plan's own guidance ("temporarily comment that single line while iterating"), that single assertion was commented out for Task 1's RED/GREEN cycle and uncommented as part of Task 2's RED commit, preserving genuine TDD RED/GREEN steps for both tasks without breaking the build mid-task

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reworded a comment to satisfy the plan's own acceptance criterion**
- **Found during:** Task 2 (lifetime stats implementation)
- **Issue:** The plan's `<action>` block supplied sample code for `totalWordsFound()` containing the literal text `#Expression` inside an explanatory comment. The same plan's `<verification>` and Task 2 `<acceptance_criteria>` both require `grep -q "#Expression" PersistenceStore.swift` to find nothing — a self-contradiction in the plan text.
- **Fix:** Reworded the comment to "Do not attempt an expression macro or a map/reduce inside the #Predicate macro" — same explanation, no literal `#Expression` occurrence.
- **Files modified:** `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift`
- **Verification:** `grep -q "#Expression" PersistenceStore.swift` now finds nothing; all 4 tests still pass.
- **Committed in:** `f0d14c1` (Task 2 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 bug/documentation self-contradiction)
**Impact on plan:** Cosmetic only — no functional or API surface change. No scope creep.

## Issues Encountered
- **Worktree was stale.** This worktree's git branch (`worktree-agent-a52cc91999ea25069`) was pinned at the commit where Phase 2's roadmap was created, before Phase 1 completion and the Phase 2 plan files were committed to `main`. Fast-forwarded (`git merge --ff-only main`) to pick up `.planning/phases/02-persistence-entitlements/02-02-PLAN.md` and all Phase 1 source before starting work. No local changes were lost (worktree was clean).
- **Unrelated UI test failure during full-suite regression.** `WordPuzzleUITests.testLaunchPerformance()` failed during the post-task full-suite run. This test predates this plan (created in Phase 1, commit `fc7959d`) and is unrelated to `Services/`. Logged to `.planning/phases/02-persistence-entitlements/deferred-items.md` rather than fixed, per scope boundary — likely caused by simulator resource contention from a sibling executor (plan 02-01) running `xcodebuild test` concurrently on the same machine. All `WordPuzzleTests` target tests (including the new `PersistenceStoreTests`) passed cleanly.

## User Setup Required

None - no external service configuration required. (StoreKit/App Store Connect setup is scoped to other plans in this phase, not 02-02.)

## Next Phase Readiness
- `PersistenceStore`'s API surface (`makeContainer`, `record`, `puzzlesPlayedToday`, `totalGamesPlayed`, `bestScore`, `totalWordsFound`) is frozen and ready for plan 02-03 to append `currentStreak(now:)` to the same file, and for plan 02-05 to instantiate it in `WordPuzzleApp.swift`.
- No blockers for 02-03 or 02-05.
- See `.planning/phases/02-persistence-entitlements/deferred-items.md` for the one pre-existing, out-of-scope UI test failure noted above — worth a clean isolated re-run once parallel plan execution finishes.

---
*Phase: 02-persistence-entitlements*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Services/GameRecord.swift
- FOUND: WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
- FOUND: WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift
- FOUND: .planning/phases/02-persistence-entitlements/deferred-items.md
- FOUND commit: a581bcb (test RED, Task 1)
- FOUND commit: a65b44c (feat GREEN, Task 1)
- FOUND commit: 284b9e8 (test RED, Task 2)
- FOUND commit: f0d14c1 (feat GREEN, Task 2)
