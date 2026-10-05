---
phase: 11-first-launch-tutorial
verified: 2026-10-04T00:00:00Z
status: passed
score: 7/7 requirements verified
---

# Phase 11: First-Launch Tutorial Verification Report

**Phase Goal:** First-time-user tutorial teaching core mechanics, with a seen flag and format decision (scripted practice puzzle with banner).
**Status:** passed. **Re-verification:** No.

## Observable Truths / Requirements

| Req | Status | Evidence |
| --- | ------ | -------- |
| TUT-01 scripted DOLPHIN/P practice, guided steps | VERIFIED | PracticePuzzle.swift, TutorialStep.swift (9 steps), TutorialController.swift (288 lines), PracticePuzzleTests and TutorialControllerTests, TutorialUITests walk 9 steps |
| TUT-02 free and unrecorded | VERIFIED | Controller builds practice GameViewModel with persistenceStore nil; controller test asserts nothing is recorded |
| TUT-03 auto-show only for new install; interruption restarts | VERIFIED | TutorialFlag.shouldShowOnLaunch(hasHistory:) wired in WordPuzzleApp.swift:80; PersistenceStore.hasAnyHistory; TutorialLaunchGateTests; markSeen only on finish/skip |
| TUT-04 Skip always visible; Finish starts real puzzle | VERIFIED | TutorialBannerView skip link; tutorial.onExit hand-off in WordPuzzleApp.swift:73; UI tests for skip and finish |
| TUT-05 Settings "How to Play" replay | VERIFIED | SettingsView row, GameView pendingHowToPlay then onHowToPlay, ContentView begin(mode: .replay); UI replay test |
| TUT-06 AX5, Reduce Motion, VoiceOver | VERIFIED | TutorialHighlight uses OverflowGlow.pulse with reduce-motion handling; banner AX compact layout; AX5 collapse bug found and fixed on iPhone 17e (2222b26); announcements wired in GameView |
| TUT-07 existing UI tests and screenshots keep passing | VERIFIED | Existing UI test launches pass -hasSeenTutorial YES; per supplied evidence UI suites 7/7 and screenshot test passed |

All must_haves artifacts from plans 11-01 to 11-06 exist, are substantive, and are wired (ContentView root switch with `.environment(tutorial.practice)`, GameView takes tutorial, Settings closure).

## Behavioral Spot-Checks

`xcodebuild test -only-testing:WordPuzzleTests` re-run: `** TEST SUCCEEDED **`. Supplied evidence: 250 unit tests, TutorialUITests 3/3, existing UI 7/7, screenshot test and compliance guards pass.

## Anti-Patterns

None found (no TODO/FIXME in Tutorial/).

## Human Verification

On-device feel check already completed and approved by the player (11-06-SUMMARY.md). None outstanding.

## Notes

Pre-existing AX5 clip of score card/Finish Round on iPhone 17e is out of scope (not covered by a TUT requirement). No orphaned requirements: TUT-01..07 all claimed by plans and mapped in REQUIREMENTS.md.
