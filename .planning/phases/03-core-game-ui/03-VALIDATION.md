---
phase: 3
slug: core-game-ui
status: planned
nyquist_compliant: true
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
| 03-01 T3 | 03-01 | 1 | GAME-01 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testAppendAndSubmitBuildsWord` | created by 03-01 T3 | ⬜ pending |
| 03-01 T3 | 03-01 | 1 | GAME-02 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testSubmitInvalidWordReturnsFalse` | created by 03-01 T3 | ⬜ pending |
| 03-01 T3 | 03-01 | 1 | GAME-03 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testScoreAndFoundCountUpdateOnCorrectSubmit` | created by 03-01 T3 | ⬜ pending |
| 03-01 T3 | 03-01 | 1 | GAME-04 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testMissedWordsGroupedByLength` | created by 03-01 T3 | ⬜ pending |
| 03-01 T3 | 03-01 | 1 | PUZZ-04 | unit + manual | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testShufflePreservesLetterSetExcludesCenter` | created by 03-01 T3 | ⬜ pending |
| 03-01 T3 | 03-01 | 1 | RET-03 | manual-only (proxy: unit) | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testCorrectSubmissionTogglesHapticTrigger` (proxy only — does not prove haptic actually fires on hardware) | created by 03-01 T3 | ⬜ pending |
| 03-01 T2 | 03-01 | 1 | D-09 (supports GAME-03) | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/RankTierTests` | created by 03-01 T2 | ⬜ pending |
| 03-02 T1 | 03-02 | 2 | GAME-01 (hex geometry) | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/HexGeometryTests` | created by 03-02 T1 | ⬜ pending |
| 03-02 T2 | 03-02 | 2 | GAME-01, PUZZ-04 (grid + gesture) | build + manual | `xcodebuild build ... -scheme WordPuzzle` | n/a | ⬜ pending |
| 03-03 T1-T3 | 03-03 | 2 | GAME-02, GAME-03, GAME-04, RET-03 (views) | build + manual | `xcodebuild build ... -scheme WordPuzzle` | n/a | ⬜ pending |
| 03-04 T2 | 03-04 | 3 | all (launch path) | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/AppWiringTests/testGameViewModelStartsARoundFromLoadedWordList` | created by 03-04 T2 | ⬜ pending |
| 03-05 T1 | 03-05 | 4 | all (on-device) | manual checkpoint | full suite + 8 on-device checks | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Plan/wave/task-ID columns filled in by gsd-planner on 2026-08-29. Both Wave 0 test files are created by plan 03-01, which has no dependencies and executes first.*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/GameViewModelTests.swift` — stubs/tests for GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03 (proxy) — **assigned to plan 03-01, Task 3**
- [ ] `WordPuzzleTests/RankTierTests.swift` — covers D-09's percentage-of-max tier lookup (not a numbered requirement but load-bearing for GAME-03's UI display) — **assigned to plan 03-01, Task 2**
- [ ] `WordPuzzleTests/HexGeometryTests.swift` — hexagon path + flower-offset trigonometry — **assigned to plan 03-02, Task 1** (added during planning)
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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: every task across all 5 plans carries an `<automated>` command
- [x] Wave 0 covers all MISSING references (plan 03-01 is dependency-free and creates both files)
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** plan-mapped 2026-08-29 (manual on-device rows verified in plan 03-05)
