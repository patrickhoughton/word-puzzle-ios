---
phase: 12-inertial-flick-spin-outer-letters
plan: 09
subsystem: validation
tags: [validation, on-device, audio-tuning]
requires: [12-08]
provides:
  - Phase gate: full automated suite green, validation map complete, on-device feel sign-off
  - Synthesized peg-wheel spin tick and landing clunk
key-files:
  created:
    - scripts/synth-spin-sounds.py
  modified:
    - .planning/phases/12-inertial-flick-spin-outer-letters/12-VALIDATION.md
    - WordPuzzle/WordPuzzle/Sounds/spin_tick.wav
    - WordPuzzle/WordPuzzle/Sounds/spin_clunk.wav
    - WordPuzzle/WordPuzzle/Sounds/LICENSE.txt
    - WordPuzzle/WordPuzzle/Game/RingSpin/SpinFeedback.swift
metrics:
  completed: 2026-10-05
---

# Phase 12 Plan 09: Validation and on-device sign-off Summary

Automated gates green, Debug build installed over Wi-Fi, and Patrick approved the spin's feel on his iPhone after the spin sounds were replaced with a synthesized prize-wheel peg tick.

## Commits
- 00b66dc, febd1b2: 12-VALIDATION.md filled in (nyquist_compliant, wave 0 complete, environmental hazards noted)
- 16bd141: first softening pass on spin tick/clunk (low-pass, lower pitch, tick volume 0.3 + 0.2f) — rejected as "like a beep"
- e7001d1: synthesized peg-wheel tick (variant B "woody") and matching clunk, generator kept at scripts/synth-spin-sounds.py

## Verification
- WordPuzzleTests (344): TEST SUCCEEDED. compliance-guards.sh: exit 0.
- UI tests: RingSpinUITests, StatsPresentationUITests pass; TutorialUITests (3) pass after a simulator reboot and fresh install.
- Environmental hazards (not code defects): free-tier 3 rounds/day cap spans UI test classes in one install; WordPuzzleUITestsLaunchTests leaves the simulator in landscape (fix: `simctl shutdown` + `boot`).

## On-device checkpoint (Patrick)
- Reply: "approved, keep both 5 and 8. The sounds are a little to shrill. I want mure of a light ticking sound"
- Step 5 (moving-tile tap grabs the ring, types nothing): **kept**
- Step 8 (Shuffle slides tiles between slots instead of cross-fade): **kept**
- Sound: pitch-shifted Kenney derivatives were too shrill, then too beep-like; three synthesized flapper-on-peg variants were auditioned on the Mac and Patrick chose **B (woody)**. Final reply: "good".
- Tuning constants (RingSpinTuning, TickThrottle, spin zone): unchanged. Only tick volume formula changed (0.45 + 0.25f -> 0.3 + 0.2f).

## Deviations
- Sounds replaced with original synthesized audio instead of the Kenney clips suggested in 12-04; LICENSE.txt records them as original work.
