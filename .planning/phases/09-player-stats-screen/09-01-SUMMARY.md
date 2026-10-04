---
phase: 09-player-stats-screen
plan: 01
subsystem: persistence
tags: [swiftdata, migration, lightweight-migration, stats]
requires: []
provides:
  - GameRecord.rankRaw / pangramsFound / hadSweep (optional)
  - PersistenceStore.record(...) with defaulted rank/pangramsFound/hadSweep
  - finishRound() persists rank, pangram count, sweep flag
affects: [09-02, 09-03, 09-04, 09-05, 09-06]
tech-stack:
  added: []
  patterns: [nested VersionedSchema legacy-store migration test]
key-files:
  created: [WordPuzzle/WordPuzzleTests/StatsMigrationTests.swift]
  modified:
    - WordPuzzle/WordPuzzle/Services/GameRecord.swift
    - WordPuzzle/WordPuzzle/Services/PersistenceStore.swift
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
key-decisions:
  - "Migration-test technique: nested LegacySchemaV1 VersionedSchema worked first try (no committed-fixture fallback needed)"
  - "Production schema has no VersionedSchema/SchemaMigrationPlan; additive optionals rely on automatic lightweight migration"
requirements-completed: [P9-A]
duration: ~25min
completed: 2026-10-04
---

# Phase 9 Plan 01: GameRecord stats fields Summary

Three additive optional GameRecord fields (rankRaw, pangramsFound, hadSweep) migrate existing on-device stores losslessly, and finishRound() now persists them.

## Accomplishments
- Legacy-store migration proven: a store written with the frozen pre-Phase-9 schema (nested `LegacySchemaV1`) reopens via `PersistenceStore.makeContainer(url:)` with all rows intact and new fields nil, and stays readable across reopen.
- `record(...)` extended with defaulted params after `date`; all existing call sites compile unchanged.
- `finishRound()` writes rank, foundPangramCount, sweepBonus > 0 before flipping to .roundOver.
- Full WordPuzzleTests suite: 152 tests passed.

## Task Commits
1. Spike migration test (unchanged schema): c2accea
2. GameRecord fields + record() + migration assertions: 6a5e6b1
3. finishRound wiring + tests: 7563dcf

## Deviations from Plan
- Worktree was stale (missing Phase 9 plans); fast-forwarded to main before starting (same fix as prior 05-02).
- xcodebuild derivedData inside the worktree failed codesign ("resource fork, Finder information, or similar detritus") so tests used `-derivedDataPath /private/tmp/claude-501/dd0901`. One full-suite run failed without a visible assertion (likely concurrent simulator contention with the parallel agent); an immediate rerun passed 152/152.

## Known Stubs
None.

## Self-Check: PASSED
