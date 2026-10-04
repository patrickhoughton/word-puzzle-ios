---
phase: 7
slug: found-words-view
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-10-04
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), `@MainActor` suites |
| **Config file** | `WordPuzzle/WordPuzzle.xcodeproj` (scheme `WordPuzzle`, target `WordPuzzleTests`, synchronized folder) |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/GameViewModelTests -only-testing:WordPuzzleTests/FoundWordsViewTests` |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite green + `scripts/compliance-guards.sh` passes + manual D-01..D-05 simulator pass
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

*Filled by planner/executor as task IDs are assigned. Decision → test mapping from RESEARCH.md:*

| Decisions | Behavior | Test Type | Automated Command / Check | File Exists | Status |
|-----------|----------|-----------|---------------------------|-------------|--------|
| D-06, D-11 (07-01 T1) | Groups by length ascending, includes zero-found lengths | unit | GameViewModelTests `foundWordGroups` ordering test | ❌ W0 | ⬜ pending |
| D-07 (07-01 T1) | Alphabetical within group | unit | GameViewModelTests alphabetical test | ❌ W0 | ⬜ pending |
| D-10, D-12 (07-01 T1) | found/total counts, `isComplete` | unit | GameViewModelTests counts/completion test | ❌ W0 | ⬜ pending |
| D-13, D-14 (07-01 T1) | points == `ScoreCalculator.points`, `isPangram` flag | unit | GameViewModelTests points/pangram test (pangram fixture) | ❌ W0 | ⬜ pending |
| D-16 (07-01 T1) | Empty state: all groups present, no found words | unit | GameViewModelTests empty test | ❌ W0 | ⬜ pending |
| D-09, D-10, D-16 copy (07-01 T2) | Frozen copy constants | unit | FoundWordsViewTests | ❌ W0 | ⬜ pending |
| D-17 (07-01 T2, 07-02 T2) | MissedWordsView untouched | automated check | `git diff --stat -- WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift` empty | n/a | ⬜ pending |
| Build (07-02 T1/T2) | Compiles | build | `xcodebuild build ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/GameViewModelTests.swift` additions — `foundWordGroups` tests (fixture is private there; extend in-file, add pangram fixture variant)
- [ ] `WordPuzzleTests/FoundWordsViewTests.swift` — frozen-copy constants (mirror `SettingsViewTests`)

*No framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Score bar opens sheet (07-03 T2); medium/large detents; Done + swipe dismiss; board inert behind sheet | D-01..D-05 | SwiftUI sheet presentation not unit-testable | Simulator: tap score bar, drag between detents, dismiss both ways |
| Sheet does not reappear at next round start | D-05 / pitfall | Presentation state interplay with fullScreenCover | Open sheet, let timer expire, start next round |
| VoiceOver button label + hint | D-02 | Accessibility Inspector | Inspect score bar element |
| Pangram visual parity with MissedWordsView | D-14 | Visual | Compare `#Preview`s |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
