---
phase: 12-inertial-flick-spin-outer-letters
plan: 05
subsystem: game-model, tutorial
tags: [swiftui, observable, tutorial]
requires: [12-03]
provides:
  - GameViewModel.rotateOuterLetters(by:)
  - TutorialStep.spin, TutorialAction.spin(slots:), TutorialTarget.spinRing
  - TutorialText.spinAccessibilityActionName
  - TutorialBannerView accessibilityActionName / onAccessibilityAction
affects: [12-06, 12-07, 12-08]
key-files:
  modified:
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
    - WordPuzzle/WordPuzzle/Tutorial/TutorialStep.swift
    - WordPuzzle/WordPuzzle/Tutorial/TutorialController.swift
    - WordPuzzle/WordPuzzle/Game/Views/TutorialBannerView.swift
    - WordPuzzle/WordPuzzleTests/TutorialCopyTests.swift
    - WordPuzzle/WordPuzzleTests/TutorialControllerTests.swift
decisions:
  - "Spin step is strict; any settled spin (even 0 slots) advances to pangram and starts the hint timer"
metrics:
  completed: 2026-10-05
---

# Phase 12 Plan 05: Spin commit and tutorial spin step Summary

`rotateOuterLetters(by:)` commits cyclic outer-letter rotations (.playing only, never touches the word or shuffle state), and the tutorial is now 10 steps with a strict "Give it a spin" step after Shuffle.

## Commits
- c85c9df: GameViewModel.rotateOuterLetters(by:) with 6 tests
- 6009d7c: tutorial step, controller, banner VoiceOver action, tests

## Verification
Whole WordPuzzleTests target: 340 tests pass.

## Deviations from Plan
- One of my own new tests (negative/wrapping) wrongly re-called startNewRound, which reshuffles letters; fixed the test. No production change.
- Expected: `TutorialUITests.testFullTutorialHandsOffToRealPuzzle` now fails until 12-07 (gesture) and 12-08 (UI test update). Not run here.

## Self-Check: PASSED
