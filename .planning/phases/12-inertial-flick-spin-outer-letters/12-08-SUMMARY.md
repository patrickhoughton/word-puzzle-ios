---
phase: 12-inertial-flick-spin-outer-letters
plan: 08
subsystem: game-ui
tags: [swiftui, jackpot, ui-tests]
requires: [12-07]
provides:
  - FullCircleView cosmetic jackpot popup + sparkle burst, GameView wiring, DEBUG ladybug preview
  - RingSpinUITests and 10-step TutorialUITests
key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/Views/FullCircleView.swift
    - WordPuzzle/WordPuzzleTests/FullCircleViewTests.swift
    - WordPuzzle/WordPuzzleUITests/RingSpinUITests.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/GameTheme.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
    - WordPuzzle/WordPuzzleUITests/TutorialUITests.swift
metrics:
  completed: 2026-10-05
---

# Phase 12 Plan 08: Full circle jackpot and UI tests Summary

Cosmetic "Full circle!" popup (no scoring access) with sparkle burst, plus UI tests proving slow one-slot spin, tile tap, Shuffle mid-spin, and the 10-step tutorial.

## Commits
- 1bfe706: FullCircleView, GameTheme constants, GameView wiring, unit tests
- 7de7bb0: TutorialUITests spin step, RingSpinUITests

## Deviations
- [Rule 3] Sparkle drawing: Image has no .font and Canvas closure inference failed; used Text(Image(...)) and a helper draw method.
- Drag tuning in RingSpinUITests was not needed (60 degrees slow landed on slot 1 first try).

## Verification
- WordPuzzleTests: TEST SUCCEEDED. compliance-guards.sh: pass.
- RingSpinUITests: passed. TutorialUITests (3 tests): passed. Each on a fresh install.
- Running both classes together in one install fails testSkipStartsRealPuzzle only because of the free-tier 3 rounds/day cap (4 rounds); not a code defect. Run the classes separately with an uninstall between.
- 2c (fast flick) passes; whether the simulator flick actually coasts is unconfirmed, the assertion still proves tiles end on slots.

## Known Stubs
None.

## Self-Check: PASSED
