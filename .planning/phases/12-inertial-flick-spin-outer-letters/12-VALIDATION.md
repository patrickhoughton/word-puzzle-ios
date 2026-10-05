---
phase: 12
slug: inertial-flick-spin-outer-letters
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-05
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`/`@Test`/`#expect`) + XCUITest |
| **Config file** | Xcode project — `WordPuzzleTests` / `WordPuzzleUITests` (file-system-synchronized groups) |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/<TouchedSuite>` |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' && bash scripts/compliance-guards.sh` |
| **Estimated runtime** | ~30 s quick / several minutes full |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the touched pure-helper suites
- **After every plan wave:** Run the full suite command
- **Before `/gsd:verify-work`:** Full suite must be green, then on-device feel checkpoint
- **Max feedback latency:** 30 seconds (quick)

---

## Per-Task Verification Map

*Filled in by the planner/executor per task. Decision → test mapping:*

| Decision | Behavior | Test Type | Suite | File Exists | Status |
|----------|----------|-----------|-------|-------------|--------|
| D-04/D-05 | trajectory continuity, duration monotonic in ω0, cap ≥ 5 s, sign symmetry | unit | `RingSpinTrajectoryTests` | ❌ W0 | ⬜ pending |
| D-06 | final angle exact multiple of π/3, no overshoot | unit | `RingSpinTrajectoryTests` | ❌ W0 | ⬜ pending |
| D-04 | angular velocity tracker (unwrap, stale, clamp, sign) | unit | `AngularVelocityTrackerTests` | ❌ W0 | ⬜ pending |
| D-10/D-11 | slot crossings + tick throttle | unit | `SlotMathTests`, `TickThrottleTests` | ❌ W0 | ⬜ pending |
| D-07/D-09 | `outerOffsets(rotation:)`, rotated letter mapping, commit continuity | unit | `HexGeometryTests`, `SlotMathTests` | extend | ⬜ pending |
| D-12 | jackpot predicate (net > 5 rev AND home) | unit | `SpinSessionTests` | ❌ W0 | ⬜ pending |
| D-09/D-16/D-17 | `rotateOuterLetters` guards, keeps `currentWord`, no `shuffleCount` bump | unit | `GameViewModelTests` | extend | ⬜ pending |
| D-01..D-03 | hit classification tile vs spin zone vs center | unit | `HexGeometryTests` | extend | ⬜ pending |
| D-11 | `SoundEffect` count + bundled files | unit | `SoundManagerTests` | extend | ⬜ pending |
| D-20 | tutorial step count 10, order, `allows(.spin)` | unit | `TutorialCopyTests`, `TutorialControllerTests` | extend | ⬜ pending |
| D-01/D-13/D-14 | off-tile flick rotates ring; Shuffle mid-spin | UI | `WordPuzzleUITests`/`TutorialUITests` | extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/RingSpinTrajectoryTests.swift`
- [ ] `WordPuzzleTests/SlotMathTests.swift`
- [ ] `WordPuzzleTests/AngularVelocityTrackerTests.swift`
- [ ] `WordPuzzleTests/TickThrottleTests.swift`
- [ ] `WordPuzzleTests/SpinSessionTests.swift`
- [ ] Update hard-coded counts: `TutorialCopyTests` (9 → 10), `TutorialControllerTests`, `SoundManagerTests` (effect count), `TutorialUITests` shuffle flow

---

## Manual-Only Verifications

| Behavior | Decision | Why Manual | Test Instructions |
|----------|----------|------------|-------------------|
| 1:1 tracking smoothness, coast length (5 s+ hard flick), soft snap clunk | D-04/D-05/D-06 | Feel can only be judged by touch | Install via `scripts/install-on-device.sh`; wind slowly, wiggle, soft push, hard flick |
| Haptic ticks + click sound pleasant at high speed, firmer clunk | D-10/D-11 | Haptics/audio not automatable | Flick hard with sound on; then silent switch on / sound setting off |
| "Full circle!" jackpot | D-12 | Requires real spin landing home | Flick hard repeatedly until >5 rev lands home; confirm no score change |
| Reduce Motion: no coast, snap on release | D-18 | System setting + feel | Enable Reduce Motion, flick, confirm immediate snap |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
