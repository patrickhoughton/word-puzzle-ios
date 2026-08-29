---
phase: 03-core-game-ui
plan: 04
subsystem: ui
tags: [swiftui, app-wiring, storekit-removal, swift-testing]

# Dependency graph
requires:
  - phase: 03-01
    provides: GameViewModel round state machine, GameTheme design tokens
  - phase: 03-02
    provides: LetterGridView (hex grid, unified gesture)
  - phase: 03-03
    provides: WordDisplayView, ScoreBarView, MissedWordsView (presentation-only components)
provides:
  - GameView — the top-level playable game screen composing all four Phase 3 child views around GameViewModel
  - WordPuzzleApp instantiates WordList and GameViewModel sharing the same instances, loads the word list, and starts the first round at launch
  - ContentView reduced to a thin GameView wrapper; Phase 2 EntitlementDebugPanel deleted entirely
  - AppWiringTests.testGameViewModelStartsARoundFromLoadedWordList — end-to-end launch-path regression coverage
affects: [03-05 (final wiring/polish), Phase 4 (paywall — replaces EntitlementDebugPanel's purchase/restore affordances)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GameView is the ONLY view permitted to reference GameViewModel — enforced by grep verification (`grep -rn GameViewModel WordPuzzle/WordPuzzle/Game/Views/` matches only GameView.swift)"
    - "App-root .task blocks: one for entitlement refresh (Phase 2), one for word-list load + first round start (Phase 3) — kept as two separate .task modifiers rather than merged, since they are independent concerns"
    - "Round-over state is read directly from GameViewModel.roundPhase via a .constant(...) Binding in .fullScreenCover — no duplicate @State mirrors view-model state"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift
  modified:
    - WordPuzzle/WordPuzzle/WordPuzzleApp.swift
    - WordPuzzle/WordPuzzle/ContentView.swift
    - WordPuzzle/WordPuzzleTests/AppWiringTests.swift

key-decisions:
  - "Declared @State private var wordList: WordList without a default value (assigned only in init, same pattern already used for gameViewModel) to avoid constructing two WordList instances — the plan's own example code textually constructed WordList() twice, which would have failed its own acceptance grep (`grep -c \"WordList()\"` expected to return 1)"
  - "AppWiringTests suite marked @Suite(.serialized) since the new test loads the full ~173K-word ENABLE list, matching the project's established convention for word-list-loading test suites (Phase 01 decision)"

patterns-established:
  - "Pattern: app root constructs shared service instances as locals in init() (`let list = WordList()`), then assigns both the @State backing storage (`_wordList = State(initialValue: list)`) and any dependent service's constructor (`GameViewModel(wordList: list, ...)`) from the same local — guarantees the environment-injected instance and the view-model's dependency are identical, never two separate objects"

requirements-completed: [GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03]

# Metrics
duration: ~12min
completed: 2026-08-29
---

# Phase 03 Plan 04: GameView Assembly and App Wiring Summary

**GameView composes ScoreBar/WordDisplay/LetterGrid/control-row/MissedWords around GameViewModel; WordPuzzleApp now instantiates and loads WordList and starts the first round at launch; the Phase 2 EntitlementDebugPanel and "Hello, world!" placeholder are gone — the app launches straight into a playable round.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-08-29
- **Tasks:** 2 completed
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- `GameView` assembles the full Phase 3 screen: `ScoreBarView` → `WordDisplayView` → `LetterGridView` → Shuffle/Delete/Finish Round control row, plus a `fullScreenCover` presenting `MissedWordsView` when `roundPhase == .roundOver`
- `WordPuzzleApp` now owns a shared `WordList` + `GameViewModel` pair (same instances injected via `.environment()` and passed into `GameViewModel.init`), loads the word list asynchronously, and calls `startNewRound()` once loaded
- `ContentView` reduced to a one-line `GameView()` wrapper; the entire `EntitlementDebugPanel` type (and its `import StoreKit`) and the placeholder "Hello, world!" view are deleted
- `AppWiringTests` gained `testGameViewModelStartsARoundFromLoadedWordList`, proving the exact launch sequence (`WordList().load()` → `GameViewModel.startNewRound()`) produces a playable round with 6 outer letters, a center letter excluded from them, ≥20 valid words, a positive max score, and `RankTier.novice`
- Full test suite: 46 tests across 10 suites, 0 failures. The previously-flagged `testLaunchPerformance` passed cleanly in isolation this run. 3 of `EntitlementStoreTests`'s 5 tests (`testClearingTransactionsRevokesPremium`, `testPurchaseUnlocksPremium`, `testRestoreUnlocksPremiumAfterFreshInstall`) were programmatically **skipped**, not passed — pre-existing SKTestSession `SKInternalErrorDomain Code=3` Simulator bug logged since plan 02-04, unrelated to this plan's changes (see 02-04-SUMMARY.md); the other 2 `EntitlementStoreTests` ran and passed normally

## Task Commits

Each task was committed atomically:

1. **Task 1: GameView — compose the full playable screen** - `fb26a05` (feat)
2. **Task 2: Wire WordList + GameViewModel into the app root and delete EntitlementDebugPanel** - `a27c21d` (feat)

**Plan metadata:** (this commit, docs — see final commit below)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` - Top-level game screen; the only view that reads `GameViewModel` from the environment
- `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` - Instantiates `WordList`/`GameViewModel` sharing instances with `.environment()`, loads the word list and starts the first round in a `.task`
- `WordPuzzle/WordPuzzle/ContentView.swift` - Thin `GameView()` wrapper; `EntitlementDebugPanel` deleted
- `WordPuzzle/WordPuzzleTests/AppWiringTests.swift` - Added end-to-end launch-path test; suite marked `.serialized`

## Decisions Made
- Removed the default-value initializer on the `wordList` `@State` property (`WordList()` inline default) in favor of declaring it without a default and assigning it only inside `init()` — identical to the pattern already used for `gameViewModel`. The plan's literal example code declared `@State private var wordList = WordList()` AND separately did `let list = WordList()` / `_wordList = State(initialValue: list)` in `init()`, which constructs two `WordList` instances (one immediately discarded) and would have made the plan's own acceptance check `grep -c "WordList()"` return 2 instead of the required 1. Fixed per Deviation Rule 1 (auto-fix bug: the plan's own code contradicted its own verification gate).
- No other deviations — Task 1 and Task 2 otherwise followed the plan's code blocks verbatim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed self-contradictory `WordList()` construction count in the plan's own template code**
- **Found during:** Task 2 acceptance-criteria verification
- **Issue:** The plan's literal `WordPuzzleApp.swift` example declared `@State private var wordList = WordList()` as a property default AND constructed a second `let list = WordList()` inside `init()` to assign via `_wordList = State(initialValue: list)`. This produces two `WordList()` textual construction sites (and one wastefully-constructed, immediately-discarded instance at runtime), while the plan's own acceptance criteria required `grep -c "WordList()" WordPuzzle/WordPuzzle/WordPuzzleApp.swift` to return exactly 1.
- **Fix:** Declared `@State private var wordList: WordList` with no default value, matching the already-present pattern for `@State private var gameViewModel: GameViewModel`. The single construction (`let list = WordList()` in `init()`) is now the only site, and it is assigned to both `_wordList` and passed into `GameViewModel.init(wordList:)`.
- **Files modified:** `WordPuzzle/WordPuzzle/WordPuzzleApp.swift`
- **Verification:** `grep -c "WordList()" WordPuzzle/WordPuzzle/WordPuzzleApp.swift` returns 1; `xcodebuild build` exits 0; full test suite (46 tests, 10 suites) passes with 0 failures.
- **Committed in:** `a27c21d` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Cosmetic/structural fix only — removes a redundant object construction, no behavior change, brings the file in line with the plan's own verification gate. No scope creep.

## Issues Encountered

None beyond the deviation above. The worktree was already fast-forwarded to `main` (containing plans 03-01/03-02/03-03) before this session started, so no merge was needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The app now launches into a fully playable round: word list loads, a puzzle generates, letters render, words submit, score/rank update, Finish Round shows the missed-words reveal, and dismissing it starts a new puzzle immediately (D-12) — this is the Phase 3 ROADMAP goal made observable.
- `EntitlementDebugPanel` is fully removed from the codebase; Phase 4's paywall will need its own purchase/restore UI (StoreKit-side `EntitlementStore` API is untouched and still frozen from Phase 2).
- Plan 03-05 (final wiring/polish, per the phase's plan list) can proceed — no blockers identified.

---
*Phase: 03-core-game-ui*
*Completed: 2026-08-29*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Game/Views/GameView.swift
- FOUND: WordPuzzle/WordPuzzle/WordPuzzleApp.swift
- FOUND: WordPuzzle/WordPuzzle/ContentView.swift
- FOUND: WordPuzzle/WordPuzzleTests/AppWiringTests.swift
- FOUND: fb26a05 (feat(03-04): add GameView composing the playable game screen)
- FOUND: a27c21d (feat(03-04): wire WordList and GameViewModel into app root, delete debug panel)
