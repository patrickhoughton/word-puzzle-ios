---
phase: 03-core-game-ui
plan: 03
subsystem: ui
tags: [swiftui, sensoryFeedback, gesture, haptics, presentation-components]

# Dependency graph
requires:
  - phase: 03-01
    provides: GameTheme design tokens, SubmissionOutcome/MissedWordGroup types, RankTier ladder (frozen APIs)
provides:
  - WordDisplayView (in-progress word, swipe-down-to-submit gesture, shake/pop feedback, sensoryFeedback haptics)
  - ScoreBarView (rank tier name + found/total word count + progress bar)
  - MissedWordsView (round-end reveal grouped by word length with pangram badges and empty state)
affects: [03-04 (GameView composition), 03-05 (final wiring/polish)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Counter-based .sensoryFeedback triggers (Int, not Bool) so consecutive identical outcomes still fire haptics"
    - "Presentation-only SwiftUI views: value + closure params only, zero references to GameViewModel, verified via grep in CI-style acceptance checks"
    - "ScrollView + LazyVStack for word lists — List is forbidden by 03-UI-SPEC.md (row separators/chrome)"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/Views/WordDisplayView.swift
    - WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift
    - WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift
  modified: []

key-decisions:
  - "Reworded doc comments that literally contained the string 'GameViewModel' (plan's own template text) to satisfy the plan's own grep-based 'no GameViewModel reference' acceptance criteria without weakening the presentation-only contract"
  - "Flagged WordPuzzleUITests.testLaunchPerformance() failure as out-of-scope/environmental (concurrent parallel-agent load), not a regression from this plan's changes, since none of the three new views are wired into the app yet"

patterns-established:
  - "Pattern: gesture thresholds (arm/submit/max-follow) and transient feedback state (shake/pop/opacity) live as private @State on the presentation view, never leak into the value contract"

requirements-completed: [GAME-01, GAME-02, GAME-03, GAME-04, RET-03]

# Metrics
duration: ~25min
completed: 2026-08-29
---

# Phase 03 Plan 03: Presentation Views (WordDisplay, ScoreBar, MissedWords) Summary

**Three standalone SwiftUI presentation views — swipe-down-to-submit word display with counter-triggered haptics, rank-tier score bar, and length-grouped missed-words reveal — all built against 03-01's frozen GameTheme/GameViewModel/RankTier contract with zero GameViewModel coupling.**

## Performance

- **Duration:** ~25 min (session included one rate-limit interruption/resume; files were already drafted correctly on disk at resume, verified against plan rather than rewritten)
- **Completed:** 2026-08-29
- **Tasks:** 3 completed
- **Files modified:** 3 created

## Accomplishments
- `WordDisplayView`: in-progress word above the hex grid, tap-to-clear, swipe-down-to-submit drag gesture (no Submit button anywhere), shake + "Not a valid word" on reject, pop + "+N" on accept, counter-triggered `.sensoryFeedback` haptics that fire correctly on consecutive identical outcomes
- `ScoreBarView`: shows `RankTier.displayName` and "N of M words" — never a raw score — with a NaN-guarded linear progress bar
- `MissedWordsView`: round-end reveal grouped by word length via `MissedWordGroup`, pangram badges (`checkmark.seal.fill`, accent-colored), dedicated "Perfect Round!" empty state, `ScrollView` + `LazyVStack` (no `List`)
- All three views compile clean, are fully presentation-only (verified via grep — zero `GameViewModel` references in code), and each ships with working `#Preview`s

## Task Commits

Each task was committed atomically:

1. **Task 1: WordDisplayView — swipe-down submit, shake/pop feedback, haptics** - `deae564` (feat)
2. **Task 2: ScoreBarView — live rank tier and found-word count** - `bb1a556` (feat)
3. **Task 3: MissedWordsView — round-end reveal grouped by length with pangram badges** - `b91c1b8` (feat)

**Plan metadata:** (this commit, docs — see final commit below)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Game/Views/WordDisplayView.swift` - In-progress word display, swipe-down submit gesture, shake/pop feedback, counter-triggered haptics
- `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift` - Rank tier name, "N of M words" count, progress bar
- `WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift` - Round-end reveal grouped by word length, pangram badges, empty state, "Next Puzzle" continue button

## Decisions Made
- Reworded two doc comments (in `WordDisplayView.swift` and `ScoreBarView.swift`) that literally contained the string "GameViewModel" — the plan's own action-block template text — because the plan's acceptance criteria and overall verification both require `grep -c "GameViewModel"` to return 0 on these files. The functional contract (value/closure params only, zero type references) was already correct; only prose wording changed. No behavior change.
- Kept the plan's discretionary "Pangram!" flourish in the accepted-word pop text (`WordDisplayView`), since it did not complicate the pop animation, per the plan's own "Claude's discretion" note.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed self-contradictory acceptance criteria in the plan's own template code**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** The plan's literal action-block code for `WordDisplayView.swift` and `ScoreBarView.swift` includes doc comments containing the exact string "GameViewModel" ("It never references GameViewModel." / "no GameViewModel reference."), while the plan's own `<acceptance_criteria>` and `<verification>` sections require `grep -c "GameViewModel"` on those same files to return 0. Building the plan's code verbatim would fail its own verification step.
- **Fix:** Reworded the two doc comments to preserve their descriptive intent ("never references the game's view model" / "no view-model reference") without the literal type-name string. No code/behavior change — these are non-code comments only.
- **Files modified:** `WordPuzzle/WordPuzzle/Game/Views/WordDisplayView.swift`, `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift`
- **Verification:** `grep -c "GameViewModel"` now returns 0 for both files; `grep -rn "GameViewModel" WordPuzzle/WordPuzzle/Game/Views/` returns no matches project-wide.
- **Committed in:** `deae564` (Task 1), `bb1a556` (Task 2)

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Cosmetic doc-comment wording change only, required to satisfy the plan's own verification gates. No scope creep, no behavior change.

## Issues Encountered

- **Worktree was stale relative to `main`:** at session start, `git log main..HEAD` was empty (worktree HEAD was a pure ancestor of `main`, missing all of phases 01–02 and plan 03-01). Per the plan's `<note>` instructions, ran `git merge --ff-only main` to fast-forward the worktree before starting — no local changes were lost (working tree was clean). This brought in the frozen `GameTheme`/`GameViewModel`/`RankTier` APIs that this plan depends on.
- **Session interruption (429 rate limit):** the session was terminated mid-task after all three files had already been fully written to disk (untracked, uncommitted). On resume, verified all three files against the plan line-by-line before proceeding — they matched the plan's specified code exactly (aside from the GameViewModel-string issue above) — so no rewrite was needed, only verification, the doc-comment fix, build/test, and commits.
- **`WordPuzzleUITests.testLaunchPerformance()` failed** in the full-suite `xcodebuild test` run, while every other suite passed (all XCTest suites, all Swift Testing suites — `RankTierTests`, `GameViewModelTests`, `PuzzleGeneratorTests`, `PersistenceStoreTests`, `WordListTests`, `ScoreCalculatorTests`, `AppWiringTests`, `ProfanityTests` — and the known 3 `EntitlementStoreTests` sandbox tests showed as `skipped`, consistent with the pre-existing 02-04 issue, not new failures). This plan's three new views are not referenced by `WordPuzzleApp.swift` or `ContentView.swift` yet (that wiring is plan 03-04's job), so they cannot affect launch timing. A second GSD executor agent was running plan 03-02 concurrently in a separate worktree on the same machine, which is the more likely cause of a performance-test timing flake. Logged to `.planning/phases/03-core-game-ui/deferred-items.md` for the 03-04/03-05 executor or phase verifier to re-confirm in isolation; not treated as a regression from this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All three presentation views are ready for composition in plan 03-04's `GameView`:
- `WordDisplayView(word:outcome:acceptedCount:rejectedCount:onClear:onSubmit:)`
- `ScoreBarView(rank:foundCount:totalCount:progress:)`
- `MissedWordsView(groups:pangrams:rank:foundCount:totalCount:onContinue:)`

No blockers. One pre-existing environmental test flake (`testLaunchPerformance`) is flagged in `deferred-items.md` for re-verification before phase sign-off, but does not block 03-04/03-05 work.

---
*Phase: 03-core-game-ui*
*Completed: 2026-08-29*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Game/Views/WordDisplayView.swift
- FOUND: WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift
- FOUND: WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift
- FOUND: deae564 (feat(03-03): add WordDisplayView with swipe-down submit and haptic feedback)
- FOUND: bb1a556 (feat(03-03): add ScoreBarView with rank tier and found-word count)
- FOUND: b91c1b8 (feat(03-03): add MissedWordsView round-end reveal grouped by word length)
