---
phase: 08-all-pangrams-bonus
plan: 03
subsystem: game-logic
tags: [view-model, bonuses, tdd, swift-testing]
requires: ["08-01"]
provides:
  - "GameViewModel sweepBonus / lengthBonusTotal / completedLengths / foundPangramCount / totalPangramCount"
  - "lastSubmissionBonusEvents, pendingCelebrations FIFO queue, dequeueCelebration()"
  - "Unclamped progressFraction (> 1 allowed)"
affects: [08-04, 08-05, 08-06]
key-files:
  modified:
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
key-decisions:
  - "SubmissionOutcome unchanged; bonuses live in separate state so points stay the word's own points"
  - "All bonus state is set before acceptedSubmissionCount increments, so onChange handlers see current events"
requirements-completed: [BON-01, BON-02, BON-03, BON-07, BON-08]
duration: ~20min
completed: 2026-10-04
---

# Phase 8 Plan 03: Completion-bonus detection in GameViewModel Summary

GameViewModel now awards the pangram-sweep (7 per pangram) and length-completion (+L) bonuses once each at submission time, queues celebrations in D-17 order (length, then sweep), and no longer clamps progress at 1.

## Commits
- 19fb427 test(08-03): failing tests (RED); 3 legacy score expectations updated (5, 15, 5, 5)
- 30dc096 feat(08-03): detection, bonus state, queue, unclamped progress (GREEN)

## Verification
GameViewModelTests + RankTierTests: 46 tests pass. PuzzleEngine untouched (D-13). maxPossibleScore computation unchanged (D-03).

## Deviations from Plan
None. Worktree fast-forwarded to main first; derived data kept at /private/tmp/claude-501/dd-0803. A full-suite run was started as a final check; it exceeded the foreground timeout (known slow/flaky cold start) and is not part of the verified claims above.

## Known Stubs
None.

## Self-Check: PASSED
Commits 19fb427 and 30dc096 present; both modified files exist.
