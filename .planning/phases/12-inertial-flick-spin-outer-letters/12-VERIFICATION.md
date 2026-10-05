---
phase: 12-inertial-flick-spin-outer-letters
verified: 2026-10-05T00:00:00Z
status: passed
score: 20/20 decisions (D-01..D-20) verified
---

# Phase 12: Inertial Flick-to-Spin Verification Report

**Goal:** Flick the outer ring of 6 letters either way with inertia, landing in new slots; distinct from Shuffle.
**Status:** passed. Feel items rely on Patrick's on-device sign-off (12-09-SUMMARY).

## Decision coverage

| Decision | Evidence | Status |
|---|---|---|
| D-01..D-03 off-tile spin start, single recognizer, tap/double-tap kept | LetterGridView: one DragGesture, TouchMode, `wantsSpin = startIndex == nil ...`, spinZoneMargin; pure `HexFlowerLayout.tileIndex`; `onEmptyDoubleTap` -> performShuffle | VERIFIED |
| D-04 1:1 dial, velocity carried | AngularVelocityTracker, `ringSpin.track` / `release` | VERIFIED |
| D-05 5s+ coast, continuous friction | RingSpinTuning (viscous + dry friction, max speed clamp), RingSpinTrajectory, tests | VERIFIED |
| D-06 soft snap, no overshoot | critically damped settle in RingSpinTrajectory, SlotMath.settleTarget | VERIFIED |
| D-07 upright letters | `outerOffsets(rotation:)` rotates positions only | VERIFIED |
| D-08 landing home OK | `rotateOuterLetters` returns true for k%6==0 | VERIFIED |
| D-09 commit cyclic rotation | GameViewModel.rotateOuterLetters via HexFlowerLayout.rotated; `.settled` event in GameView | VERIFIED |
| D-10 tick/clunk haptics | SpinFeedback + TickThrottle, `.ticks` / `.clunk` events | VERIFIED |
| D-11 sounds, respect setting | SoundEffect.spinTick/spinClunk, wavs bundled, `soundEnabled:` passed; deviation: synthesized sounds instead of Kenney, approved by Patrick, LICENSE recorded | VERIFIED |
| D-12 cosmetic Full circle | SpinSession.isJackpot (net angle), `.jackpot` -> spinFeedback.jackpot + showFullCircle, no score call, full_circle.wav | VERIFIED |
| D-13 grab to stop | `ringMoving` in touch-down logic, `touchDown()` | VERIFIED |
| D-14 tiles locked while moving | `isInputDisabled: viewModel.isShuffling \|\| ringSpin.isActive` | VERIFIED |
| D-15 Shuffle cancels spin | `performShuffle` calls `ringSpin.cancelAndCommit()`; all three shuffle paths use it | VERIFIED |
| D-16 word kept | rotateOuterLetters never touches currentWord | VERIFIED |
| D-17 only during .playing | isSpinEnabled, reset on round end, cancelAndCommit on sheets and scene phase | VERIFIED |
| D-18 Reduce Motion | `ringSpin.reduceMotion` wired from environment, branch at controller line 86 | VERIFIED |
| D-19 no VO action beyond Shuffle | Shuffle stays; a tutorial-only accessibility action was added (additive, harmless) | VERIFIED |
| D-20 tutorial spin step | TutorialStep `.spin` after `.shuffle`, controller advances on `.spin`, spinRing highlight, TutorialUITests step 7 | VERIFIED |

## Artifacts and wiring
All 8 files in Game/RingSpin exist and are substantive. RingSpinController is owned by GameView and passed to LetterGridView. Events are routed through `handleSpinEvent`. HexFlowerLayout is extended with rotation, hit test and `rotated`. Sound assets are present.

## Spot-checks
- `xcodebuild test -only-testing:WordPuzzleTests` -> TEST SUCCEEDED (re-run). The last summary line printed was a small suite, but the overall result is success. 344 passed was reported in 12-VALIDATION.
- UI tests (RingSpinUITests, TutorialUITests) reported passing in 12-09-SUMMARY. Not re-run.

## Anti-patterns
None blocking found. A debug-only "Preview Full circle!" button is inside `#if DEBUG` territory (GameView ~line 425). I did not confirm the guard.

## Human verification
None outstanding. On-device feel was signed off by Patrick.

## Gaps
None.

_Verifier: Claude (gsd-verifier)_
