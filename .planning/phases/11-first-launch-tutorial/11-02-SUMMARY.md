---
phase: 11-first-launch-tutorial
plan: 02
subsystem: tutorial
tags: [swift, tutorial, practice-puzzle, copy]
requires: []
provides:
  - PracticePuzzle (DOLPHIN, center P) curated literal with scripted words
  - TutorialStep enum and TutorialText copy table
affects: [11-04, 11-05]
tech-stack:
  added: []
  patterns: [pure data enums locked by unit tests]
key-files:
  created:
    - WordPuzzle/WordPuzzle/Tutorial/PracticePuzzle.swift
    - WordPuzzle/WordPuzzle/Tutorial/TutorialStep.swift
    - WordPuzzle/WordPuzzleTests/PracticePuzzleTests.swift
    - WordPuzzle/WordPuzzleTests/TutorialCopyTests.swift
key-decisions:
  - "Practice puzzle is a non-DEBUG curated literal, validated against the bundled word list"
requirements-completed: [TUT-01, TUT-06]
duration: 10min
completed: 2026-10-04
---

# Phase 11 Plan 02: Practice Puzzle and Tutorial Copy Summary

DOLPHIN/P hand-curated practice puzzle plus a 9-step TutorialStep enum and verbatim UI-SPEC copy table, both locked by passing unit tests.

## Deviations from Plan

None - plan executed as written. Tests were run on iPhone 17 Pro Max (parallel-agent constraint) rather than iPhone 17 Pro. Only PracticePuzzleTests and TutorialCopyTests were run; the full suite and compliance-guards script were not run.

## Commits
- 0ce67c5: practice puzzle + tests
- c91bca6: TutorialStep + copy + tests

## Self-Check: PASSED
