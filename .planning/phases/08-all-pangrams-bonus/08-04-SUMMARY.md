---
phase: 08-all-pangrams-bonus
plan: 04
subsystem: ui
tags: [swiftui, score-bar, found-words, shimmer, mythic-grandmaster]
requires: [08-01]
provides:
  - ScoreBarView pangram counter, overflow shimmer/glow, Mythic styling, static accessibilityText
  - FoundWordsView pangram line and group "+L" bonus
  - MissedWordsView sweep / length bonus lines
affects: [08-05]
key-files:
  created:
    - WordPuzzle/WordPuzzleTests/ScoreBarViewTests.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift
    - WordPuzzle/WordPuzzle/Game/Views/FoundWordsView.swift
    - WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift
    - WordPuzzle/WordPuzzleTests/FoundWordsViewTests.swift
key-decisions:
  - "New view parameters have default values (0) so GameView compiles unchanged until Plan 05 wires real values"
requirements-completed: [BON-03, BON-04, BON-06, BON-08]
metrics:
  duration: ~20min
  completed: 2026-10-04
---

# Phase 8 Plan 04: Static bonus UI Summary

Value-in views now render the pangram counter (seal icon + "1/3") in an always-present detail row, a full-bar glow plus shimmer when progress > 1 (glow only under Reduce Motion), accent sparkles styling for Mythic Grandmaster, the Found Words "Pangrams · X of N" line with "+L" group bonuses, and earned-only "Pangram sweep!" / "Length bonuses" lines in MissedWordsView. All copy and accessibility strings are pinned by tests.

## Commits
- RED ScoreBarView tests (test(08-04))
- feat(08-04): ScoreBarView changes
- 89a0c4f feat(08-04): FoundWordsView and MissedWordsView changes

## Verification
ScoreBarViewTests and FoundWordsViewTests pass; compliance guards pass; full suite passes except the known flaky WordListTests.testWordSetLookupIsO1.

## Deviations from Plan
- The RED step for Task 2 was committed together with its implementation (tests and code in one commit) rather than as a separate failing-test commit.
- Worktree fast-forwarded to main before starting; derived data placed outside the repo (per instructions).

## Known Stubs
None. Default-valued parameters (foundPangrams, totalPangrams, sweepBonus, lengthBonusTotal) are intentionally 0 until Plan 05 wires GameView.

## Self-Check: PASSED
