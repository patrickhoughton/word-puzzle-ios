# Phase 4: Paywall & Free Tier Gate - Research

**Researched:** 2026-08-31
**Domain:** SwiftUI gating logic + SwiftData persistence extension + StoreKit 2 consumption (no new IAP plumbing)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The paywall appears in TWO situations: (1) right after a free user finishes their 3rd puzzle of the day — it replaces the normal "generate next puzzle" flow instead of a 4th round starting, and (2) immediately on any later app relaunch that same day, before any puzzle is shown, if the daily limit is already reached. A free user should never see a puzzle screen they aren't allowed to play.
- **D-02:** An abandoned round (app closed/backgrounded before "Finish Round" is tapped) COUNTS toward the daily 3-puzzle limit. This is a deliberate change from current behavior: `PersistenceStore.record()` (and therefore `puzzlesPlayedToday()`) today only fires in `GameViewModel.finishRound()`. Closing this loophole requires tracking "puzzle started" as a distinct event from "puzzle finished." **Constraint downstream agents must preserve:** the daily-limit count (started rounds) and RET-02's lifetime stats (finished rounds — total games played, best score, total words found) are DIFFERENT counts and must not be conflated. A round that's started but abandoned must NOT count as a "game played" for lifetime stats or contribute a score.
- **D-03:** Free (non-premium) users see a running counter of puzzles remaining today (e.g. "2 of 3 free puzzles today"). Only relevant/shown for non-premium users.
- **D-04:** The counter lives in `ScoreBarView` — the existing top-of-screen status bar — rather than a new dedicated UI element.
- **D-05:** The paywall is a true dead-end once it appears — no dismiss, no peek at a locked/blurred game screen behind it. No home/menu screen exists to fall back to. The only actions are Unlock (purchase) or Restore Purchases.
- **D-06:** The paywall shows a LIVE-TICKING countdown to the user's next free puzzle (e.g. "2h 14m until your next free puzzle"), not a static message. The countdown target must align with `PersistenceStore.puzzlesPlayedToday()`'s existing day boundary (`calendar.startOfDay(for:)` + 1 day, i.e. local midnight) — do not introduce a different rolling-24-hour boundary.
- **D-07:** The paywall also shows "today's stats": Puzzles played today (existing `puzzlesPlayedToday()`), Current streak (existing `currentStreak()`), Today's total score (NEW query method required), Today's words found (NEW query method required).
- **D-08:** Price is presented prominently and literally (via `unlimitedProduct.displayPrice`, e.g. "$2.99") with a single primary CTA ("Unlock Unlimited" or similar) — not value-framed/de-emphasized copy.
- **D-09:** "Restore Purchases" is a secondary text link below the primary Unlock button — visible and functional, but does not compete visually with the primary CTA.

### Claude's Discretion

- Exact copy/wording for the sales pitch, Unlock button label, and countdown text format (e.g. "2h 14m" vs "2 hours 14 minutes") — **RESOLVED by 04-UI-SPEC.md** (already approved, see Canonical References below): exact copy is frozen in the UI-SPEC's Copywriting Contract.
- Visual layout/spacing of the paywall screen — **RESOLVED by 04-UI-SPEC.md** (approved 2026-08-31).
- Exact SwiftData query shape for the two new "sum today" methods (D-07) — planner/researcher decides whether these live on `PersistenceStore` as new methods following the existing `fetchCount`/`FetchDescriptor` patterns, or are computed differently. **Addressed in this research** (see Architecture Patterns, Code Examples).
- Exact schema/mechanism for tracking "puzzle started" (D-02) — planner/researcher decides, must satisfy the D-02 constraint. **Addressed in this research** (see Architecture Patterns, Don't Hand-Roll).
- Where exactly in `GameView`/`GameViewModel` the gate check happens — planner decides based on cleanest integration with existing round-phase state machine. **Addressed in this research** (see Architecture Patterns).

### Deferred Ideas (OUT OF SCOPE)

None new — discussion stayed within Phase 4 scope. Related backlog items already captured separately and NOT re-litigated here: 999.1 (player stats screen), 999.3 (differentiated invalid-word messaging), 999.10 (rejected-word logging).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| MON-01 | Free users can play 3 puzzles per day; a paywall gate appears after the 3rd puzzle ends | Architecture Patterns (gate interception design), Don't Hand-Roll (round-start tracking model), Code Examples (SwiftData schema + `PersistenceStore` extension, `GameViewModel.requestNextRound`), Common Pitfalls (task-ordering race, semantics change to `puzzlesPlayedToday()`) |

Note: MON-02/MON-03/MON-04 are already complete (Phase 2) and are consumed, not re-implemented, in this phase.

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **StoreKit 2 (native), not third-party SDKs** — `EntitlementStore` already satisfies this; Phase 4 must not introduce RevenueCat/Adapty or any new StoreKit plumbing.
- **SwiftData for queryable history/stats, `@AppStorage` for simple flags/seeds** — the new "puzzle started" tracking and "sum today" queries MUST use SwiftData, per the Phase 2 discuss-phase decision explicitly recorded in CLAUDE.md's Persistence table ("Game history, daily streak, lifetime stats" → SwiftData). A hand-rolled `@AppStorage` daily-attempt counter would contradict this locked project-level decision.
- **MVVM + `@Observable`, no TCA** — any new state (round-start tracking) must follow the existing `@Observable final class` convention already used by `WordList`/`PersistenceStore`/`EntitlementStore`.
- **No `UserDefaults`/cached flag as entitlement source of truth (MON-04)** — already satisfied by `EntitlementStore`; Phase 4 must not add a shortcut cached "isPremium" flag anywhere for the gate logic. Read `entitlementStore.isPremium` fresh each time.
- **"No Restore Purchases button" and "IAP reviewer cannot find the paywall" are listed as common rejection triggers** — the paywall must be trivially reachable; Review Notes must explain how to trigger it (e.g. "the sandbox account has already made 3 attempts today, so the paywall shows immediately on launch" or provide a way to reset).
- **Offline-first (UX-01, future phase but a standing constraint)** — nothing in Phase 4 should require network access; StoreKit calls already tolerate offline (sandbox/production entitlement checks are local via `Transaction.currentEntitlements`, purchase itself requires connectivity which is expected/acceptable for IAP).

## Summary

Phase 4 is pure gating logic and one new screen built entirely on top of already-completed, already-tested infrastructure (`EntitlementStore` for StoreKit 2, `PersistenceStore` for SwiftData). No new third-party dependency, no new StoreKit work, and no new persistence *system* — only two additive extensions to `PersistenceStore` and one new lightweight SwiftData model.

The central technical decision is **D-02's "abandoned rounds count toward the limit"** requirement, because the current codebase only ever writes a `GameRecord` when a round *finishes* (`GameViewModel.finishRound()` → `PersistenceStore.record()`). The cleanest solution — and the one most consistent with the project's own established conventions (additive-only changes to a "frozen" API, SwiftData over hand-rolled counters, clean separation of concerns) — is to add a **new, minimal SwiftData model** (e.g. `RoundStartRecord`, a single `date: Date` field) written at the moment a round actually starts (`GameViewModel.startNewRound(with:)`), and to **redefine `puzzlesPlayedToday()`'s data source** to count rows in this new model instead of `GameRecord`. `GameRecord` and all of RET-02's lifetime-stat methods (`totalGamesPlayed()`, `bestScore()`, `totalWordsFound()`) stay completely untouched, automatically preserving the "abandoned rounds don't count as games played" half of D-02's constraint. This keeps the "frozen" Phase 2 API's *signatures* stable (same method names, same call sites in the paywall/stats UI) while changing internal semantics deliberately — but it DOES require updating existing `PersistenceStoreTests.swift` assertions that currently rely on `record()` being the only way to move `puzzlesPlayedToday()`, since after this change `record()` alone will no longer do so.

The gate itself is best implemented as a single new `GameViewModel` method (`requestNextRound(isPremium:)`) that funnels BOTH trigger points from D-01 — "after the 3rd puzzle finishes" (via `MissedWordsView`'s `onContinue`) and "on relaunch when the limit is already reached" (via `WordPuzzleApp`'s `.task`) — through one gate check, transitioning to a new `RoundPhase.paywalled` case instead of starting a round when blocked. This avoids injecting `EntitlementStore` as a new dependency into `GameViewModel` (isPremium is passed in as a parameter instead, preserving `GameViewModel`'s existing narrow dependency surface) and avoids any reactive/derived "isLocked" boolean that would incorrectly fire the moment round 3 *starts* (before it's even finished) rather than only when a *4th* round is attempted.

**Primary recommendation:** Add `RoundStartRecord` (new SwiftData model, insert-only) + redefine `puzzlesPlayedToday()` onto it; add `todayTotalScore()`/`todayTotalWordsFound()` to `PersistenceStore` following the existing fetch-and-reduce pattern; add `RoundPhase.paywalled` + `GameViewModel.requestNextRound(isPremium:)` as the single gate-check funnel for both D-01 triggers; drive the countdown with `TimelineView(.periodic(from: .now, by: 1))` computed against `calendar.startOfDay(for:) + 1 day`; sequence the two `WordPuzzleApp` launch `.task` blocks so entitlement refresh completes before the gate check runs.

## Architecture Patterns

### Recommended Project Structure

No new folders needed. New files land in existing locations:

```
WordPuzzle/WordPuzzle/
├── Services/
│   ├── PersistenceStore.swift       # extend: puzzlesPlayedToday() data source change,
│   │                                 #   + todayTotalScore(), todayTotalWordsFound(),
│   │                                 #   + recordRoundStarted()
│   ├── RoundStartRecord.swift       # NEW — mirrors GameRecord.swift's shape/style
│   └── EntitlementStore.swift       # unchanged — consumed as-is
├── Game/
│   ├── GameViewModel.swift          # extend: RoundPhase.paywalled case,
│   │                                 #   requestNextRound(isPremium:) method
│   └── Views/
│       ├── GameView.swift           # extend: fullScreenCover branches on .paywalled too,
│       │                             #   passes entitlementStore.isPremium into onContinue
│       ├── ScoreBarView.swift       # extend: free-puzzle counter text (D-03/D-04)
│       └── PaywallView.swift        # NEW — value-in/closure-out, per 04-UI-SPEC.md
└── WordPuzzleApp.swift              # extend: sequence .task blocks, call requestNextRound
```

### Pattern 1: Round-Start Tracking as a Separate, Minimal SwiftData Model

**What:** Add a new `@Model final class RoundStartRecord { var date: Date }`, inserted (never updated) every time a round actually starts. `puzzlesPlayedToday()` is redefined to `fetchCount` against `RoundStartRecord` instead of `GameRecord`, using the exact same day-boundary predicate shape it already has.

**When to use:** Whenever a "count of attempts" must diverge from a "count of completions," and the completions side already has its own well-tested, schema-stable model that other code depends on (here: `GameRecord` backs RET-02's lifetime stats and is exercised by existing tests).

**Why this over extending `GameRecord` with an `isCompleted` flag:** Extending `GameRecord` would require (a) a schema migration adding a new field, (b) holding a reference to the in-progress record across the gap between `startNewRound()` and `finishRound()` to mutate it in place, and (c) adding an `isCompleted == true` filter to `totalGamesPlayed()`, `bestScore()`, and `totalWordsFound()` — three already-tested "frozen" methods whose predicates would need to change. A separate insert-only model touches zero existing predicates and makes the "these are two different counts" constraint (D-02) structurally obvious rather than filter-dependent.

**Example (new file, mirrors `GameRecord.swift`'s exact style):**
```swift
import Foundation
import SwiftData

/// CONTEXT D-02: tracks a round START, independent of whether it is ever finished.
/// Deliberately separate from GameRecord (which only ever represents a FINISHED
/// round for RET-02 lifetime stats) so the daily-limit count (this model) and the
/// lifetime "games played" count (GameRecord) can never be conflated.
@Model
final class RoundStartRecord {
    var date: Date

    init(date: Date = .now) {
        self.date = date
    }
}
```

**`PersistenceStore` changes:**
```swift
// Container must register the new model:
static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
    let configuration: ModelConfiguration
    if let url {
        configuration = ModelConfiguration(url: url)
    } else {
        configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
    }
    return try ModelContainer(for: GameRecord.self, RoundStartRecord.self, configurations: configuration)
}

/// D-02: called once per round that actually starts (GameViewModel.startNewRound(with:)).
@discardableResult
func recordRoundStarted(date: Date = .now) -> RoundStartRecord {
    let entry = RoundStartRecord(date: date)
    context.insert(entry)
    try? context.save()
    return entry
}

/// CHANGED (D-02): now counts RoundStartRecord (started rounds, including abandoned),
/// not GameRecord (finished rounds). Signature and day-boundary logic unchanged —
/// only the backing model changed. Existing callers (paywall stats display,
/// ScoreBarView counter) need no changes.
func puzzlesPlayedToday(now: Date = .now) -> Int {
    let startOfDay = calendar.startOfDay(for: now)
    guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
        return 0
    }
    let descriptor = FetchDescriptor<RoundStartRecord>(
        predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
    )
    return (try? context.fetchCount(descriptor)) ?? 0
}
```

`ModelContainer(for:configurations:)` accepts a variadic list of model types — confirmed stable, documented SwiftData API (Apple Developer Documentation, `ModelContainer` initializers). This is the standard way to register multiple `@Model` types in one container; no `Schema` object is required unless versioned migrations are needed (not needed pre-launch, no shipped users yet).

### Pattern 2: "Sum Today" Queries Follow the Existing Fetch-and-Reduce Pattern (D-07)

**What:** SwiftData has no `SUM`/`AVG` pushdown (already documented in the codebase's own `totalWordsFound()` comment: "RESEARCH Pitfall 3: SwiftData has NO SUM/AVG pushdown... Fetch and reduce in Swift instead"). The two new D-07 methods follow that exact precedent, scoped to today's day boundary (same boundary shape as `puzzlesPlayedToday()`, but querying `GameRecord` — finished rounds only, since abandoned rounds must not contribute a score per D-02's constraint).

**Example:**
```swift
/// D-07: sum of score across today's FINISHED rounds only (GameRecord, not
/// RoundStartRecord) — an abandoned round contributes 0, per D-02's constraint
/// that abandoned rounds must not contribute a score.
func todayTotalScore(now: Date = .now) -> Int {
    let (start, end) = todayBounds(now: now)
    let descriptor = FetchDescriptor<GameRecord>(
        predicate: #Predicate { $0.date >= start && $0.date < end }
    )
    let records = (try? context.fetch(descriptor)) ?? []
    return records.reduce(0) { $0 + $1.score }
}

func todayTotalWordsFound(now: Date = .now) -> Int {
    let (start, end) = todayBounds(now: now)
    let descriptor = FetchDescriptor<GameRecord>(
        predicate: #Predicate { $0.date >= start && $0.date < end }
    )
    let records = (try? context.fetch(descriptor)) ?? []
    return records.reduce(0) { $0 + $1.wordsFoundCount }
}

/// Extracted to avoid the day-boundary math (RESEARCH: 3 call sites now
/// duplicate this — puzzlesPlayedToday, todayTotalScore, todayTotalWordsFound).
private func todayBounds(now: Date) -> (Date, Date) {
    let start = calendar.startOfDay(for: now)
    let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
    return (start, end)
}
```
Note: `#Predicate` macros cannot close over a tuple element cleanly in all SwiftData/Swift versions in every case — if the planner hits a compile error capturing `start`/`end` from a tuple return, fall back to two local `let` bindings before the predicate (`let (start, end) = todayBounds(now: now); let s = start; let e = end`) or inline the boundary math per-method as `puzzlesPlayedToday()` already does. Flagged as LOW-risk but worth a fast compile-check early rather than assuming the refactor is transparent.

### Pattern 3: Single Gate-Check Funnel for Both D-01 Triggers

**What:** Add one `RoundPhase` case and one `GameViewModel` method that both trigger points call, rather than duplicating the "am I locked?" check in two places (`WordPuzzleApp`'s `.task` and `MissedWordsView`'s `onContinue`).

**Why not a reactive `isLocked` computed property in `GameView`:** A naive `var isLocked: Bool { !entitlementStore.isPremium && persistenceStore.puzzlesPlayedToday() >= 3 }`, if used to decide fullScreenCover *content* reactively, becomes true the moment round 3 *starts* (since `puzzlesPlayedToday()` counts starts under Pattern 1) — well before round 3 even finishes. If the paywall's content were derived from this boolean at `.roundOver` time, it would incorrectly show the paywall instead of round 3's own `MissedWordsView` recap. The gate must be evaluated only as a discrete decision at the exact moment "should a NEW round begin?" is asked — not as a continuously-reactive value tied to the same counter that a round increments upon starting.

**Example:**
```swift
// GameViewModel.swift
enum RoundPhase: Equatable { case loading, playing, roundOver, paywalled }

/// D-01: single funnel for BOTH trigger points — "continue after finishing"
/// and "relaunch when already at the limit." isPremium is passed in rather
/// than injected as a dependency, keeping GameViewModel decoupled from
/// EntitlementStore's type.
func requestNextRound(isPremium: Bool) {
    if !isPremium, (persistenceStore?.puzzlesPlayedToday() ?? 0) >= 3 {
        roundPhase = .paywalled
    } else {
        startNewRound()
    }
}

// startNewRound(with:) gains the D-02 side effect:
func startNewRound(with puzzle: Puzzle) {
    persistenceStore?.recordRoundStarted()   // NEW — must happen before any early return
    self.puzzle = puzzle
    // ...unchanged...
}
```

```swift
// GameView.swift
@Environment(EntitlementStore.self) private var entitlementStore
@Environment(PersistenceStore.self) private var persistenceStore

.fullScreenCover(isPresented: .constant(
    viewModel.roundPhase == .roundOver || viewModel.roundPhase == .paywalled
)) {
    if viewModel.roundPhase == .paywalled {
        PaywallView(
            unlimitedProduct: entitlementStore.unlimitedProduct,
            puzzlesPlayedToday: persistenceStore.puzzlesPlayedToday(),
            currentStreak: persistenceStore.currentStreak(),
            todayScore: persistenceStore.todayTotalScore(),
            todayWordsFound: persistenceStore.todayTotalWordsFound(),
            onUnlock: { try? await entitlementStore.purchaseUnlimited() },
            onRestore: { try? await entitlementStore.restore() }
        )
    } else {
        MissedWordsView(
            groups: viewModel.missedWordGroups,
            pangrams: viewModel.pangramSet,
            rank: viewModel.rank,
            foundCount: viewModel.foundCount,
            totalCount: viewModel.totalWordCount,
            onContinue: { viewModel.requestNextRound(isPremium: entitlementStore.isPremium) }
        )
    }
}
```

```swift
// WordPuzzleApp.swift — sequence, don't race (see Common Pitfalls)
.task {
    await entitlementStore.refreshEntitlements()
    await entitlementStore.loadProduct()
    await wordList.load()
    gameViewModel.requestNextRound(isPremium: entitlementStore.isPremium)
}
```
Combining the two previously-separate `.task` blocks into one sequential task removes the race condition entirely (see Common Pitfalls) at negligible cost — entitlement refresh is fast relative to parsing the ~173K-word list, which was already the dominant latency.

### Anti-Patterns to Avoid

- **Deriving the gate from a reactive boolean checked at render time:** Causes the paywall to preempt the just-finished round's own missed-words recap (see Pattern 3 rationale).
- **A hand-rolled `@AppStorage` daily-attempt counter:** Contradicts CLAUDE.md's explicit Phase 2 decision that queryable daily/history data belongs in SwiftData, not `@AppStorage`. It would also be a second source of truth for "how many rounds today" that can drift from `RoundStartRecord`'s ground truth — the same anti-pattern `currentStreak()`'s own code comment already calls out for streaks ("a stored counter is a second source of truth that drifts out of sync with actual play history").
- **Extending `GameRecord` with an `isCompleted` flag instead of a separate model:** Touches three already-tested "frozen" aggregate methods and requires in-place mutation of a previously-inserted model object across two method calls. See Pattern 1.
- **Detecting abandonment via `ScenePhase`/`UIApplication` background notifications:** Unreliable (not guaranteed to fire before a hard kill from the app switcher in all cases) and unnecessary — recording the start *immediately* at `startNewRound(with:)` time captures both normal and abandoned rounds with zero lifecycle-notification complexity, since the write happens before the user has any chance to abandon.
- **Injecting `EntitlementStore` into `GameViewModel` as a stored dependency:** Unnecessary coupling; `isPremium` is a single `Bool` that can be passed as a parameter to `requestNextRound(isPremium:)`, keeping `GameViewModel`'s test seams (which currently construct it with only `wordList` + optional `persistenceStore`) unchanged in shape.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Daily attempt counter that includes abandoned rounds | A custom `@AppStorage` int + date-key reset logic | New minimal SwiftData model (`RoundStartRecord`) + existing `fetchCount`/`FetchDescriptor` pattern | Matches CLAUDE.md's locked Phase 2 decision (SwiftData for queryable daily/history data); avoids a second, driftable source of truth; trivially testable with the same in-memory-container pattern already used throughout `PersistenceStoreTests.swift` |
| "Sum score/words today" | A cached running total updated incrementally on every submit | Fetch-and-reduce in Swift, scoped by the existing day-boundary predicate shape | SwiftData has no SUM pushdown (already documented in-repo); at this app's data scale (a few records/day) fetch-and-reduce cost is negligible — same reasoning already applied to `totalWordsFound()` |
| Live countdown to midnight | `Timer.scheduledTimer` + manual `@State` invalidation/cleanup | `TimelineView(.periodic(from: .now, by: 1))` | `TimelineView` is the SwiftUI-native, lifecycle-safe mechanism for time-driven view updates — no manual timer invalidation, no memory-leak risk from a retained `Timer` reference, integrates with SwiftUI's render loop instead of fighting it |
| Restore Purchases button behavior | Any custom StoreKit 1 payment-queue restore call | `EntitlementStore.restore()` (already calls `AppStore.sync()`) | Already built, already correct per MON-03/Guideline 3.1.1; Phase 4 only needs to wire the existing method to a button |

**Key insight:** Every piece of "new work" in this phase is additive to already-tested infrastructure. The single genuine design decision (D-02's round-start tracking) is best solved by adding a new, deliberately minimal, insert-only model rather than by mutating or overloading anything that already has passing tests depending on its current shape.

## Common Pitfalls

### Pitfall 1: `puzzlesPlayedToday()`'s Semantics Change Breaks Existing Tests

**What goes wrong:** `PersistenceStoreTests.swift` currently has tests (`testPuzzlesPlayedTodayCountsTodaysSessions`, `testPuzzlesPlayedTodayExcludesEarlierDays`, `testPuzzlesPlayedTodayPersistsAcrossRestart`) that call `store.record(...)` and then assert on `store.puzzlesPlayedToday()`. If `puzzlesPlayedToday()` is redefined to query `RoundStartRecord` instead of `GameRecord` (Pattern 1), these tests will start failing (count returns 0) because `record()` no longer writes to the model `puzzlesPlayedToday()` reads from.

**Why it happens:** This is an intentional, CONTEXT-mandated semantics change (D-02), not a regression — but it is a breaking change to test *fixtures*, not just implementation.

**How to avoid:** The plan must explicitly include updating these three tests to call a new `recordRoundStarted()` (or equivalent) instead of/in addition to `record()`, and must audit `GameViewModelTests.swift`'s `testFinishRoundRecordsSession` (checks `totalGamesPlayed()`, unaffected) and `testStartNewRoundResetsState` (calls `startNewRound(with:)` twice with no `persistenceStore` — safe, nil-coalesces).

**Warning signs:** Existing green tests turning red immediately after the `PersistenceStore` change, with failure messages showing `puzzlesPlayedToday() == 0` where a nonzero count was expected.

### Pitfall 2: `.task` Block Race Between Entitlement Refresh and the Launch-Time Gate Check

**What goes wrong:** `WordPuzzleApp.swift` currently runs entitlement refresh and word-list loading as two separate, concurrently-scheduled `.task` modifiers. If the launch-time gate check (`requestNextRound(isPremium:)`) reads `entitlementStore.isPremium` before `refreshEntitlements()` has completed, a genuinely premium user could be incorrectly shown the paywall on a cold launch (isPremium still at its default `false`).

**Why it happens:** SwiftUI's multiple `.task` modifiers on the same view run independently/concurrently; there's no implicit ordering guarantee between them, and word-list parsing (~173K words) and a StoreKit entitlement check have no inherent reason to finish in a predictable relative order.

**How to avoid:** Sequence the two operations into a single `.task` (see Code Examples) so entitlement state is authoritative before the gate check runs. This also matches D-08/MON-04's existing intent ("the entitlement check runs on EVERY app launch... before any view renders meaningful content").

**Warning signs:** Intermittent/flaky paywall-on-launch behavior for a premium test account, especially on a fast device where word-list parsing is quick.

### Pitfall 3: Recording the Round-Start Too Late or Too Early

**What goes wrong:** If `recordRoundStarted()` is called from `startNewRound()` (the public, guard-gated entry point) rather than `startNewRound(with:)` (the point after generation actually succeeds), a failed puzzle-generation attempt (e.g. word list not yet loaded) would either silently fail to record (if placed after the guard) or over-record (if placed before the guard, on every call including ones that bail out to `.loading`). Recording must happen exactly once per successful round start.

**How to avoid:** Place the `recordRoundStarted()` call inside `startNewRound(with:)`, which is only ever invoked once a `Puzzle` has actually been produced (either by `startNewRound()`'s successful generation path or directly by tests as the deterministic seam).

**Warning signs:** `puzzlesPlayedToday()` returning counts higher than the number of times a puzzle was actually shown to the user, or a test asserting `startNewRound(with:)` is idempotent-with-respect-to-persistence discovering it isn't.

### Pitfall 4: Countdown Boundary Drift from `puzzlesPlayedToday()`'s Boundary

**What goes wrong:** If the countdown's "midnight" is computed independently (e.g. `Date().addingTimeInterval(86400)` — a rolling 24 hours) rather than via the same `calendar.startOfDay(for:) + 1 day` logic `PersistenceStore` uses, the countdown could show a target time that disagrees with when `puzzlesPlayedToday()` actually resets (DST transitions make a rolling-24-hour offset and a calendar-day offset diverge by up to an hour twice a year, and even without DST a rolling window drifts from "midnight" over the course of a session).

**How to avoid:** Compute the countdown target using the exact same `Calendar` instance and `startOfDay(for:) + 1 day` pattern already in `PersistenceStore`, ideally by having `PersistenceStore` expose this boundary (e.g. a `nextResetDate(now:)` method) rather than duplicating the calendar math a fourth time in `PaywallView`/`GameView`.

**Warning signs:** Countdown reaches "0m" but the paywall doesn't unlock (or vice versa) — a visible, embarrassing user-facing bug.

### Pitfall 5: `.fullScreenCover(isPresented: .constant(...))` With Two Underlying Booleans

**What goes wrong:** The existing pattern uses `.constant(viewModel.roundPhase == .roundOver)` — a single boolean derived from one enum comparison. Extending this to `.constant(viewModel.roundPhase == .roundOver || viewModel.roundPhase == .paywalled)` is safe (SwiftUI re-evaluates the `.constant()` binding's wrapped value on every body re-render since it's not cached), but the *content closure* must re-check `viewModel.roundPhase` itself to decide between `MissedWordsView` and `PaywallView` — forgetting this and always rendering `MissedWordsView` inside the closure would silently ship a paywall that never appears.

**How to avoid:** Write the content closure's branch explicitly (see Pattern 3's code example) and add a UI test / manual QA step that specifically exercises "reach the limit via relaunch" (roundPhase transitions `.loading` → `.paywalled` directly, never touching `.roundOver`) as a distinct path from "reach the limit via finishing round 3."

## Code Examples

Verified patterns from official sources and existing codebase precedent:

### TimelineView-Driven Countdown (D-06)

```swift
// Source: Apple SwiftUI documentation (TimelineView), cross-referenced against
// community examples (see Sources). context.date, not Date(), avoids per-frame
// drift/flicker.
struct CountdownView: View {
    let resetDate: Date  // from PersistenceStore's day-boundary logic — see Pitfall 4

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, resetDate.timeIntervalSince(context.date))
            Text(formatted(remaining))
                .font(GameTheme.displayFont)
                .foregroundStyle(GameTheme.accent)
        }
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if seconds < 60 { return "Less than a minute" }
        if hours >= 1 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
```
This matches 04-UI-SPEC.md's Copywriting Contract format rules exactly ("{H}h {M}m" / "{M}m" / "Less than a minute").

### Multi-Model `ModelContainer` Registration

```swift
// Source: Apple SwiftData documentation, ModelContainer(for:configurations:) —
// variadic model-type list, stable since SwiftData's introduction (iOS 17).
return try ModelContainer(for: GameRecord.self, RoundStartRecord.self, configurations: configuration)
```

### `AppStore.sync()` Restore (already built — reference only, no new code needed)

```swift
// EntitlementStore.swift, already present:
func restore() async throws {
    try await AppStore.sync()
    await refreshEntitlements()
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-------------------|---------------|--------|
| StoreKit 1 `SKPaymentQueue.restoreCompletedTransactions()` | StoreKit 2 `AppStore.sync()` | StoreKit 2, iOS 15+ | Already adopted by `EntitlementStore.restore()` — no action needed |
| `Timer.scheduledTimer` for periodic UI updates | `TimelineView(.periodic(...))` | SwiftUI, iOS 15+ | Recommended for the D-06 countdown — no manual timer lifecycle management |

**Deprecated/outdated:** Nothing else in this phase's scope touches deprecated APIs; `EntitlementStore` already avoids the deprecated StoreKit 1 restore path per its own code comment.

## Open Questions

1. **Should `currentStreak()` (RET-01) be redefined to use `RoundStartRecord` as well, or stay `GameRecord`-based (finished rounds only)?**
   - What we know: CONTEXT's D-02/D-07 only mandate changing `puzzlesPlayedToday()`'s semantics; streak is not mentioned.
   - What's unclear: Whether an abandoned-only day should "count" toward a streak.
   - Recommendation: Leave `currentStreak()` unchanged (finished-rounds-only, i.e. still `GameRecord`-based) — a streak conceptually rewards actually *playing*, not merely *starting and quitting*, and CONTEXT gives no instruction to change this. If the planner disagrees, this should be called out explicitly as a new decision, not inferred silently.

2. **Exact wiring of `PaywallView`'s `onUnlock`/`onRestore` closures for async error handling.**
   - What we know: 04-UI-SPEC.md specifies inline error text slots for both purchase and restore failures with exact copy.
   - What's unclear: Whether `PaywallView` owns `@State` for the error strings itself (value-in/closure-out with an `async throws` closure it awaits and catches locally) or whether `GameView`/`WordPuzzleApp` catches and passes error state down as a value.
   - Recommendation: Given the established "value-in/closure-out, no environment reach-through" pattern for child views, `PaywallView` should own transient UI state (loading spinner during purchase, error text) itself, calling `onUnlock: () async -> Void` / `onRestore: () async -> Void` closures that internally `do/catch` and report success/failure back via a completion value or by throwing — the planner should pick the exact shape but should NOT make `PaywallView` reach into `EntitlementStore` directly, per the UI-SPEC's explicit constraint.

3. **Should the free-puzzle counter in `ScoreBarView` (D-03/D-04) read `PersistenceStore` directly, or be passed a computed `Int` from `GameView`?**
   - What we know: `ScoreBarView` is currently a pure value-in view (no environment reads at all).
   - What's unclear: Whether adding a `remainingFreePuzzles: Int?` parameter (nil for premium users, per D-03) is preferable to `ScoreBarView` gaining its own `@Environment` reads.
   - Recommendation: Preserve `ScoreBarView`'s existing zero-environment-coupling convention — add a new optional parameter (e.g. `freePuzzlesRemaining: Int?`), computed by `GameView` from `entitlementStore.isPremium` / `persistenceStore.puzzlesPlayedToday()` and passed down, consistent with how every other `ScoreBarView` value is already supplied by `GameView`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Xcode | Build/test | ✓ | 26.6 (Build 17F113) | — |
| Swift | Compilation | ✓ | 6.3.3 | — |
| iOS Simulator (iPhone 17-class) | Manual QA of paywall, countdown, sandbox purchase | ✓ | iPhone 17 Pro / Pro Max / 17e available | — |
| `WordPuzzle.storekit` config file | Sandbox purchase/restore testing | ✓ | present at `WordPuzzle/WordPuzzle/WordPuzzle.storekit` | — |
| StoreKit sandbox testing (via Xcode scheme's "Run" StoreKit Configuration) | Verifying purchase/restore during dev | ✓ (per STATE.md Phase 02-05 note) | — | Reset the scheme's StoreKit Configuration back to `WordPuzzle.storekit` if a prior session changed it to "None" (STATE.md explicitly flags this as a known trap) |
| Apple Developer sandbox tester account | Manual QA of real Restore Purchases flow across reinstalls (Phase 4 success criterion 4) | Not verifiable from this environment | — | Follow the same manual sandbox purchase process already used and documented in Phase 02-05's summary |

No missing dependencies block execution of this phase's core logic (gating + new screen). The only environment dependency requiring manual, human-in-the-loop verification is the actual sandbox purchase/restore round-trip across app reinstalls (success criteria 3 and 4), consistent with how Phase 2 already handled this (STATE.md: "Deferred to plan 02-05's real sandbox purchase test as the authoritative MON-02/MON-03 proof").

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Suite`/`@Test`/`#expect`) — confirmed from `PersistenceStoreTests.swift` and `GameViewModelTests.swift` |
| Config file | none — standard Xcode test target (`WordPuzzleTests`), no separate config |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/PersistenceStoreTests` |
| Full suite command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|--------------|
| MON-01 | `recordRoundStarted()` fires once per `startNewRound(with:)` call | unit | `-only-testing:WordPuzzleTests/GameViewModelTests` | ✅ (extend existing file) |
| MON-01 | `puzzlesPlayedToday()` counts `RoundStartRecord`, not `GameRecord`, including a round that is never finished | unit | `-only-testing:WordPuzzleTests/PersistenceStoreTests` | ✅ (extend existing file, update 3 existing tests per Pitfall 1) |
| MON-01 | `todayTotalScore()` / `todayTotalWordsFound()` sum only finished rounds (`GameRecord`), excluding abandoned starts | unit | `-only-testing:WordPuzzleTests/PersistenceStoreTests` | ✅ (extend existing file) |
| MON-01 | `requestNextRound(isPremium: false)` transitions to `.paywalled` when `puzzlesPlayedToday() >= 3`; `requestNextRound(isPremium: true)` always starts a round regardless of count | unit | `-only-testing:WordPuzzleTests/GameViewModelTests` | ✅ (extend existing file) |
| MON-01 | Paywall appears exactly after the 3rd puzzle's `MissedWordsView`, not before, not after a restart (full end-to-end) | manual / UI test | N/A — cross-launch state, best verified manually per Phase 2's precedent for StoreKit-dependent flows | ❌ Wave 0 (manual QA script, not automatable given StoreKit sandbox + relaunch requirements) |
| MON-01 | Restore Purchases restores premium status on a device with a prior sandbox purchase | manual | N/A — requires real sandbox Apple ID | ❌ Wave 0 (manual QA script, same pattern as Phase 02-05) |

### Sampling Rate

- **Per task commit:** `-only-testing:WordPuzzleTests/PersistenceStoreTests` and `-only-testing:WordPuzzleTests/GameViewModelTests` (fast, no simulator-wide word-list reload beyond what's already `@Suite(.serialized)`-protected)
- **Per wave merge:** Full `WordPuzzleTests` suite
- **Phase gate:** Full suite green, PLUS the two manual QA scripts (paywall-after-3rd-puzzle, restore-on-reinstall) executed and recorded before `/gsd:verify-work`, mirroring how Phase 2's sandbox purchase test was handled as the authoritative proof for StoreKit-dependent success criteria.

### Wave 0 Gaps

- [ ] `WordPuzzleTests/PersistenceStoreTests.swift` — update `testPuzzlesPlayedTodayCountsTodaysSessions`, `testPuzzlesPlayedTodayExcludesEarlierDays`, `testPuzzlesPlayedTodayPersistsAcrossRestart` to call `recordRoundStarted()` (not just `record()`) — covers MON-01's semantics change (Pitfall 1)
- [ ] `WordPuzzleTests/PersistenceStoreTests.swift` — new test cases for `todayTotalScore()`, `todayTotalWordsFound()`, and `recordRoundStarted()`/redefined `puzzlesPlayedToday()` — covers MON-01, D-07
- [ ] `WordPuzzleTests/GameViewModelTests.swift` — new test cases for `requestNextRound(isPremium:)` (both branches) and for `startNewRound(with:)`'s new `recordRoundStarted()` side effect — covers MON-01, D-02
- [ ] Manual QA script (not a Wave 0 file, but must exist before phase gate): step-by-step reproduction of "play 3 puzzles (including one abandoned), see paywall, verify countdown, sandbox-purchase, verify persists across restart, reinstall + Restore Purchases" — mirrors Phase 02-05's manual sandbox test structure

## Sources

### Primary (HIGH confidence)
- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` — existing `fetchCount`/`FetchDescriptor`/`SortDescriptor` patterns, day-boundary logic, SUM-pushdown limitation comment
- `WordPuzzle/WordPuzzle/Services/EntitlementStore.swift` — frozen public API (`isPremium`, `unlimitedProduct`, `purchaseUnlimited()`, `restore()`, `refreshEntitlements()`, `loadProduct()`)
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift`, `GameView.swift`, `WordPuzzleApp.swift` — current round-phase state machine, `.task` structure, `.fullScreenCover` precedent
- `WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift`, `GameViewModelTests.swift` — existing test coverage/assertions that will be affected by this phase's changes
- `.planning/phases/04-paywall-free-tier-gate/04-CONTEXT.md`, `04-UI-SPEC.md` — locked decisions and frozen visual/copy contract
- `.planning/STATE.md` — Phase 2/3 decisions, "frozen API" notes, known StoreKit sandbox testing traps

### Secondary (MEDIUM confidence)
- Apple App Store Review Guideline 3.1.1 restore-purchases requirement — verified via multiple current (2025/2026) developer community sources agreeing the requirement is unchanged: a visible, functional Restore Purchases mechanism reachable from the paywall (or Settings) is sufficient; no additional requirement found beyond what `EntitlementStore.restore()` + a visible button already satisfies
- SwiftUI `TimelineView(.periodic(from:by:))` pattern (`context.date` vs `Date()` to avoid drift) — verified across multiple current tutorial sources, consistent with Apple's own documented `TimelineView` API shape

### Tertiary (LOW confidence)
- None — all findings above were either verified against the actual codebase or cross-checked across multiple current sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new frameworks/dependencies introduced; all APIs (`SwiftData`, `StoreKit 2`, `TimelineView`) already in active, tested use in this codebase or are stable, long-established Apple APIs
- Architecture: HIGH — gate design derived directly from reading the actual current state machine (`RoundPhase`, `.fullScreenCover` usage, `.task` structure) and CONTEXT's explicit constraints; verified against existing test files to catch breaking changes ahead of time
- Pitfalls: HIGH — each pitfall was identified by tracing actual code paths (existing tests, `.task` concurrency, predicate boundary math) rather than generic StoreKit/SwiftData folklore

**Research date:** 2026-08-31
**Valid until:** 30 days (stable native-platform APIs; no fast-moving external dependency in this phase)
