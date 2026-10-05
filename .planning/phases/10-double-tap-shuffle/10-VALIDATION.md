---
phase: 10
slug: double-tap-shuffle
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-04
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) in `WordPuzzleTests` |
| **Config file** | `WordPuzzle/WordPuzzle.xcodeproj` (no separate config) |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/EmptyDoubleTapDetectorTests -only-testing:WordPuzzleTests/GameViewModelTests` |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green + on-device checklist done
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

*Filled in by planner / executor once task IDs exist.*

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-xx | 01 | 1 | PUZZ-04 | unit | quick run command | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/EmptyDoubleTapDetectorTests.swift` — detector: in-window/in-range fires; too slow / too far / drag travel rejected; `reset()` breaks chain; triple tap fires once then restarts (check whether the project uses file-system-synchronized groups or needs a pbxproj entry)
- [ ] Extend `WordPuzzleTests/GameViewModelTests.swift` — `shuffleOuterLetters()` Bool return, `shuffleCount` bump only on real shuffle, rejection while `isShuffling`, rejection outside `.playing`, in-progress word preserved

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Double-tap empty background / grid gaps shuffles | PUZZ-04 | Real touch gesture feel | On device: double-tap margins, top padding, gaps between hexes |
| Tile double-tap appends letter twice, no shuffle; tile tap latency unchanged | PUZZ-04 | Gesture timing | Rapidly tap a tile twice; word gets 2 letters, no shuffle, no perceptible lag |
| Double-tap on word display / buttons does not shuffle | PUZZ-04 | Gesture precedence | Double-tap word display, Shuffle, Delete, Finish, stats/settings icons |
| Light haptic on button + gesture, none when rejected | PUZZ-04 | Simulator has no haptics | Feel haptic on each path; rapid taps during animation buzz once |
| Inert during roundOver / sheets | PUZZ-04 | Modal presentation | Open sheets, end round, double-tap — no shuffle |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
