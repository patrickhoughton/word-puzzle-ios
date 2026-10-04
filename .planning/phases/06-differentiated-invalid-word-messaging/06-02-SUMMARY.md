---
phase: 06-differentiated-invalid-word-messaging
plan: 02
subsystem: ui
tags: [swiftui, haptics, sound, rejection-feedback]
requires: [06-01]
provides:
  - Reason-specific rejection message, color, haptic and shake in WordDisplayView
  - Reason-gated reject sound in GameView (silent for duplicates)
affects: []
tech-stack:
  added: []
  patterns: [guard case let .rejected(reason) = outcome, SoundEffect.forRejection gating]
key-files:
  created: []
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/WordDisplayView.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
key-decisions:
  - "Duplicates show secondary-color message with no shake, one light haptic, no sound; other reasons keep full error feedback"
requirements-completed: [D-03, D-04, D-05, D-06]
duration: 20min
completed: 2026-10-04
---

# Phase 6 Plan 02: Reason-specific rejection feedback Summary

WordDisplayView now shows each RejectionReason's own message ("Too tiny!", "Forgot the middle!", "Got that one already", "Hmm, not a word"), with duplicates handled gently (gray, no shake, light haptic, no sound) and GameView gating the reject sound via `SoundEffect.forRejection`.

## Commits
- ecdfa2a: reason-specific feedback and reason-gated sound

## Tasks
1. Reason-specific feedback in WordDisplayView and reason-gated sound in GameView (ecdfa2a)
2. Debug build installed on iPhone over Wi-Fi (no commit)
3. On-device verification: user approved

## Verification
- Full suite: 94 tests, 1 failure: `WordListTests.testWordSetLookupIsO1`, a timing flake under parallel load. It passes in isolation, was also seen in 06-01, and is unrelated to this phase.
- On-device human verification approved.

## Deviations from Plan
None - plan executed as written.

## Self-Check: PASSED
