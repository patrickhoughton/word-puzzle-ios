---
phase: 3
slug: core-game-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-29
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Test`, `#expect`) — confirmed in use across `WordPuzzleTests/` (e.g. `ScoreCalculatorTests.swift`, `PuzzleGeneratorTests.swift`) |
| **Config file** | None — no `.xctestplan`; tests run via the `WordPuzzle` scheme's default test action |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/GameViewModelTests` |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` |
| **Estimated runtime** | ~60 seconds (quick) / ~180 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/GameViewModelTests`
- **After every plan wave:** Run `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'`
- **Before `/gsd:verify-work`:** Full suite must be green, PLUS a manual on-device pass (this phase's success criteria explicitly require "works on a real iPhone") covering: drag-to-connect across tiles, tap-to-append, swipe-down submit, shuffle animation, haptic feel, shake/pop feedback
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 3-XX-XX | TBD | 0 | GAME-01 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testAppendAndSubmitBuildsWord` | ❌ W0 | ⬜ pending |
| 3-XX-XX | TBD | 0 | GAME-02 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testSubmitInvalidWordReturnsFalse` | ❌ W0 | ⬜ pending |
| 3-XX-XX | TBD | 0 | GAME-03 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testScoreAndFoundCountUpdateOnCorrectSubmit` | ❌ W0 | ⬜ pending |
| 3-XX-XX | TBD | 0 | GAME-04 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testMissedWordsGroupedByLength` | ❌ W0 | ⬜ pending |
| 3-XX-XX | TBD | 0 | PUZZ-04 | unit + manual | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testShufflePreservesLetterSetExcludesCenter` | ❌ W0 | ⬜ pending |
| 3-XX-XX | TBD | 0 | RET-03 | manual-only (proxy: unit) | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testCorrectSubmissionTogglesHapticTrigger` (proxy only — does not prove haptic actually fires on hardware) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Plan/wave/task-ID columns are TBD — gsd-planner fills these in when it creates the actual PLAN.md task breakdown.*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/GameViewModelTests.swift` — stubs/tests for GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03 (proxy)
- [ ] `WordPuzzleTests/RankTierTests.swift` — covers D-09's percentage-of-max tier lookup (not a numbered requirement but load-bearing for GAME-03's UI display)
- [ ] No shared fixture gap — existing `@Suite(.serialized)` + `WordList()`/`.load()` pattern from `PuzzleGeneratorTests.swift` is directly reusable for constructing a real `Puzzle` in `GameViewModelTests`
- [ ] Framework install: none — Swift Testing already present, no `xcodebuild -resolvePackageDependencies` needed (zero SPM deps)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Haptic feedback actually fires on correct submission | RET-03 | Simulator cannot verify real haptic hardware output; `sensoryFeedback` trigger toggling is only a proxy | On a real iPhone, submit a valid word and confirm a haptic tap is felt |
| Hex grid visual layout — center letter distinguished, 6 outer letters arranged correctly | GAME-01 | Visual correctness not verifiable by unit test | On-device/simulator visual check against CONTEXT.md D-01 |
| Drag-to-connect gesture across tiles feels correct and doesn't drop/misfire | GAME-01, D-02 | Gesture feel and hit-testing accuracy require real touch input | On a real iPhone, drag across multiple tiles and confirm each is registered in order |
| Tap-to-append and drag-to-connect don't fight each other for the same touch | GAME-01, D-02 | Gesture composition conflicts only surface with real touch timing | On a real iPhone, alternate tap and drag input on the same puzzle round |
| Shuffle animation feel (non-instant rearrangement) | PUZZ-04, D-03 | Animation smoothness is a visual/qualitative check | Tap Shuffle repeatedly and confirm outer letters animate (not jump) into new positions |
| Reject animation on invalid word submission | GAME-02 | Animation correctness not verifiable by unit test | Submit an invalid word and confirm a shake/reject animation plays without crashing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
