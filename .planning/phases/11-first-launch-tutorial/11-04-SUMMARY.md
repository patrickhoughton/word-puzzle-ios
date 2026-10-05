---
phase: 11-first-launch-tutorial
plan: 04
subsystem: tutorial
tags: [swift, observable, state-machine]
requires: [11-01, 11-02]
provides:
  - TutorialController (nil-store practice GameViewModel, send/allows gating, onExit hand-off)
  - TutorialAction, TutorialTarget, TutorialMode, TutorialTiming
affects: [11-05]
key-files:
  created:
    - WordPuzzle/WordPuzzle/Tutorial/TutorialController.swift
    - WordPuzzle/WordPuzzleTests/TutorialControllerTests.swift
key-decisions:
  - "Practice board is a second GameViewModel with persistenceStore nil, so it cannot write SwiftData"
requirements-completed: [TUT-01, TUT-02, TUT-04, TUT-05]
duration: 15min
completed: 2026-10-04
---

# Phase 11 Plan 04: TutorialController Summary

View-free @Observable state machine driving the 9-step tutorial on a nil-persistence practice GameViewModel, with strict input gating, delayed miss explanation, pangram hints, and skip/finish/replay semantics. 19 unit tests.

## Deviations from Plan
None. Tasks 1 and 2 share one test file and were committed together (645788a) since the controller and all tests were written in one pass.

## Verification
Full WordPuzzleTests: 250 tests passed (231 baseline + 19). compliance-guards.sh passes.

## Self-Check: PASSED
