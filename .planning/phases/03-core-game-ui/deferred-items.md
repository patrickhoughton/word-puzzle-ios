# Deferred Items — Phase 03 core-game-ui

## From plan 03-03

### `WordPuzzleUITests.testLaunchPerformance()` failure — out of scope

- **Observed during:** `xcodebuild test` full-suite verification for plan 03-03.
- **Detail:** `testLaunchPerformance` failed in a run where all XCTest and Swift Testing
  unit suites passed (including `RankTierTests`, `GameViewModelTests`,
  `PuzzleGeneratorTests`, `PersistenceStoreTests`, `WordListTests`, `ScoreCalculatorTests`,
  `AppWiringTests`, `ProfanityTests` — all green). `EntitlementStoreTests` showed the
  same 3 pre-existing `skipped` sandbox tests noted since plan 02-04.
- **Why out of scope:** Plan 03-03 only adds three standalone presentation views
  (`WordDisplayView`, `ScoreBarView`, `MissedWordsView`) under `Game/Views/`. None of
  them are referenced by `WordPuzzleApp.swift` or `ContentView.swift` yet (wiring is
  plan 03-04's job), so they cannot affect app launch timing. This machine was running
  a second GSD executor agent in parallel (plan 03-02, separate worktree) building/testing
  concurrently, which is the more likely cause of a performance-test timing flake.
- **Action:** Not fixed. Flagged for the plan 03-04/03-05 executor or verifier to re-run
  in isolation and confirm it is not a real regression before phase sign-off.
