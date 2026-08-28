# Phase 2: Persistence & Entitlements — Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a pure data and service layer — no UI. Two `@Observable` service classes:
1. **`PersistenceStore`** — SwiftData-backed game history. Supports `puzzlesPlayedToday()`, daily streak calculation, and lifetime stats queries.
2. **`EntitlementStore`** — StoreKit 2-backed premium status. Reads `Transaction.currentEntitlements` on every app launch via a `.task` on `WindowGroup`.

Both services are injected via SwiftUI `.environment()` at app root and exercised by XCTest unit/integration tests. App Store Connect setup (Paid Applications Agreement + IAP product creation) is a prerequisite task at the start of this phase.

</domain>

<decisions>
## Implementation Decisions

### Game Record Schema
- **D-01:** Each stored game session captures: `date` (timestamp), `score` (Int), and `wordsFoundCount` (Int). Full word lists are NOT stored — they're re-generatable from the puzzle engine and would bloat the SwiftData store unnecessarily.
- **D-02:** Scoring formula per session (standard Spelling Bee rules):
  - 4-letter word = 1 point
  - 5+ letter word = word.count points (e.g., 7-letter word = 7 pts)
  - Pangram bonus = +7 points on top of the word's length score
  - Total session score = sum of all submitted valid words

### App Store Connect Prerequisites
- **D-03:** App Store Connect setup is NOT started. Phase 2 plans must begin with a first-timer-friendly walkthrough before any StoreKit 2 code is written:
  1. Accept the Paid Applications Agreement in App Store Connect
  2. Create an app record (if not already done)
  3. Create a non-consumable IAP product
  Plans must include step-by-step instructions (menu paths, what to click), consistent with the first-timer guidance from Phase 1 (D-02).
- **D-04:** IAP product identifier: `com.patrickhoughton.wordpuzzle.unlimited`

### StoreKit 2 Testing
- **D-05:** Testing uses a **StoreKit Configuration File** (`.storekit`) added to the Xcode project + the `StoreKitTest` framework in XCTest. This enables simulated purchases without a real Apple ID — no sandbox account required for automated tests.
- **D-06:** Automated tests cover BOTH the purchase flow AND the restore flow (covering MON-03 and MON-04). A manual sandbox test (real Apple ID on device) is performed before marking the phase complete, but automated tests are the primary verification path.

### Service Wiring Architecture
- **D-07:** Both `PersistenceStore` and `EntitlementStore` are `@Observable` final classes (consistent with `WordList` from Phase 1). They are instantiated in `WordPuzzleApp` and injected via `.environment()`. Views access them with `@Environment(PersistenceStore.self)` and `@Environment(EntitlementStore.self)`.
- **D-08:** `EntitlementStore` calls `Transaction.currentEntitlements` eagerly — in a `.task` modifier on the `WindowGroup` in `WordPuzzleApp.swift`. This ensures `isPremium` is authoritative before any view renders, satisfying the success criterion "on every app launch."

### Claude's Discretion
- SwiftData model name and property names (e.g., `GameRecord` vs. `GameSession`) — planner picks
- Streak reset logic implementation details (midnight UTC vs. local timezone) — planner decides; local timezone is the standard user expectation
- SwiftData `ModelContainer` configuration (in-memory for tests vs. on-disk for production) — planner handles; in-memory store for XCTest is the standard pattern

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — MON-02, MON-03, MON-04 (monetization), RET-01, RET-02 (retention) define acceptance criteria for Phase 2

### Roadmap
- `.planning/ROADMAP.md` §"Phase 2: Persistence & Entitlements" — 5 success criteria are the source of truth for what "done" means

### Prior Phase Context
- `.planning/phases/01-word-engine-puzzle-generation/01-CONTEXT.md` — D-01 (Xcode project structure), D-02 (first-timer step-by-step guidance required in all plans), D-07 (`Puzzle` struct and `enable-clean.txt` bundling)

### Research
- `.planning/research/STACK.md` — confirmed stack: SwiftUI + @Observable MVVM, iOS 17+ target, SwiftData for persistence, StoreKit 2 for IAP

No external specs or ADRs beyond project files.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WordPuzzle/WordPuzzle/PuzzleEngine/PuzzleModel.swift` — `Puzzle` struct is the record type; `Puzzle.validWords` array drives `wordsFoundCount`; `Puzzle.pangrams` determines pangram bonus in scoring
- `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` — minimal `@main` struct; will be updated to instantiate PersistenceStore and EntitlementStore, inject via `.environment()`, and add `.task` for EntitlementStore launch check

### Established Patterns
- `WordList` in `WordPuzzle/WordPuzzle/PuzzleEngine/WordList.swift` is already `@Observable final class` — `PersistenceStore` and `EntitlementStore` follow the same pattern
- `PuzzleEngine/` group inside the app target (not a standalone Swift Package) — new service files go in a `Services/` group at the same level

### Integration Points
- `WordPuzzleApp.swift` is the injection root — both services instantiated here and passed down the view hierarchy
- Phase 3 (Core Game UI) will consume `PersistenceStore` to record game results and `EntitlementStore` to gate features
- Phase 4 (Paywall) will consume `EntitlementStore.isPremium` and `PersistenceStore.puzzlesPlayedToday()` to determine when to show the paywall

</code_context>

<specifics>
## Specific Ideas

- Patrick is new to iOS development — App Store Connect walkthrough must be first-timer-friendly with explicit menu paths (e.g., "App Store Connect → Agreements, Tax, and Banking → Request")
- The IAP product identifier `com.patrickhoughton.wordpuzzle.unlimited` must match the bundle ID used in Xcode exactly — plans should include a step to verify bundle ID consistency
- StoreKit Configuration File approach is preferred because it allows the entire entitlement flow to be verified in Simulator/XCTest without requiring a physical device or sandbox Apple ID
- Blocker from STATE.md: Paid Applications Agreement must be accepted in App Store Connect BEFORE writing any StoreKit 2 code — this must be Step 1 in Phase 2 execution

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 2 scope.

</deferred>

---

*Phase: 02-persistence-entitlements*
*Context gathered: 2026-08-28*
