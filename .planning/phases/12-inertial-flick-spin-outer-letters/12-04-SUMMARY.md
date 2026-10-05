---
phase: 12-inertial-flick-spin-outer-letters
plan: 04
subsystem: audio
tags: [avfoundation, sound, spin]
requires: []
provides:
  - SoundEffect.spinTick / spinClunk / fullCircle
  - SoundManager.playSpinTick(enabled:volume:) with 4-player round-robin pool
affects: [12-06 SpinFeedback]
key-files:
  created:
    - WordPuzzle/WordPuzzle/Sounds/spin_tick.wav
    - WordPuzzle/WordPuzzle/Sounds/spin_clunk.wav
    - WordPuzzle/WordPuzzle/Sounds/full_circle.wav
  modified:
    - WordPuzzle/WordPuzzle/Sounds/LICENSE.txt
    - WordPuzzle/WordPuzzle/Services/SoundManager.swift
    - WordPuzzle/WordPuzzleTests/SoundManagerTests.swift
decisions:
  - "Audio PATH B (fallback) used: clips derived from already-bundled Kenney CC0 clips via python gain/pitch shift + afconvert; ffmpeg not installed and brew install skipped to save time."
metrics:
  completed: 2026-10-05
---

# Phase 12 Plan 04: Spin Sounds Summary

Three new sound effects (spin tick, clunk, Full circle) plus a 4-player round-robin pool so ~20 ticks/s never clip, all behind the existing Sound Effects gate and the .ambient session.

## Audio path used: B (fallback)
- spin_tick: sweep_tick, gain 0.5, pitch x1.15 (about 20 ms)
- spin_clunk: sweep_tick, gain 0.9, pitch x0.55 (about 42 ms)
- full_circle: pangram_sweep, gain 0.9, pitch x1.12 (about 200 ms)

All are 44.1 kHz mono Int16 (verified with afinfo) and credited in LICENSE.txt. Because these are pitch-shifted derivatives, the on-device checkpoint (12-09) should offer an audition and swap to true Kenney tick_001 / drop_002 / maximize_004 if they sound weak.

## Commits
- Task 1 (clips + LICENSE): see git log "feat(12-04): add spin tick, clunk and full circle clips"
- Task 2 (SoundManager + tests): see git log "feat(12-04): spin SoundEffect cases and round-robin tick pool"

## Verification
SoundManagerTests: 24 tests passed (including testAllEffectsAreBundled). compliance-guards.sh not run (no networking code added).

## Deviations from Plan
None to behavior. Path B chosen directly rather than attempting the brew/ffmpeg time-box.

## Self-Check: PASSED
