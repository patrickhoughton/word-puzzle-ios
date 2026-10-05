---
phase: 11-first-launch-tutorial
plan: 05
subsystem: tutorial
tags: [swiftui, wiring]
requires: [11-01, 11-03, 11-04]
provides:
  - Tutorial wired into the running app (launch gate, root switch, GameView input gating)
affects: [11-06]
key-files:
  modified:
    - WordPuzzle/WordPuzzle/WordPuzzleApp.swift
    - WordPuzzle/WordPuzzle/ContentView.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
key-decisions:
  - "GameView takes optional tutorial; every change is a no-op when nil"
  - "Settings replay uses pendingHowToPlay + sheet onDismiss (no root swap mid-dismissal)"
requirements-completed: [TUT-01, TUT-02, TUT-03, TUT-04, TUT-05, TUT-06]
duration: 15min
completed: 2026-10-04
---

# Phase 11 Plan 05: Tutorial Wiring Summary

WordPuzzleApp owns TutorialController and branches at launch (tutorial for no-history installs, otherwise a real round); ContentView swaps in a practice-VM GameView; GameView routes all input through `tutorial.send`, shows banner/highlights/dimming/Skip, replays from Settings, and announces steps to VoiceOver.

## Deviations from Plan
None - plan executed as written. Added a small `hint(_:default:)` helper so highlighted controls expose the step instruction as accessibility hint.

## Verification
- Unit suite: 250 tests passed. compliance-guards.sh passes.
- WordPuzzleUITests (all): TEST SUCCEEDED, 0 failures (2 skipped pre-existing).
- Not exercised: manual fresh-install tutorial walkthrough (plan 11-06 covers).

## Commits
- f83d49c app + ContentView; 4a5c57b GameView

## Self-Check: PASSED
