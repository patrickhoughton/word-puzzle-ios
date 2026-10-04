---
phase: 06-differentiated-invalid-word-messaging
verified: 2026-10-04T19:05:00Z
status: passed
score: 12/12 must-haves verified
---

# Phase 6: Differentiated Invalid-Word Messaging Verification Report

**Phase Goal:** Replace the single generic "Not a valid word" rejection with distinct feedback per reason (too short, not a word, already found; plus missing center letter).
**Status:** passed (on-device human verification already approved at the 06-02 checkpoint)
**Re-verification:** No

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | tooShort / missingCenterLetter / alreadyFound / notAWord each reported | VERIFIED | `GameViewModel.swift` lines 203-207 ordered guards, each calling `reject(reason)` |
| 2 | Precedence tooShort, missingCenter, outside letter, alreadyFound, dictionary | VERIFIED | Same lines, in that order |
| 3 | Duplicate leaves score, foundWords, acceptedCount unchanged | VERIFIED | Reject happens before the mutation block (209-216); test at GameViewModelTests ~245 |
| 4 | Fixed strings, no interpolation | VERIFIED | `RejectionReason.message` switch, with the four exact CONTEXT strings |
| 5 | `forRejection` is nil for alreadyFound, `.wordRejected` otherwise | VERIFIED | `SoundManager.swift:23-28`; SoundManagerTests lines 85, 90 |
| 6 | View shows reason.message | VERIFIED | `WordDisplayView.showRejectedFeedback` sets `feedbackText = reason.message` |
| 7 | Duplicate: neutral secondary color, no shake, light haptic, no sound | VERIFIED | `.neutral` style uses `Color.secondary`; early return before shake; `UIImpactFeedbackGenerator(.light)`; GameView guard on `forRejection` |
| 8 | Other reasons keep shake, double heavy haptic, sound, error color | VERIFIED | `WordDisplayView` error path; GameView plays `.wordRejected` |
| 9 | Two identical consecutive rejections both produce feedback | VERIFIED | `rejectedSubmissionCount` is a counter that increments on every reject; the `feedbackToken` guards the timers |
| 10 | Longest message does not truncate at large Dynamic Type | VERIFIED (code and human check) | Body font with `lineLimit(1)` and `minimumScaleFactor(0.7)`; wording and display confirmed on-device |
| 11 | No "Not a valid word" string remains | VERIFIED | Message source is solely `RejectionReason.message` |
| 12 | Tests pass | VERIFIED | Reran GameViewModelTests and SoundManagerTests: TEST SUCCEEDED |

**Score:** 12/12

## Key Links

| From | To | Status |
|------|----|--------|
| `GameViewModel.reject` | `lastOutcome` then counter | WIRED (outcome set before the counter bump) |
| `GameView` onChange(rejectedSubmissionCount) | `SoundEffect.forRejection` | WIRED |
| `WordDisplayView` | `outcome` and `rejectedCount` | WIRED |

## Decision Coverage (CONTEXT IDs)

| ID | Plan | Status | Evidence |
|----|------|--------|----------|
| D-01 | 06-01 | SATISFIED | Four-case `RejectionReason`; outside letter folded into `.notAWord` |
| D-02 | 06-01 | SATISFIED | `.rejected(RejectionReason)`; per-reason tests |
| D-03 | 06-01, 06-02 | SATISFIED | Exact strings |
| D-04 | 06-01, 06-02 | SATISFIED | No interpolation; scalable font |
| D-05 | 06-01, 06-02 | SATISFIED | Gentle duplicate feedback |
| D-06 | 06-02 | SATISFIED | Full feedback preserved for the other three |
| D-07 | 06-01 | SATISFIED | Guard order; note a test case covers the ordering |

All seven IDs are accounted for in plan frontmatter. No orphans.

## Anti-Patterns

None blocking. Stub scan of the modified files found no TODO or placeholder code.

## Notes

- Minor: the Dynamic Type claim rests on `minimumScaleFactor(0.7)` on one line, so extreme sizes could still clip. The on-device check was approved.
- Known unrelated flake: `WordListTests.testWordSetLookupIsO1` (timing).

_Verified: 2026-10-04_
_Verifier: Claude (gsd-verifier)_
