# Phase 4: Paywall & Free Tier Gate — Context

**Gathered:** 2026-08-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Gate free play at 3 puzzles/day and build the paywall screen that unlocks unlimited play via the already-built `EntitlementStore` (purchase/restore/price). No new StoreKit work — Phase 2 already built and verified `purchaseUnlimited()`, `restore()`, `refreshEntitlements()`, and `unlimitedProduct`. This phase is gating logic + one new screen, not new IAP plumbing.

</domain>

<decisions>
## Implementation Decisions

### Paywall Trigger Conditions
- **D-01:** The paywall appears in TWO situations, not just one: (1) right after a free user finishes their 3rd puzzle of the day — it replaces the normal "generate next puzzle" flow instead of a 4th round starting, and (2) immediately on any later app relaunch that same day, before any puzzle is shown, if the daily limit is already reached. A free user should never see a puzzle screen they aren't allowed to play.
- **D-02:** An abandoned round (app closed/backgrounded before "Finish Round" is tapped) COUNTS toward the daily 3-puzzle limit. This is a deliberate change from the current codebase: `PersistenceStore.record()` (and therefore `puzzlesPlayedToday()`) today only fires in `GameViewModel.finishRound()`, so an abandoned round is currently invisible to the count. Closing this loophole requires tracking "puzzle started" as a distinct event from "puzzle finished" — new persistence work, not present in the codebase today. **Constraint downstream agents must preserve:** the daily-limit count (started rounds) and RET-02's lifetime stats (finished rounds — total games played, best score, total words found) are DIFFERENT counts and must not be conflated. A round that's started but abandoned should count against the daily limit but must NOT count as a "game played" for lifetime stats or contribute a score.

### Free-Puzzle-Count Visibility
- **D-03:** Free (non-premium) users see a running counter of puzzles remaining today (e.g. "2 of 3 free puzzles today") — no surprise wall. This is only relevant/shown for non-premium users; premium users have no daily limit so nothing needs to display for them.
- **D-04:** The counter lives in `ScoreBarView` — the existing top-of-screen status bar (rank tier + found count) — rather than a new dedicated UI element.

### Paywall Hard-Wall Behavior
- **D-05:** The paywall is a true dead-end once it appears — no dismiss, no peek at a locked/blurred game screen behind it. The app has no home/menu screen to fall back to (Phase 3 D-12 — no separate start screen exists), so there is genuinely nothing else to show. The only actions are Unlock (purchase) or Restore Purchases; leaving means backgrounding or quitting the app.
- **D-06:** The paywall shows a LIVE-TICKING countdown to the user's next free puzzle (e.g. "2h 14m until your next free puzzle"), not a static "come back tomorrow" message. This requires a `Timer`/`TimelineView`-driven view, updating in real time. The countdown target must align with `PersistenceStore.puzzlesPlayedToday()`'s existing day boundary (`calendar.startOfDay(for:)` + 1 day, i.e. local midnight) — do not introduce a different rolling-24-hour boundary that would disagree with the count logic.
- **D-07:** The paywall also shows "today's stats" alongside the sales pitch (price + Unlock CTA + Restore link), not a pure sales-only screen:
  - Puzzles played today (e.g. "3 of 3") — already available via `PersistenceStore.puzzlesPlayedToday()`, no new work.
  - Current streak — already available via `PersistenceStore.currentStreak()`, no new work.
  - **Today's total score** — NOT currently queryable. `PersistenceStore` has no "sum score across today's `GameRecord`s" method. New query method required.
  - **Today's words found** — NOT currently queryable. Same implication: new query method required (sum of `wordsFoundCount` across today's records).

### Paywall Screen Content & Copy
- **D-08:** Price is presented prominently and literally (via `unlimitedProduct.displayPrice`, e.g. "$2.99") with a single primary CTA ("Unlock Unlimited" or similar) — not value-framed/de-emphasized copy ("less than a coffee").
- **D-09:** "Restore Purchases" is a secondary text link below the primary Unlock button — visible and functional (required by Apple Guideline 3.1.1, already satisfied technically by `EntitlementStore.restore()`), but does not compete visually with the primary CTA.

### Claude's Discretion
- Exact copy/wording for the sales pitch, Unlock button label, and countdown text format (e.g. "2h 14m" vs "2 hours 14 minutes")
- Visual layout/spacing of the paywall screen (component arrangement, GameTheme token usage) — this could also be pushed to a dedicated `/gsd:ui-phase 4` pass if a fuller design contract is wanted before planning
- Exact SwiftData query shape for the two new "sum today" methods (D-07) — planner/researcher decides whether these live on `PersistenceStore` as new methods following the existing `fetchCount`/`FetchDescriptor` patterns, or are computed differently
- Exact schema/mechanism for tracking "puzzle started" (D-02) — e.g. a lightweight new SwiftData model, an `@AppStorage` daily-attempt counter, or extending `GameRecord` with an in-progress state — planner/researcher decides, but must satisfy the D-02 constraint (daily-limit count ≠ lifetime-stats count)
- Where exactly in `GameView`/`GameViewModel` the gate check happens (e.g. intercepting `MissedWordsView`'s `onContinue` closure vs. a check in `startNewRound()` vs. at `WordPuzzleApp` launch) — planner decides based on cleanest integration with existing round-phase state machine

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — MON-01 (the only requirement mapped to Phase 4; MON-02/03/04 were already built and verified in Phase 2) defines acceptance criteria
- `.planning/ROADMAP.md` §"Phase 4: Paywall & Free Tier Gate" — 4 success criteria are the source of truth for what "done" means

### Project Instructions
- `CLAUDE.md` §"App Store Connect — What to Know for First Submission" — "No Restore Purchases button" and "IAP reviewer cannot find the paywall" are listed as common rejection triggers; the paywall must be trivially reachable in Review Notes

### Prior Phase Context
- `.planning/phases/02-persistence-entitlements/02-CONTEXT.md` — D-01/D-02 (`GameRecord` schema, scoring formula), D-07/D-08 (`@Observable` + `.environment()` service pattern, entitlement check timing)
- `.planning/phases/03-core-game-ui/03-CONTEXT.md` — D-12 (no separate start/menu screen exists — directly informs D-05's "true dead-end" decision here), D-07 (per-reason invalid-word messaging was deferred, unrelated to this phase but confirms the pattern of deferring polish)

No external specs or ADRs beyond project files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WordPuzzle/WordPuzzle/Services/EntitlementStore.swift` — fully built: `isPremium`, `unlimitedProduct` (for `.displayPrice`), `purchaseUnlimited()`, `restore()`, `refreshEntitlements()`, `loadProduct()`. Phase 4 consumes this as-is; no changes needed to this file's public API.
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` — `puzzlesPlayedToday(now:)` (COUNT via `fetchCount`, local-calendar-day boundary) and `currentStreak(now:)` are ready to consume directly. New methods needed for D-07 (today's total score, today's words found) should follow the same `fetchCount`/`FetchDescriptor` push-down pattern already established (e.g. `bestScore()`'s `SortDescriptor` + `LIMIT 1` approach, or a `#Predicate`-filtered sum).
- `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift` — existing top status bar (rank + found count); D-04 adds the free-puzzle counter here.

### Established Patterns
- `@Observable final class` for all service/state types — any new state needed for D-02's "puzzle started" tracking should follow this convention.
- `WordPuzzleApp.swift` is the injection root; both `PersistenceStore` and `EntitlementStore` are already instantiated and injected via `.environment()` there — Phase 4 doesn't need to add new injection plumbing, just consume what's there.
- `GameView.swift` is deliberately the ONLY view that touches `GameViewModel` — every child (`ScoreBarView`, `WordDisplayView`, `MissedWordsView`, `LetterGridView`) is value-in/closure-out. A new `PaywallView` should likely follow the same value/closure contract style rather than reaching into environment objects directly, consistent with Phase 3's established pattern.

### Integration Points
- `GameView.swift`'s `.fullScreenCover` pattern (currently used for `MissedWordsView` on `roundPhase == .roundOver`) is the direct precedent for how a `PaywallView` full-screen presentation would likely be wired.
- `MissedWordsView`'s `onContinue: { viewModel.startNewRound() }` closure (in `GameView.swift`) is the specific interception point for D-01's "block next puzzle" trigger — `startNewRound()` itself, or the code that decides to call it, needs the daily-limit + abandoned-round-aware gate check.
- `WordPuzzleApp.swift`'s existing `.task` blocks (entitlement refresh, word list load + `startNewRound()`) are the specific interception point for D-01's "block on relaunch" trigger.

</code_context>

<specifics>
## Specific Ideas

- The paywall must show a genuinely live-ticking countdown (D-06), not a static message — Patrick was specific about wanting real-time feedback on when free play resumes.
- Today's-stats block (D-07) is a deliberate richer paywall than a bare sales screen — four data points (puzzles today, streak, today's score, today's words found), two of which need new `PersistenceStore` query work.
- The abandoned-round decision (D-02) was a deliberate choice to close a loophole, accepting the added persistence-schema complexity rather than taking the simpler "only finished rounds count" default.

</specifics>

<deferred>
## Deferred Ideas

None new — discussion stayed within Phase 4 scope. Related backlog items already captured separately and NOT re-litigated here: 999.1 (player stats screen — a general lifetime-stats UI, distinct from the today-only stats shown on the paywall per D-07), 999.3 (differentiated invalid-word messaging), 999.10 (rejected-word logging).

</deferred>

---

*Phase: 04-paywall-free-tier-gate*
*Context gathered: 2026-08-31*
