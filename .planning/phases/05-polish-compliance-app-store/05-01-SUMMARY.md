---
phase: 05-polish-compliance-app-store
plan: 01
subsystem: audio
tags: [avfoundation, avaudioplayer, avaudiosession, sound-effects, kenney, cc0]

# Dependency graph
requires:
  - phase: 03-core-game-ui
    provides: GameViewModel.RoundPhase and SubmissionOutcome enums this plan's mapping helpers switch over
provides:
  - Four CC0 WAV sound-effect assets bundled in the app (word_accepted, word_rejected, pangram_found, round_end)
  - SoundManager service (@MainActor singleton) with an AVAudioPlayer pool, an enabled/disabled gate, and preloadPlayers test seam
  - SoundEffect enum with forSubmission(accepted:isPangram:) and forRoundPhase(_:) mapping helpers
  - Frozen soundEffectsEnabledKey ("soundEffectsEnabled") for the future @AppStorage-backed Settings toggle
affects: [05-05 (Settings screen + GameView call sites), 05-02..05-08 (any plan touching audio feedback)]

# Tech tracking
tech-stack:
  added: [AVFoundation (AVAudioPlayer, AVAudioSession) -- native, no new SPM dependency]
  patterns:
    - "Cross-cutting services live in WordPuzzle/WordPuzzle/Services/ (SoundManager joins EntitlementStore, PersistenceStore, ScoreCalculator)"
    - "Test seam via constructor flag (preloadPlayers: Bool) to skip AVAudioSession/AVAudioPlayer setup in gate/mapping unit tests"
    - "Deterministic test hooks (lastAttemptedEffect, attemptedPlayCount) recorded before touching real playback APIs, so behavior is unit-testable without asserting on audio output"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Sounds/word_accepted.wav
    - WordPuzzle/WordPuzzle/Sounds/word_rejected.wav
    - WordPuzzle/WordPuzzle/Sounds/pangram_found.wav
    - WordPuzzle/WordPuzzle/Sounds/round_end.wav
    - WordPuzzle/WordPuzzle/Sounds/LICENSE.txt
    - WordPuzzle/WordPuzzle/Services/SoundManager.swift
    - WordPuzzle/WordPuzzleTests/SoundManagerTests.swift
  modified: []

key-decisions:
  - "Used Kenney 'Interface Sounds' pack (not 'UI Audio' as named in D-02's example) because its confirmation_*/error_*/maximize_* clip families map directly onto the four D-01 events; both are CC0 packs so this satisfies D-02's constraint"
  - "No source-clip substitution needed in step 3 -- all four converted files landed at exactly the plan's pre-verified byte sizes and durations (word_accepted 25608B/0.290s, word_rejected 12332B/0.139s, pangram_found 33556B/0.380s, round_end 43298B/0.490s), so the originally specified clips were kept"
  - "SoundManager.sessionCategory fixed at .ambient (never .playback) per RESEARCH Pitfall 3, so SFX respect the hardware silent switch"

patterns-established:
  - "Pattern: SFX events map through two pure static functions (forSubmission, forRoundPhase) rather than being decided ad-hoc at call sites -- plan 05-05's GameView call sites just pass GameViewModel state straight through"

requirements-completed: [UX-02]

# Metrics
duration: ~20min
completed: 2026-09-07
---

# Phase 05 Plan 01: Sound Effects Foundation Summary

**Four Kenney CC0 sound-effect WAVs bundled via the synchronized Xcode group, played through a new `SoundManager` service gated by an enabled flag and mapped from game events via two pure static functions.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-07T16:11:00Z (approx, first bash call)
- **Completed:** 2026-09-07T16:19:09Z
- **Tasks:** 2 completed
- **Files modified:** 7 (5 new assets, 1 new service, 1 new test file)

## Accomplishments
- Downloaded and verified the Kenney "Interface Sounds" CC0 pack (sha256 matched the plan's pre-verified hash exactly), converted 4 Ogg source clips to 44.1kHz mono 16-bit PCM WAV via Python `soundfile` (no ffmpeg/sox available on this machine)
- All 4 output files land under the 50KB cap and match the plan's pre-verified sizes/durations byte-for-byte, so no step-3 substitution was needed
- Implemented `SoundEffect` (4-case enum, `CaseIterable`) with `forSubmission(accepted:isPangram:)` and `forRoundPhase(_:)` mapping helpers matching the frozen interface contract
- Implemented `SoundManager` (`@MainActor` singleton) with an `AVAudioPlayer` pool preloaded from bundled resources, `.ambient` session category, and a `preloadPlayers: Bool` test seam
- 13 new `SoundManagerTests` (Swift Testing) cover the enabled gate, all mapping branches, static config, and bundled-resource lookup via `Bundle.main.url` -- proving Task 1's synchronized-group resource bundling actually worked, not just inspected by `ls`
- Full regression suite green: 72 tests across 12 Swift Testing suites + 2 XCTest suites (EntitlementStoreTests, PerformanceTests) + 6 UI tests, zero failures
- `project.pbxproj` was never touched -- the synchronized root group picked up `Sounds/` and the new `SoundManager.swift`/`SoundManagerTests.swift` files automatically

## Task Commits

Each task was committed atomically:

1. **Task 1: Download, convert and bundle the four Kenney SFX assets** - `f8bf0db` (chore)
2. **Task 2: Implement SoundManager with an enabled gate and a test seam** - `cfe7997` (test, RED) + `169b08c` (feat, GREEN)

**Plan metadata:** (pending final commit)

_Note: Task 2 used TDD -- RED (failing compile due to missing types) then GREEN (implementation). No REFACTOR commit needed; the GREEN implementation matched the plan's target shape on first pass except for the one-line deviation below._

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Sounds/word_accepted.wav` - 44.1kHz mono WAV, 0.290s, 25608 bytes (confirmation_001.ogg source)
- `WordPuzzle/WordPuzzle/Sounds/word_rejected.wav` - 44.1kHz mono WAV, 0.139s, 12332 bytes (error_008.ogg source)
- `WordPuzzle/WordPuzzle/Sounds/pangram_found.wav` - 44.1kHz mono WAV, 0.380s, 33556 bytes (maximize_006.ogg source)
- `WordPuzzle/WordPuzzle/Sounds/round_end.wav` - 44.1kHz mono WAV, 0.490s, 43298 bytes (confirmation_004.ogg source)
- `WordPuzzle/WordPuzzle/Sounds/LICENSE.txt` - CC0 attribution and source-clip mapping
- `WordPuzzle/WordPuzzle/Services/SoundManager.swift` - `SoundEffect` enum + `SoundManager` class (84 lines)
- `WordPuzzle/WordPuzzleTests/SoundManagerTests.swift` - 13 `@Test` functions covering the full `<behavior>` contract

## Decisions Made
- Kept the plan's originally specified source clips (confirmation_001, error_008, maximize_006, confirmation_004) -- converted output matched the plan's pre-verified sizes/durations exactly, so no audition-driven substitution (step 3) was needed
- `.ambient` session category confirmed as the correct choice per RESEARCH Pitfall 3 -- kept as specified

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's own sample code failed its own acceptance criterion**
- **Found during:** Task 2 (SoundManager implementation, GREEN step)
- **Issue:** The plan's `<action>` code block for `SoundManager.swift` includes a doc comment reading `Never `.playback` -- that deliberately overrides the silent switch.`, but the same task's acceptance criteria requires `grep -c '\.playback' WordPuzzle/WordPuzzle/Services/SoundManager.swift` to return `0`. Implementing the sample code verbatim would fail the plan's own gate.
- **Fix:** Reworded the comment to `Never use the category that deliberately overrides the silent switch.` -- same warning intent, no literal `.playback` token.
- **Files modified:** `WordPuzzle/WordPuzzle/Services/SoundManager.swift`
- **Verification:** `grep -c '\.playback' WordPuzzle/WordPuzzle/Services/SoundManager.swift` returns 0; all 13 SoundManagerTests still pass after the edit.
- **Committed in:** `169b08c` (Task 2 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 bug fix, plan-internal contradiction)
**Impact on plan:** Cosmetic-only fix to a doc comment; no behavior change. No scope creep.

## Issues Encountered
- This worktree's git branch (`worktree-agent-ac8fbe2c61ccac29f`) was 25 commits behind `main` at the start of execution -- it predated the phase 5 planning commits (`05-01-PLAN.md` through `05-08-PLAN.md` and supporting docs did not exist on this branch yet). Resolved with a fast-forward `git merge --ff-only main` before starting Task 1, since this worktree branch was a strict ancestor of `main` with no local divergence. No conflicts.
- First `xcodebuild test -only-testing:WordPuzzleTests/SoundManagerTests` run failed with an infrastructure error ("Early unexpected exit, operation never finished bootstrapping") unrelated to the code under test; a retry succeeded cleanly. Not a code defect -- consistent with the Simulator flakiness noted elsewhere in STATE.md's Blockers/Concerns for this dev machine.

## User Setup Required

None - no external service configuration required. Sound assets are CC0 and bundled locally; no App Store Connect or credential changes needed for this plan.

## Next Phase Readiness

- `SoundManager.shared`, `SoundEffect`, and the frozen `soundEffectsEnabledKey` string are ready for plan 05-05 to wire into `SettingsView`'s toggle and `GameView`'s four call sites (word accepted/rejected, pangram found, round end/paywall shown) exactly as specified in this plan's `<interfaces>` block -- no renaming needed.
- No blockers for subsequent Phase 5 plans (05-02 through 05-08 are independent per the plan's `depends_on: []` and `wave: 1`).

---
*Phase: 05-polish-compliance-app-store*
*Completed: 2026-09-07*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Sounds/word_accepted.wav
- FOUND: WordPuzzle/WordPuzzle/Sounds/word_rejected.wav
- FOUND: WordPuzzle/WordPuzzle/Sounds/pangram_found.wav
- FOUND: WordPuzzle/WordPuzzle/Sounds/round_end.wav
- FOUND: WordPuzzle/WordPuzzle/Sounds/LICENSE.txt
- FOUND: WordPuzzle/WordPuzzle/Services/SoundManager.swift
- FOUND: WordPuzzle/WordPuzzleTests/SoundManagerTests.swift
- FOUND commit: f8bf0db (chore, Task 1)
- FOUND commit: cfe7997 (test/RED, Task 2)
- FOUND commit: 169b08c (feat/GREEN, Task 2)
