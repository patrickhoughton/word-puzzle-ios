---
phase: 8
slug: all-pangrams-bonus
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-04
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Test`, `@Suite`), `@testable import WordPuzzle`; XCTest UI tests in `WordPuzzleUITests` |
| **Config file** | `WordPuzzle/WordPuzzle.xcodeproj` shared scheme `WordPuzzle` |
| **Quick run command** | `cd WordPuzzle && xcodebuild test -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/RankTierTests -only-testing:WordPuzzleTests/ScoreCalculatorTests -only-testing:WordPuzzleTests/SoundManagerTests` |
| **Full suite command** | `cd WordPuzzle && xcodebuild test -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests` |
| **Estimated runtime** | ~30s quick / ~120s full (GameViewModelTests loads ENABLE list, serialized) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite green + device checkpoint (AX5, Reduce Motion, haptics, audio)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

Filled in by the planner/executor against plan task IDs. Decision → test mapping (from 08-RESEARCH.md):

| Decision | Behavior | Test Type | Target | File Exists | Status |
|----------|----------|-----------|--------|-------------|--------|
| D-01 | `sweepBonus(pangramCount:)` 3→21, 1→7, 0→0 | unit | ScoreCalculatorTests | ✅ add cases | ⬜ pending |
| D-02 | 1-pangram fixture awards word + 7 pangram + 7 sweep | unit | GameViewModelTests | ✅ add | ⬜ pending |
| D-03 | `maxPossibleScore` unchanged; `finishRound()` persists bonus-inclusive score | unit | GameViewModelTests | ✅ add | ⬜ pending |
| D-04/D-06 | `tier(100,100)==.legend`; `tier(101,100)==.mythicGrandmaster`; 11 cases | unit | RankTierTests | ✅ UPDATE | ⬜ pending |
| D-05 | `progressFraction` may exceed 1; 0 when max 0 | unit | GameViewModelTests | ✅ update | ⬜ pending |
| D-07/D-17 | Same word completes length + sweep → events [length, sweep], both scored | unit | GameViewModelTests | ✅ add | ⬜ pending |
| D-08 | Tally step duration clamp(1.2/N, 0.03, 0.3) | unit | ScoreCalculatorTests / CelebrationTimingTests | ❌ W0 | ⬜ pending |
| D-09 | Copy strings exact ("Pangram sweep! +21", "5 Letters complete! +5") | unit | static copy tests | ❌ W0 | ⬜ pending |
| D-10 | New SoundEffect cases bundled; count test updated | unit | SoundManagerTests | ✅ UPDATE | ⬜ pending |
| D-11 | "Pangrams · X of N" line; ScoreBar a11y label | unit | FoundWordsViewTests | ✅ add | ⬜ pending |
| D-12/D-13 | PuzzleGenerator untouched | review | `git diff -- PuzzleGenerator.swift` empty | n/a | ⬜ pending |
| D-14/D-18 | `lengthCompletionBonus(length:)` = L; once per length; incomplete → none | unit | ScoreCalculatorTests + GameViewModelTests | ✅ add | ⬜ pending |
| Reset | New round clears sweep/length state | unit | GameViewModelTests | ✅ add | ⬜ pending |
| Empty pangrams | `pangrams: []` never sweeps | unit | GameViewModelTests | ✅ add | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Update `RankTierTests` (11 tiers, mythic boundary) and `SoundManagerTests` count test in the same plan as the code change
- [ ] GameViewModel fixtures: existing `pangramFixturePuzzle` (stack case), new 2-pangram fixture, `pangrams: []` fixture
- [ ] Framework install: none

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tally card, pill, shimmer, Reduce Motion fallback | UI-SPEC | Animation timing not unit-assertable | `scripts/install-on-device.sh`; trigger sweep + length completion; toggle Reduce Motion |
| VoiceOver announcement | UI-SPEC | Requires assistive tech | Enable VoiceOver, complete a length group, confirm announcement |
| AX5 layout fit | UI-SPEC | Dynamic Type visual | Set AX5, trigger celebrations, confirm no clipping |
| Haptics + audio clips (audition) | D-10 | Perceptual | Device with sound on; confirm fanfare/tick/chime distinct, silent switch honored |
| Stack ordering visual | D-17 | Sequencing visual | Find a word completing both length + sweep; pill then tally, no overlap; Finish Round mid-tally dismisses |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
