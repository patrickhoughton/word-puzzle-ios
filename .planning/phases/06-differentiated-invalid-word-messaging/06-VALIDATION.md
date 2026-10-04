---
phase: 6
slug: differentiated-invalid-word-messaging
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-04
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test`, `#expect`) in `WordPuzzleTests` |
| **Config file** | `WordPuzzle/WordPuzzle.xcodeproj`, scheme `WordPuzzle` |
| **Quick run command** | `cd WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/GameViewModelTests -only-testing:WordPuzzleTests/SoundManagerTests` |
| **Full suite command** | `cd WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests` |
| **Estimated runtime** | ~90 seconds (includes build) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-T1 | 06-01 | 1 | D-01/D-02/D-07 reasons + precedence | unit | quick run (GameViewModelTests) | ✅ extend | ⬜ pending |
| 06-01-T1 | 06-01 | 1 | D-02 duplicate leaves score/foundWords unchanged | unit | quick run (GameViewModelTests) | ✅ extend | ⬜ pending |
| 06-01-T1 | 06-01 | 1 | D-03/D-04 exact message strings | unit | quick run (GameViewModelTests) | ✅ extend | ⬜ pending |
| 06-01-T2 | 06-01 | 1 | D-05 no reject sound for duplicate | unit | quick run (SoundManagerTests) | ✅ extend | ⬜ pending |
| 06-02-T1 | 06-02 | 2 | D-03/D-05/D-06 view + sound wiring compiles, suite green | build + unit | full suite command | ✅ | ⬜ pending |
| 06-02-T2 | 06-02 | 2 | Device install | script | `bash scripts/install-on-device.sh Debug` | ✅ | ⬜ pending |
| 06-02-T3 | 06-02 | 2 | D-05/D-06 haptics/sound/color | manual | see Manual-Only | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The existing assertion at `GameViewModelTests.swift:47` (`== .rejected`) must be updated in the same task as the enum change or the test target won't compile.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Duplicate: no shake, single light haptic, no sound, secondary color | D-05 | Haptics are no-ops in Simulator; animation/color not unit-observable | On device, find a word, submit it again; confirm gentle feedback and "Got that one already" in gray |
| Too short / missing center / not a word: shake, double heavy haptic, reject sound, error color | D-06 | Same as above | On device, submit "can"-style 3-letter word, a word without center letter, and a non-word; confirm full feedback with correct text |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
