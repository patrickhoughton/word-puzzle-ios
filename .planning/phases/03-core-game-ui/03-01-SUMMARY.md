---
phase: 03-core-game-ui
plan: 01
subsystem: game-logic
tags: [swiftui, observation, swift-testing, mvvm, game-engine]

# Dependency graph
requires:
  - phase: 01-word-engine-puzzle-generation
    provides: "Puzzle model, generatePuzzle(from:), WordList.contains(_:)"
  - phase: 02-persistence-entitlements
    provides: "PersistenceStore.record(score:wordsFoundCount:), ScoreCalculator"
provides:
  - "GameTheme design-token enum (spacing, geometry, typography, color, motion)"
  - "RankTier 10-tier percentage-of-max rank lookup (D-09, App Store 4.3 clone-risk avoidance)"
  - "GameViewModel: frozen @MainActor @Observable round state machine API for plans 03-02/03-03/03-04"
  - "#F5B800 honeycomb-gold AccentColor asset"
affects: [03-02, 03-03, 03-04, 03-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@Observable final class GameViewModel follows established WordList/PersistenceStore/EntitlementStore service convention"
    - "Monotonic Int counters (acceptedSubmissionCount/rejectedSubmissionCount) for .sensoryFeedback(_:trigger:) instead of re-settable Bools"
    - "startNewRound(with puzzle:) test seam separates deterministic testing from the wordList-driven startNewRound() production path"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/GameTheme.swift
    - WordPuzzle/WordPuzzle/Game/RankTier.swift
    - WordPuzzle/WordPuzzle/Game/GameViewModel.swift
    - WordPuzzle/WordPuzzleTests/RankTierTests.swift
    - WordPuzzle/WordPuzzleTests/GameViewModelTests.swift
  modified:
    - WordPuzzle/WordPuzzle/Assets.xcassets/AccentColor.colorset/Contents.json

key-decisions:
  - "GameViewModel submission validation mirrors PuzzleGenerator's private isValidPuzzleWord rule exactly (length >= 4, contains center, subset of letters) plus dictionary and duplicate checks, so the UI never rejects a word the generator counted as valid"
  - "finishRound() records the session via PersistenceStore BEFORE flipping roundPhase to .roundOver, so the missed-words screen always renders against already-persisted data"

patterns-established:
  - "GameTheme.swift is the single source of spacing/typography/color/geometry tokens for all Phase 3 views — no inline magic numbers"

requirements-completed: [GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03]

# Metrics
duration: ~15min
completed: 2026-08-29
---

# Phase 3 Plan 1: Game Logic Core (GameTheme, RankTier, GameViewModel) Summary

**GameViewModel round state machine with word submission validation, scoring, shuffle, and missed-word grouping, plus an original (non-NYT) 10-tier rank ladder and the design-token file every Phase 3 view will read from**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-08-29T14:30:00-05:00
- **Completed:** 2026-08-29T14:33:05-05:00
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- `GameTheme` enum centralizes every spacing/geometry/typography/color/motion token from `03-UI-SPEC.md`, and the app's `AccentColor` asset now resolves to `#F5B800` (honeycomb gold) so default-styled buttons pick up the tint automatically
- `RankTier` implements the locked D-09 10-tier ladder (Novice → Legend) as a percentage-of-max-score lookup with a divide-by-zero guard and round-down threshold math — verified against all 14 documented boundary cases
- `GameViewModel` is now the single frozen API surface (word building, submission validation, scoring, shuffle, missed-word grouping, round lifecycle) that plans 03-02, 03-03, and 03-04 build their views against without further exploration
- All Wave 0 test gaps listed in `03-VALIDATION.md` are closed: 5 `RankTierTests` + 10 `GameViewModelTests`, all green

## Task Commits

Each task was committed atomically:

1. **Task 1: GameTheme design tokens + honeycomb-gold accent color** - `10052e2` (feat)
2. **Task 2: RankTier — original 10-tier percentage-of-max lookup (D-09)** - `e92969f` (test, RED) → `80b3da8` (feat, GREEN)
3. **Task 3: GameViewModel — round state, validation, scoring, shuffle, missed words** - `40da82f` (test, RED) → `2c0a052` (feat, GREEN)

**Plan metadata:** (this commit, docs: complete plan)

_Note: TDD tasks (2, 3) each have two commits (test → feat); no refactor step was needed._

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Game/GameTheme.swift` - Spacing/geometry/typography/color/motion design tokens from 03-UI-SPEC.md
- `WordPuzzle/WordPuzzle/Assets.xcassets/AccentColor.colorset/Contents.json` - App-wide tint set to #F5B800 honeycomb gold
- `WordPuzzle/WordPuzzle/Game/RankTier.swift` - Original 10-tier rank enum + percentage-of-max lookup (D-09)
- `WordPuzzle/WordPuzzleTests/RankTierTests.swift` - 5 tests covering all tier boundaries, divide-by-zero guard, round-down thresholds, display names
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` - @MainActor @Observable round state machine: word building, submission validation, scoring, shuffle, missed-word grouping, round lifecycle
- `WordPuzzle/WordPuzzleTests/GameViewModelTests.swift` - 10 tests covering GAME-01..04, PUZZ-04, RET-03 proxy, duplicates, delete/clear, finish-round persistence, round reset

## Decisions Made
- None beyond what's captured in `key-decisions` above — plan's exact API and content were followed verbatim per its explicit "do not rename anything" instruction, since plans 03-02/03-03/03-04 are already written against these signatures.

## Deviations from Plan

None — plan executed exactly as written. The plan's task `<action>` blocks specified exact file contents; those were used verbatim, and both TDD tasks confirmed RED (compile failure referencing the not-yet-created type) before implementing GREEN.

## Issues Encountered

**Stale worktree required a fast-forward merge before execution could begin.** This agent's worktree (`worktree-agent-a73a6c94cc2ac75d6`) was checked out 64 commits behind `main` — before Phase 1, Phase 2, and Phase 3 planning artifacts existed, so `.planning/phases/03-core-game-ui/03-01-PLAN.md` and all Phase 1/2 source files (`WordPuzzle/`, `PuzzleEngine/`, `Services/`) were missing. Verified the worktree branch had zero commits of its own ahead of `main` (`git log --oneline main..HEAD` was empty), then ran `git merge --ff-only main` to bring the worktree current with no risk of losing local work. Execution proceeded normally after the fast-forward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `GameTheme`, `RankTier`, and `GameViewModel` form a frozen, fully-tested API contract. Plans 03-02 (hex grid + input), 03-03 (score/word-list UI), and 03-04 (missed-words/round-over screens) can build views directly against these names/signatures without exploring the codebase.
- Full project test suite (`xcodebuild test`, all destinations) passes: 40 Swift Testing tests across 9 suites + XCTest suites (EntitlementStoreTests with the 3 pre-existing SKTestSession skips from Phase 2, PerformanceTests, UI launch tests) — no regressions.
- No blockers for 03-02.

---
*Phase: 03-core-game-ui*
*Completed: 2026-08-29*

## Self-Check: PASSED

All created files verified present:
- FOUND: WordPuzzle/WordPuzzle/Game/GameTheme.swift
- FOUND: WordPuzzle/WordPuzzle/Game/RankTier.swift
- FOUND: WordPuzzle/WordPuzzle/Game/GameViewModel.swift
- FOUND: WordPuzzle/WordPuzzleTests/RankTierTests.swift
- FOUND: WordPuzzle/WordPuzzleTests/GameViewModelTests.swift

All task commits verified present in `git log`:
- FOUND: 10052e2, e92969f, 80b3da8, 40da82f, 2c0a052
