---
phase: 06-differentiated-invalid-word-messaging
plan: 01
subsystem: game-logic
tags: [swift, rejection-reason, sound, tdd]
requires: []
provides:
  - RejectionReason enum with fixed playful messages
  - SubmissionOutcome.rejected(RejectionReason)
  - SoundEffect.forRejection(_:) (nil for .alreadyFound)
affects: [06-02]
tech-stack:
  added: []
  patterns: [ordered per-reason guards, outcome set before counter bump]
key-files:
  created: []
  modified:
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
    - WordPuzzle/WordPuzzle/Services/SoundManager.swift
    - WordPuzzle/WordPuzzleTests/SoundManagerTests.swift
key-decisions:
  - "Single rejectedSubmissionCount for all reasons; duplicate gating happens at consumers"
  - "Outside-letter submissions fold into .notAWord"
requirements-completed: [D-01, D-02, D-03, D-04, D-05, D-07]
duration: 15min
completed: 2026-10-04
---

# Phase 6 Plan 01: Rejection reasons and sound mapping Summary

Typed `RejectionReason` (tooShort, missingCenterLetter, alreadyFound, notAWord) with exact playful strings, ordered checks in `submitCurrentWord()`, and a pure `SoundEffect.forRejection` that is silent for duplicates.

## Commits
- e59e466: RejectionReason, guards, GameViewModel tests
- 0977d5c: SoundEffect.forRejection and tests

## Verification
- `-only-testing:WordPuzzleTests/WordListTests, GameViewModelTests, SoundManagerTests`: 40 tests in 3 suites passed, `** TEST SUCCEEDED **`.
- Full `WordPuzzleTests` run: 94 tests, 1 issue: `WordListTests.testWordSetLookupIsO1()` (a timing test). It passed when rerun with fewer suites in parallel, so it looks like a load-related flake. It was not caused by this plan's changes and was not investigated further.

## Deviations from Plan
None. The two tasks' code was written together, then committed as two commits split by file.

## Known Stubs
None.

## Self-Check: PASSED
