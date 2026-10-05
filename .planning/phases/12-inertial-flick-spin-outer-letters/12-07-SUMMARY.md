---
phase: 12-inertial-flick-spin-outer-letters
plan: 07
subsystem: game-ui
tags: [swiftui, gesture, ring-spin]
requires: [12-03, 12-05, 12-06]
provides:
  - LetterGridView per-touch tiles/spin mode in a single DragGesture, letter-keyed rotated tiles, 28pt spin-zone hit area
  - GameView ownership of RingSpinController/SpinFeedback, event routing, performShuffle(), isSpinEnabled gating, lifecycle resets, tutorial spin wiring
key-files:
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/LetterGridView.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
metrics:
  completed: 2026-10-05
---

# Phase 12 Plan 07: Wire the spin into the game screen Summary

Off-tile drags now turn the outer ring 1:1 with inertial coast and slot commit; tile touches at rest behave as before. GameView owns the controller and routes ticks, clunk, commit and jackpot feedback.

## Commits
- 3267d8f: LetterGridView (single DragGesture, pure-math hit test, letter-keyed tiles, padding(m)/padding(-m) hit area; TileFramePreferenceKey removed)
- cc29124: GameView wiring

## Decisions recorded (confirm at the 12-09 on-device checkpoint)
1. While the ring is moving, ANY touch except the center tile grabs it and never types; the center tile falls to tiles mode where isInputDisabled ignores it (reconciles D-13 and D-14).
2. A tap on a MOVING ring always grabs and never counts toward the grid double-tap, so a grid double-tap mid-spin grabs then settles. Background double-tap and the Shuffle button go through performShuffle(), which snaps+commits then shuffles. A grid double-tap shuffles only if the ring was at rest.
3. Tiles are keyed by LETTER, so a regular Shuffle now visibly slides tiles between slots instead of cross-fading in place. Needed so the spin commit is a visual no-op; user accepts or rejects on device.
4. VoiceOver (D-19): no gameplay spin action. Tutorial spin step escape is the banner action from 12-05.

## Deviations from Plan
- Reworded a GameView comment so `grep ringSpin.angle` has zero matches (acceptance criterion).
- performShuffle adds an isLive(.shuffle) guard to the grid empty double-tap path, which previously had none (per plan).

## Verification
- WordPuzzleTests unit target: TEST SUCCEEDED. compliance-guards.sh exit 0. Build succeeded.
- UI tests not run; TutorialUITests.testFullTutorialHandsOffToRealPuzzle expected to fail until 12-08.

## Known Stubs
None (jackpot popup deferred to 12-08 per plan).

## Self-Check: PASSED
