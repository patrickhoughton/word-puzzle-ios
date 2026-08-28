# Deferred Items — Phase 02 (persistence-entitlements)

Out-of-scope discoveries logged during plan execution but not fixed (per executor scope boundary).

## 02-02: Full-suite regression run

- **Test:** `WordPuzzleUITests.testLaunchPerformance()`
- **Result:** Failed (135.986s) during the full-suite regression run after completing 02-02 tasks
- **Scope:** Pre-existing test created in Phase 1 (`01-01`, commit `fc7959d`), in the
  `WordPuzzleUITests` target — unrelated to `Services/GameRecord.swift` or
  `Services/PersistenceStore.swift` added by this plan
- **Likely cause:** Launch performance measurement run concurrently with a sibling
  executor (plan 02-01) also running `xcodebuild test` against Simulator clones on the
  same machine — plausible resource contention rather than a real regression
- **Action:** Not fixed — out of scope for 02-02. All `WordPuzzleTests` target tests
  (PersistenceStoreTests 4/4, WordListTests, ProfanityTests, PuzzleGeneratorTests,
  PerformanceTests) passed. Re-run `-only-testing:WordPuzzleUITests/WordPuzzleUITestsLaunchTests`
  in isolation if this persists after parallel execution ends.
