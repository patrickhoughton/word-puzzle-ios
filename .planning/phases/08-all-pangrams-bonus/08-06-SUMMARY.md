---
phase: 08-all-pangrams-bonus
plan: 06
subsystem: verification
tags: [device-checkpoint, overflow, debug-tools]
requires: [08-05]
provides:
  - On-device approval of Phase 8 completion bonuses
  - Strengthened overflow (> 100%) bar treatment
  - DEBUG-only shortcuts for reaching the 100% crossing on device
affects: [09]
key-files:
  created: []
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift
    - WordPuzzle/WordPuzzle/Game/GameTheme.swift
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
    - WordPuzzle/WordPuzzleTests/ScoreBarViewTests.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
    - WordPuzzle/WordPuzzleTests/WordListTests.swift
requirements-completed: [BON-01, BON-02, BON-03, BON-04, BON-05, BON-06, BON-07, BON-08]
duration: ~1h (incl. device feedback loop)
completed: 2026-10-04
---

# Phase 8 Plan 06: On-device checkpoint Summary

Phase 8 build installed over Wi-Fi on Patrick's iPhone 15 Pro and approved, after one feedback round that made the past-100% bar much louder and added Debug-only shortcuts to reach it.

## Accomplishments
- Task 1: full suite + compliance guards green; Debug build installed and launched over Wi-Fi.
- Task 2 checkpoint: **approved** by Patrick.
- Sound audition: Patrick reviewed the current clips against Kenney alternatives (local sound-picker page) and kept all three (maximize_008 fanfare, tick_002 tick, confirmation_002 chime).

## Changes from device feedback
1. **Overflow bar (bd93e5e)** — "make the over-100% bar more impactful" (Patrick chose "all of it"):
   thick molten-gold capsule with drifting gradient, pulsing glow, bright shimmer and rising sparkles;
   a live crossing of 100% fires a particle burst, vertical pop and heavy haptic; gold "112%" badge beside
   Mythic Grandmaster (`ScoreBarView.overflowPercentText`, tested). All in overlays so the score bar height
   (AX5 fit) is unchanged. Explicit #F5B800 gold (`GameTheme.overflowGold`) so it never depends on tint resolution.
   Reduce Motion: static gold capsule + badge. VoiceOver adds "Progress beyond maximum, N percent."
2. **Debug shortcuts (28a0593)** — `#if DEBUG` ladybug menu (hidden under `-ScreenshotPuzzle`):
   "Solve to just under 100%" and "Type next missing word". Tested; Release build verified to compile without them.

## Deviations from Plan
- [Rule 1 - Bug] Replaced flaky wall-clock `WordListTests.testWordSetLookupIsO1` with a compile-time
  `Set<String>` type pin (7924215). It failed only under full-suite load.
- `scripts/install-on-device.sh` auto-detect requires an already-connected tunnel; a paired-but-idle phone
  is reported as missing. Worked around by passing the UDID explicitly (script unchanged).

## Verification
- Full WordPuzzleTests: 146 tests pass. compliance-guards.sh: all guards pass.
- Patrick approved on device.
