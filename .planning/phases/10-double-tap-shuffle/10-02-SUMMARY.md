---
phase: 10-double-tap-shuffle
plan: 02
subsystem: game-ui
tags: [gesture, shuffle, haptics, swiftui]
requires: ["10-01"]
provides:
  - "Double-tap on empty space (flower square or background) shuffles outer letters"
  - "Light impact haptic per real shuffle"
affects: [10-03]
key-files:
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/LetterGridView.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
key-decisions:
  - "Background Color.clear layer with onTapGesture(count: 2) instead of ancestor gesture, so no gesture sits over tiles or word display"
requirements-completed: [PUZZ-04]
duration: 8min
completed: 2026-10-04
---

# Phase 10 Plan 02: Double-tap shuffle wiring Summary

LetterGridView's single DragGesture now feeds EmptyDoubleTapDetector (with a Rectangle contentShape covering gaps), and GameView adds a behind-everything clear background double-tap layer plus a light impact haptic keyed on shuffleCount.

## Tasks
1. LetterGridView onEmptyDoubleTap + detector in existing gesture - commit "feat(10-02): empty-space double-tap detection..."
2. GameView wiring (grid callback, background layer, haptic) - commit "feat(10-02): wire background double-tap layer..."

## Verification
Full unit suite (-only-testing:WordPuzzleTests) TEST SUCCEEDED; scripts/compliance-guards.sh passed. On-device feel checks deferred to Plan 03.

## Deviations from Plan
None. Both tasks were edited together and built once, then committed as two separate commits.

## Known Stubs
None.

## Self-Check: PASSED
