---
phase: 05-polish-compliance-app-store
plan: 02
subsystem: ui
tags: [swiftui, dynamic-type, accessibility, scaledmetric, gametheme]

# Dependency graph
requires:
  - phase: 03-core-game-ui
    provides: "GameTheme design-token system and HexTileView hexagon geometry"
provides:
  - "GameTheme's four font tokens (displayFont/headingFont/bodyFont/labelFont) as Dynamic Type text styles instead of fixed point sizes"
  - "HexTileView.baseLetterSize / maxLetterSize / clampedLetterSize(scaled:) — a testable, clamped letter-size API for the honeycomb tiles"
affects: [05-04-compliance-guards, 05-06-manual-accessibility-verification]

# Tech tracking
tech-stack:
  added: []
  patterns: ["@ScaledMetric with a hard ceiling via min() for fixed-geometry components that must not overflow"]

key-files:
  created:
    - WordPuzzle/WordPuzzleTests/DynamicTypeTests.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/GameTheme.swift
    - WordPuzzle/WordPuzzle/Game/Views/HexTileView.swift

key-decisions:
  - "GameTheme's four font tokens keep their original names (displayFont/headingFont/bodyFont/labelFont) but now resolve to Font.largeTitle/.title3/.body/.footnote text styles, so zero call sites needed edits"
  - "HexTileView's letter size is the one sanctioned Font.system(size:) usage in the app — clamped to a 40pt ceiling via HexTileView.clampedLetterSize(scaled:) so the 70pt hexagon never overflows at AX1-AX5 Dynamic Type sizes"
  - "Wrote the font call as Font.system(size:...) (explicit type) rather than the equivalent .system(size:...) shorthand, so grep -rln \"Font.system(size:\" finds exactly one file — this is what plan 05-04's compliance-guards.sh whitelist will scan for"

patterns-established:
  - "Any future fixed-geometry component that must scale text uses @ScaledMetric(relativeTo:) plus a static min()-based clamp helper, unit-tested in isolation from the view (same pattern as HexFlowerLayout's extracted trigonometry)"

requirements-completed: [UX-03]

# Metrics
duration: 17min
completed: 2026-09-07
---

# Phase 5 Plan 02: Dynamic Type Typography Migration Summary

**Migrated all four GameTheme font tokens from fixed `Font.system(size:)` points to Dynamic Type text styles, and added a clamped `@ScaledMetric` letter size to HexTileView so the fixed 70pt hexagon never overflows at accessibility text sizes.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-09-07T11:01:22-05:00
- **Completed:** 2026-09-07T11:18:11-05:00
- **Tasks:** 2 completed
- **Files modified:** 3 (2 modified, 1 created)

## Accomplishments
- `GameTheme.displayFont/headingFont/bodyFont/labelFont` now resolve to `Font.largeTitle.weight(.semibold)` / `Font.title3.weight(.semibold)` / `Font.body` / `Font.footnote` — all four scale with the system Dynamic Type setting while rendering pixel-identically to Phase 3 at the default category.
- `HexTileView` now reads its letter size from a `@ScaledMetric(relativeTo: .largeTitle)` value clamped to a 40pt ceiling via `HexTileView.clampedLetterSize(scaled:)`, so the fixed 70pt hexagon can never clip even at AX5-magnitude text sizes.
- 9 new tests in `DynamicTypeTests.swift` pin the clamp math (pass-through below the ceiling, clamp at/above it, base/max invariants, headroom-inside-hexagon invariant).
- Full test suite (68 tests, 12 suites) passes with zero call-site changes required — all 28 existing `GameTheme.*` font references across `GameView`, `WordDisplayView`, `ScoreBarView`, `MissedWordsView`, `PaywallView` kept compiling untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace GameTheme's fixed-point fonts with Dynamic Type text styles** - `7902283` (feat)
2. **Task 2: Clamp HexTileView's letter size and pin the clamp with tests** - `3a616d0` (feat, tdd)

**Plan metadata:** (this commit, following)

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Game/GameTheme.swift` - Typography section replaced with 4 Dynamic Type text-style tokens; doc comment explains the UX-03/D-04 rationale
- `WordPuzzle/WordPuzzle/Game/Views/HexTileView.swift` - Letter font now driven by a clamped `@ScaledMetric` value; added `baseLetterSize`/`maxLetterSize`/`clampedLetterSize(scaled:)` static API; `lineLimit(1)` + `minimumScaleFactor(0.5)` added as defense-in-depth
- `WordPuzzle/WordPuzzleTests/DynamicTypeTests.swift` - New `@MainActor @Suite` with 9 `@Test` functions covering the full clamp-math behavior contract

## Decisions Made
- Kept all four `GameTheme` font token identifiers unchanged (only their right-hand-side values changed) so no call sites needed edits, per the plan's scope guard.
- Wrote `HexTileView`'s font as `Font.system(size:...)` (explicit `Font.` prefix) instead of the equivalent `.system(size:...)` shorthand the plan's own interface listing used, so the app-wide "exactly one file contains `Font.system(size:`" grep invariant holds — see Deviations below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded GameTheme's doc comment to avoid embedding the literal grep target string**
- **Found during:** Task 1
- **Issue:** The plan's own action text specified a doc comment containing the literal substring `Font.system(size:)` twice ("...Font.system(size:) never scales..." and "Never reintroduce Font.system(size:) here..."), but the same task's own verification script asserts `grep -c "Font.system(size:" GameTheme.swift` equals `0`. Following the action text verbatim would have failed the task's own verify step.
- **Fix:** Reworded both sentences to describe the same concept ("a fixed-point-size font never scales...", "Never reintroduce a fixed-point-size font here...") without using the literal `Font.system(size:` substring. No change to the rationale conveyed.
- **Files modified:** `WordPuzzle/WordPuzzle/Game/GameTheme.swift`
- **Verification:** `grep -c "Font.system(size:" GameTheme.swift` returns 0; `xcodebuild build` succeeds.
- **Committed in:** `7902283` (Task 1 commit)

**2. [Rule 3 - Blocking] Used explicit `Font.system(size:...)` instead of the plan's literal `.system(size:...)` shorthand**
- **Found during:** Task 2
- **Issue:** The plan's interface code for the new `HexTileView.body` used `.font(.system(size: ..., weight: .semibold))` — Swift's implicit-member shorthand. That produces the substring `font(.system(size:`, which does NOT contain the literal `Font.system(size:` (capital F immediately followed by `.system(size:`). The plan's own overall-verification step requires `grep -rln "Font.system(size:" WordPuzzle/WordPuzzle` to return exactly one file (HexTileView.swift), which would have returned zero files with the shorthand form.
- **Fix:** Used the fully-qualified `Font.system(size: ..., weight: .semibold)` instead of the shorthand — behaviorally identical, but makes HexTileView.swift the sole match for the grep pattern that plan 05-04's `compliance-guards.sh` is documented to whitelist.
- **Files modified:** `WordPuzzle/WordPuzzle/Game/Views/HexTileView.swift`
- **Verification:** `grep -rln "Font.system(size:" WordPuzzle/WordPuzzle` returns exactly `WordPuzzle/WordPuzzle/Game/Views/HexTileView.swift`; full test suite still passes (68/68).
- **Committed in:** `3a616d0` (Task 2 commit)

**3. [Rule 3 - Blocking] Ran tests against `iPhone 17 Pro` simulator instead of the plan's `iPhone 17` destination**
- **Found during:** Task 2 verification, and overall plan verification
- **Issue:** This is one of three parallel worktree-agent executors running concurrently against the same shared macOS host. All three agents' `xcodebuild test` invocations targeted `platform=iOS Simulator,name=iPhone 17` — the only simulator with that exact name — causing repeated `Early unexpected exit, operation never finished bootstrapping (Test crashed with signal kill...)` failures from resource contention, not a code defect.
- **Fix:** Retargeted verification commands at the idle `iPhone 17 Pro` simulator (same iOS runtime family, same test target), which ran cleanly with zero contention.
- **Files modified:** None — verification-only change, no source files affected.
- **Verification:** `DynamicTypeTests` (9/9) and the full suite (68/68 across 12 suites) both pass cleanly on `iPhone 17 Pro`.
- **Committed in:** N/A (verification command choice, not a code change)

---

**Total deviations:** 3 auto-fixed (all Rule 3 - blocking issues preventing the plan's own verification from succeeding as literally written)
**Impact on plan:** All three are verification/tooling-level corrections that preserve the plan's stated intent (zero fixed-point fonts outside HexTileView; HexTileView as the sole sanctioned exception; green test suite). No production behavior changed beyond what the plan specified. No scope creep.

## Issues Encountered
- This worktree's git branch was stale relative to `main` — it had none of Phase 4's implementation or the Phase 5 planning docs (including this plan file) yet. Confirmed the branch tip was an exact ancestor of `main` (zero unique commits) via `git merge-base`, then fast-forwarded (`git merge --ff-only main`) to bring in Phase 4's code and the Phase 5 `PLAN.md`/`CONTEXT.md`/`UI-SPEC.md`/`RESEARCH.md` files needed to execute this plan. No conflicts; no destructive operations used.
- Simulator resource contention from parallel worktree agents sharing the single named `iPhone 17` simulator caused repeated test-runner bootstrap crashes; worked around by using the idle `iPhone 17 Pro` simulator for all verification in this plan (see Deviation 3).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `GameTheme`'s typography tokens and `HexTileView`'s clamp API are now frozen per this plan's contract; plan 05-04's `compliance-guards.sh` can safely grep for `Font.system(size:` and expect exactly one whitelisted file.
- AX5-magnitude visual verification (does the honeycomb actually look right at the largest accessibility text size on a real device/simulator) is explicitly deferred to plan 05-06, which can re-tune the 40pt ceiling if needed — no code changes anticipated, just a possible constant tweak.

---
*Phase: 05-polish-compliance-app-store*
*Completed: 2026-09-07*

## Self-Check: PASSED

- FOUND: WordPuzzle/WordPuzzle/Game/GameTheme.swift
- FOUND: WordPuzzle/WordPuzzle/Game/Views/HexTileView.swift
- FOUND: WordPuzzle/WordPuzzleTests/DynamicTypeTests.swift
- FOUND: .planning/phases/05-polish-compliance-app-store/05-02-SUMMARY.md
- FOUND commit: 7902283 (Task 1)
- FOUND commit: 3a616d0 (Task 2)
