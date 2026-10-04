---
phase: 07-found-words-view
verified: 2026-10-04T20:00:00Z
status: passed
score: 17/17 decisions (D-01..D-17) verified
---

# Phase 7: Found Words View Verification Report

**Goal:** Player can see found words this round, grouped by length, via an in-round view opened from ScoreBarView.
**Status:** passed (device items human-approved in 07-03)

## Truths
| Decision | Status | Evidence |
|---|---|---|
| FW-ENTRY D-01..D-05 | VERIFIED | GameView wraps ScoreBarView in Button setting isShowingFoundWords; .sheet with detents [.medium,.large], drag indicator, Done button (onDone), chevron.right in ScoreBarView, a11y hint; flag reset on roundPhase != .playing. Modality/VoiceOver human-approved (07-03). |
| FW-DATA D-06, D-07, D-10, D-11 | VERIFIED | GameViewModel.foundWordGroups: totals from puzzle.validWords by length (zero-found lengths included), sorted ascending, found words sorted alphabetically. Tests pass. |
| FW-ROW D-08, D-09, D-12..D-15 | VERIFIED | FoundWordsView: MissedWordsView row styling, pangram accent + badge, "+N" via ScoreCalculator in view-model, header title/subtitle, completed-group checkmark; no pangram count line. |
| FW-EMPTY D-16 | VERIFIED | Nudge shown when foundCount == 0; all groups render at 0 of N; button available at all times during .playing. |
| FW-ISOLATION D-17 | VERIFIED | MissedWordsView.swift last changed in phase 03 commit; FoundWordsView is value-in/closure-out, no GameViewModel reads. |

## Spot-checks
xcodebuild test (iPhone 17 Pro) FoundWordsViewTests + GameViewModelTests: 33 tests passed, TEST SUCCEEDED.

## Anti-patterns
None found (no TODO/stubs; empty arrays only in previews/guards).

## Notes
Known unrelated flake: WordListTests.testWordSetLookupIsO1 under full-suite load.
