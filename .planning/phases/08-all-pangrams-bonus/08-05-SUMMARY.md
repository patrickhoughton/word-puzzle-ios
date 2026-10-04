---
phase: 08-all-pangrams-bonus
plan: 05
subsystem: ui
tags: [swiftui, celebration, haptics, accessibility, sound]
requires: [08-02, 08-03, 08-04]
provides:
  - SweepTallyCard and LengthCompletePill presentation views
  - GameView celebration overlay host with sequential cancellable drain Task
affects: [08-06]
key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/Views/CompletionCelebrationViews.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
requirements-completed: [BON-03, BON-05, BON-06, BON-08]
duration: ~15min
completed: 2026-10-04
---

# Phase 8 Plan 05: Celebration views and GameView wiring Summary

Value-in SweepTallyCard / LengthCompletePill plus a GameView drain Task that plays the length pill then the sweep tally sequentially, with replaced sounds, offset haptics, Reduce Motion fallbacks and single VoiceOver announcements.

## Accomplishments
- New presentation-only views (no view-model, no hit testing, hidden from VoiceOver); pill uses AttributedString so text equals `lengthPillText`.
- GameView passes real foundPangrams/totalPangrams/sweepBonus/lengthBonusTotal to ScoreBarView, FoundWordsView and MissedWordsView.
- Per-word sound replaced via `forAcceptedSubmission(isPangram:earnedBonus:)`; drain starts only when bonus events exist, waits 0.25s lead-in so haptics do not coincide.
- Overlay anchored top over LetterGridView, never blocks input; roundPhase leaving `.playing` cancels the drain and clears the overlay.

## Task Commits
1. Task 1: c3c5ea4 - SweepTallyCard and LengthCompletePill
2. Task 2: f7f90d0 - GameView wiring

## Deviations from Plan
None. Note: `Text + Text` was avoided in favor of the AttributedString path the plan allowed as fallback.

## Verification
- Full WordPuzzleTests: 144 tests, only failure is known-flaky WordListTests.testWordSetLookupIsO1 (timing). 
- compliance-guards.sh: all 4 guards pass.
- Animation, audio, haptics to be verified on device in Plan 06.

## Known Stubs
None.

## Self-Check: PASSED
