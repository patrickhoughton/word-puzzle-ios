---
phase: 04-paywall-free-tier-gate
plan: 02
subsystem: game-viewmodel
tags: [swiftui, observable, gating, storekit-adjacent, testing]

# Dependency graph
requires:
  - phase: 04-paywall-free-tier-gate
    plan: 01
    provides: "recordRoundStarted() and RoundStartRecord-backed puzzlesPlayedToday() on PersistenceStore"
provides:
  - "RoundPhase.paywalled case and GameViewModel.freePuzzlesPerDay = 3 single source of truth"
  - "requestNextRound(isPremium:) — the single funnel both paywall trigger points (Next Puzzle, launch) must call"
  - "startNewRound(with:) round-start side effect, making abandoned rounds consume a free puzzle (D-02)"
  - "Single sequenced WordPuzzleApp launch .task with entitlement refresh guaranteed before the gate decision"
affects: [04-03, 04-04, paywall-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "requestNextRound(isPremium:) is a discrete decision point, not a derived/reactive boolean — avoids pre-empting round 3's own missed-words recap the instant the 3rd round starts"
    - "isPremium passed as a parameter rather than injecting EntitlementStore, keeping GameViewModel decoupled from StoreKit types"

key-files:
  created: []
  modified:
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzle/WordPuzzleApp.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
    - WordPuzzle/WordPuzzleTests/AppWiringTests.swift

key-decisions:
  - "requestNextRound(isPremium:) is the ONLY place that decides whether a new round may begin — both the post-finish 'Next Puzzle' trigger and the launch-time gate check funnel through it"
  - "recordRoundStarted() is called as the FIRST statement inside startNewRound(with:), not inside the wordList.isLoaded-guarded startNewRound(), so bailing out to .loading never over-records"
  - "WordPuzzleApp's two separate .task modifiers were merged into one sequenced task (refreshEntitlements -> loadProduct -> wordList.load -> requestNextRound) to eliminate a race where a premium user could be paywalled because isPremium was still at its default false"
  - "[Rule 3 - blocking issue] GameView.swift's switch over RoundPhase became non-exhaustive the moment .paywalled was added, which failed the build entirely. Added a minimal `case .paywalled: EmptyView()` placeholder — the plan's own verification step 3 (expecting GameView.swift untouched) was based on an incorrect assumption; the real paywall screen is still plan 04-03's responsibility"

requirements-completed: [MON-01]

# Metrics
duration: ~15min
completed: 2026-08-31
---

# Phase 4 Plan 2: Paywall Gate & Launch Sequencing Summary

**Single `requestNextRound(isPremium:)` decision funnel plus a round-start side effect and a sequenced launch task, so free users are paywalled on the 4th round start (not the 3rd) and premium users are never paywalled by a launch-time race.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2
- **Files modified:** 5 (0 created, 5 modified — 1 outside the plan's declared file list, see Deviations)

## Accomplishments
- `GameViewModel.RoundPhase` gains `.paywalled`; `GameViewModel.freePuzzlesPerDay = 3` is the single source of truth for the daily limit
- `requestNextRound(isPremium:)` is the sole gate-check funnel: premium always plays, free users below the limit play, free users at/above the limit are paywalled without starting a round (count does not move)
- `startNewRound(with:)` now calls `persistenceStore?.recordRoundStarted()` first, so an abandoned round still consumes a free puzzle — deliberately not tied to ScenePhase/background notifications, which are not guaranteed to fire before a hard kill
- `WordPuzzleApp` collapsed from two independent `.task` modifiers to one sequenced task, guaranteeing `entitlementStore.isPremium` is authoritative before the launch-time gate decision runs
- 8 new unit tests (4 in `GameViewModelTests`, 1 new + 1 updated in `AppWiringTests`) cover both `requestNextRound` branches, the round-start side effect, and the launch-time paywall path

## Task Commits

Each task was committed atomically:

1. **Task 1: Add RoundPhase.paywalled, freePuzzlesPerDay, requestNextRound(isPremium:), and the round-start side effect** - `b44ab0c` (feat)
2. **Task 2: Sequence WordPuzzleApp's launch tasks so the entitlement check precedes the launch-time gate decision** - `090763d` (feat)

**Plan metadata:** (this commit, pending)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` - Adds `.paywalled` case, `freePuzzlesPerDay`, `requestNextRound(isPremium:)`; `startNewRound(with:)` gains the `recordRoundStarted()` side effect
- `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` - Two `.task` modifiers merged into one sequenced task ending in `gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium)`
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` - Minimal `.paywalled` placeholder case (`EmptyView()`) added to keep the exhaustive `switch` compiling; not in the plan's declared file list (see Deviations)
- `WordPuzzle/WordPuzzleTests/GameViewModelTests.swift` - 4 new tests: round-start-without-game-record, paywall-at-limit, premium-bypasses-limit, allowed-below-limit
- `WordPuzzle/WordPuzzleTests/AppWiringTests.swift` - `testGameViewModelStartsARoundFromLoadedWordList` updated to call `requestNextRound(isPremium: false)`; new `testLaunchGatePaywallsFreeUserAlreadyAtDailyLimit` covers the launch-time `.paywalled` path for free vs. premium

## Decisions Made
- See `key-decisions` in frontmatter. Three decisions were specified by the plan itself; one (the GameView.swift fix) was an auto-fix for a blocking compile error the plan did not anticipate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] GameView.swift's switch over RoundPhase became non-exhaustive**
- **Found during:** Task 1, first verification run (`xcodebuild test`)
- **Issue:** Adding `RoundPhase.paywalled` made the existing `switch viewModel.roundPhase { case .loading: ...; case .playing, .roundOver: ... }` in `GameView.swift` non-exhaustive, failing the build with `switch must be exhaustive`. The plan's own overall `<verification>` step 3 expected `GameView.swift` to remain completely untouched (it is plan 04-03's file), but that expectation did not account for the new enum case breaking compilation.
- **Fix:** Added a minimal `case .paywalled: EmptyView()` placeholder with a comment noting plan 04-03 builds the real paywall screen. No other line of `GameView.swift` was touched.
- **Files modified:** `WordPuzzle/WordPuzzle/Game/Views/GameView.swift`
- **Commit:** `b44ab0c`

## Issues Encountered

None beyond the GameView.swift blocking fix above. Both tasks' `xcodebuild test` verification runs passed after that fix (14/14 tests in Task 1's suite, 19/19 across both suites in Task 2). Full project test suite (56 tests, 10 suites) passes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `requestNextRound(isPremium:)` is ready for plan 04-03 to wire into the "Next Puzzle" button after `MissedWordsView`'s `onContinue` closure (currently still calls `viewModel.startNewRound()` directly in `GameView.swift` — that trigger point is unchanged by this plan and is explicitly plan 04-03's scope per the plan's `<interfaces>`).
- The real `.paywalled` screen (paywall UI, purchase button, restore, stats block, countdown) is still entirely unbuilt — `GameView.swift` currently renders `EmptyView()` for that phase. Plan 04-03 must replace this placeholder.
- No blockers.

---
*Phase: 04-paywall-free-tier-gate*
*Completed: 2026-08-31*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Game/GameViewModel.swift
- FOUND: WordPuzzle/WordPuzzle/WordPuzzleApp.swift
- FOUND: WordPuzzle/WordPuzzle/Game/Views/GameView.swift
- FOUND: WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
- FOUND: WordPuzzle/WordPuzzleTests/AppWiringTests.swift
- FOUND commit: b44ab0c
- FOUND commit: 090763d
