---
phase: 04-paywall-free-tier-gate
plan: 03
subsystem: ui
tags: [swiftui, storekit2, paywall, in-app-purchase, timelineview]

# Dependency graph
requires:
  - phase: 04-paywall-free-tier-gate (04-01)
    provides: "PersistenceStore daily-counter/reset-date API (puzzlesPlayedToday, currentStreak, todayTotalScore, todayTotalWordsFound, nextResetDate)"
  - phase: 04-paywall-free-tier-gate (04-02)
    provides: "GameViewModel.RoundPhase.paywalled case and requestNextRound(isPremium:) gate logic"
provides:
  - "PaywallView: the rendered free-tier dead-end screen (countdown, today's stats, price, Unlock CTA, Restore link, inline errors)"
  - "ScoreBarView free-puzzle counter for free users"
  - "GameView fullScreenCover branching between PaywallView and MissedWordsView on roundPhase"
affects: [05-app-store-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TimelineView(.periodic) for live countdowns instead of Timer.scheduledTimer"
    - "Presentation views (PaywallView) take all data as values + async throwing closures, zero @Environment reach-through"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Game/Views/PaywallView.swift
    - WordPuzzle/WordPuzzleTests/PaywallViewTests.swift
  modified:
    - WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift
    - WordPuzzle/WordPuzzle/Game/Views/GameView.swift

key-decisions:
  - "GameView.swift needed `import StoreKit` to reference Product.displayPrice via entitlementStore.unlimitedProduct — added as a Rule 3 blocking-issue fix, not in the plan's literal code block"

patterns-established:
  - "PaywallView.countdownText(remaining:) is a static, unit-testable formatter separate from the TimelineView rendering it — pins frozen D-06 copy contract"

requirements-completed: [MON-01]

# Metrics
duration: ~12min
completed: 2026-08-31
---

# Phase 04 Plan 03: Paywall UI and GameView Wiring Summary

**Built `PaywallView` to the frozen 04-UI-SPEC.md contract (live countdown via TimelineView, today's stats card, price + Unlock/Restore CTAs) and wired it into `GameView`'s full-screen cover alongside `ScoreBarView`'s free-puzzle counter — the visible half of MON-01.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 2 completed
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `PaywallView` renders the complete dead-end screen: "Next free puzzle in" countdown (live-ticking via `TimelineView(.periodic(from: .now, by: 1))`), a 4-row "Today's Stats" card that renders 0s rather than an empty state, literal price text, an "Unlock Unlimited Puzzles" primary CTA, and a secondary "Restore Purchases" text link — with inline purchase/restore error slots and `.interactiveDismissDisabled()` enforcing D-05's true dead-end.
- `PaywallView.countdownText(remaining:)` is a static, unit-tested formatter pinning the D-06 copy contract (`"{H}h {M}m"` / `"{M}m"` / `"Less than a minute"`), verified by 3 passing `PaywallViewTests` cases covering all boundary conditions including negative remaining time.
- `GameView`'s single `.fullScreenCover` now branches its content closure on `roundPhase == .paywalled` vs `.roundOver`, replacing 04-02's `EmptyView()` placeholder with the real `PaywallView`, wired to `EntitlementStore.purchaseUnlimited()`/`.restore()` and `PersistenceStore`'s daily-stat/reset-date accessors.
- `MissedWordsView`'s "Next Puzzle" now routes through `viewModel.requestNextRound(isPremium: entitlementStore.isPremium)` instead of the ungated `startNewRound()` — the gate can no longer be bypassed from the recap screen.
- `ScoreBarView` gained `freePuzzlesRemaining: Int?` / `freePuzzlesPerDay: Int`, showing `"{n} of 3 free puzzles today"` (trailing-aligned) for free users and rendering nothing when `nil` (premium users), with the accessibility label updated to include the remaining count when present.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build PaywallView to the frozen UI-SPEC contract, with a unit-testable countdown formatter** - `2c4b735` (feat)
2. **Task 2: Add the free-puzzle counter to ScoreBarView and wire the paywall into GameView** - `026378d` (feat)

_TDD task 1 (RED->GREEN) was implemented as a single commit since the plan supplied the exact final file contents for both the view and its tests rather than a separate failing-test step._

## Files Created/Modified
- `WordPuzzle/WordPuzzle/Game/Views/PaywallView.swift` - New paywall screen: countdown, stats card, price/CTA/restore block, static `countdownText(remaining:)` formatter
- `WordPuzzle/WordPuzzleTests/PaywallViewTests.swift` - Unit tests pinning the D-06 countdown format contract (hours+minutes, minutes-only, sub-minute clamp)
- `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift` - Added `freePuzzlesRemaining`/`freePuzzlesPerDay` params, trailing counter text, updated accessibility label, added third preview
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` - Added `EntitlementStore`/`PersistenceStore` environment reads, `import StoreKit`, branched `fullScreenCover` content closure, gated `onContinue`, `ScoreBarView` counter wiring

## Decisions Made
- `GameView.swift` required `import StoreKit` to resolve `Product.displayPrice` on `entitlementStore.unlimitedProduct` — the plan's code block referenced this property without the import; added as a build-blocking fix (Rule 3).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing `import StoreKit` to GameView.swift**
- **Found during:** Task 2 (wiring PaywallView into GameView)
- **Issue:** `entitlementStore.unlimitedProduct?.displayPrice` failed to compile with "property 'displayPrice' is not available due to missing import of defining module 'StoreKit'" — `Product.displayPrice` is a StoreKit type/property GameView.swift had never needed before this plan.
- **Fix:** Added `import StoreKit` alongside the existing `import SwiftUI` at the top of the file.
- **Files modified:** WordPuzzle/WordPuzzle/Game/Views/GameView.swift
- **Verification:** Full xcodebuild test suite (59 tests, 11 suites) passed after the fix.
- **Committed in:** `026378d` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary compile fix with zero behavioral or architectural impact. No scope creep.

## Issues Encountered

Several of the plan's own `<acceptance_criteria>` grep gates (e.g., `grep -cE "EntitlementStore|PersistenceStore|GameViewModel" PaywallView.swift` expected to return 0, and the equivalent gate on `ScoreBarView.swift`) return non-zero counts. Verified these are exclusively doc-comment mentions baked into the plan's own literal `<action>` code blocks (e.g., "this view NEVER reads EntitlementStore or PersistenceStore from @Environment", "GameViewModel/store coupling by design") — not actual `@Environment`/type-level coupling. `grep -n` confirmed zero functional references; the views have no `@Environment` properties and take all inputs as plain values/closures, satisfying the actual zero-coupling design intent even though the plan's own grep patterns don't distinguish comments from code. No code changes made — the files match the plan's prescribed "exactly this content" verbatim.

## Next Phase Readiness

- MON-01 is now fully wired end-to-end: the gate (04-02) decides `.paywalled`, and this plan renders it with a complete, spec-compliant UI, no dismiss path, and correct purchase/restore -> new-round flow.
- Full test suite green (59 tests, 11 suites) including the new `PaywallViewTests`.
- Remaining Phase 4 scope (plan 04-04, if present) can build on this without further paywall UI changes.

---
*Phase: 04-paywall-free-tier-gate*
*Completed: 2026-08-31*

## Self-Check: PASSED

All created/modified files exist on disk and both task commit hashes (`2c4b735`, `026378d`) are present in git history.
