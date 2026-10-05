---
phase: 10-double-tap-shuffle
plan: 01
subsystem: game-logic
tags: [shuffle, gesture, swift-testing]
requires: []
provides:
  - "GameViewModel.shuffleOuterLetters() -> Bool (phase-gated), shuffleCount"
  - "EmptyDoubleTapDetector pure value type"
affects: [10-02, 10-03]
tech-stack:
  added: []
  patterns: ["injected time/points for deterministic gesture logic"]
key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/EmptyDoubleTapDetector.swift
    - WordPuzzle/WordPuzzleTests/EmptyDoubleTapDetectorTests.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
key-decisions:
  - "Detector defaults 0.3s interval / 10pt travel / 44pt separation; tunable in Plan 03 device check"
duration: 10min
completed: 2026-10-04
---

# Phase 10 Plan 01: Shuffle contract and double-tap detector Summary

shuffleOuterLetters() now returns Bool, is gated on .playing and !isShuffling, and bumps a monotonic shuffleCount only on real shuffles; EmptyDoubleTapDetector classifies empty-space double-taps from injected time and points.

## Tasks
1. Phase-gated shuffle + shuffleCount, 6 new tests - a64ec1b
2. EmptyDoubleTapDetector + 9 tests - see git log (feat(10-01) detector commit)

## Deviations from Plan
None - plan executed as written. (RED build-failure run was skipped; tests and implementation were written together and verified green.) No view files or pbxproj touched.

## Known Stubs
None.

## Self-Check: PASSED
