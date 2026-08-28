# Phase 2: Persistence & Entitlements - Research

**Researched:** 2026-08-28
**Domain:** SwiftData persistence, StoreKit 2 entitlements, StoreKitTest automated testing, App Store Connect first-time IAP setup
**Confidence:** HIGH (SwiftData/StoreKit 2 core APIs, App Store Connect steps) / MEDIUM (StoreKitTest + Swift Testing framework interop, SwiftData aggregate query limits)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Game Record Schema**
- D-01: Each stored game session captures: `date` (timestamp), `score` (Int), and `wordsFoundCount` (Int). Full word lists are NOT stored — they're re-generatable from the puzzle engine and would bloat the SwiftData store unnecessarily.
- D-02: Scoring formula per session (standard Spelling Bee rules):
  - 4-letter word = 1 point
  - 5+ letter word = word.count points (e.g., 7-letter word = 7 pts)
  - Pangram bonus = +7 points on top of the word's length score
  - Total session score = sum of all submitted valid words

**App Store Connect Prerequisites**
- D-03: App Store Connect setup is NOT started. Phase 2 plans must begin with a first-timer-friendly walkthrough before any StoreKit 2 code is written: (1) Accept the Paid Applications Agreement, (2) Create an app record (if not already done), (3) Create a non-consumable IAP product. Plans must include step-by-step instructions (menu paths, what to click), consistent with the first-timer guidance from Phase 1 (D-02).
- D-04: IAP product identifier: `com.patrickhoughton.wordpuzzle.unlimited`

**StoreKit 2 Testing**
- D-05: Testing uses a **StoreKit Configuration File** (`.storekit`) added to the Xcode project + the `StoreKitTest` framework in XCTest. This enables simulated purchases without a real Apple ID — no sandbox account required for automated tests.
- D-06: Automated tests cover BOTH the purchase flow AND the restore flow (covering MON-03 and MON-04). A manual sandbox test (real Apple ID on device) is performed before marking the phase complete, but automated tests are the primary verification path.

**Service Wiring Architecture**
- D-07: Both `PersistenceStore` and `EntitlementStore` are `@Observable` final classes (consistent with `WordList` from Phase 1). They are instantiated in `WordPuzzleApp` and injected via `.environment()`. Views access them with `@Environment(PersistenceStore.self)` and `@Environment(EntitlementStore.self)`.
- D-08: `EntitlementStore` calls `Transaction.currentEntitlements` eagerly — in a `.task` modifier on the `WindowGroup` in `WordPuzzleApp.swift`. This ensures `isPremium` is authoritative before any view renders, satisfying the success criterion "on every app launch."

### Claude's Discretion
- SwiftData model name and property names (e.g., `GameRecord` vs. `GameSession`) — planner picks
- Streak reset logic implementation details (midnight UTC vs. local timezone) — planner decides; local timezone is the standard user expectation
- SwiftData `ModelContainer` configuration (in-memory for tests vs. on-disk for production) — planner handles; in-memory store for XCTest is the standard pattern

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 2 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MON-02 | User can purchase a one-time non-consumable IAP ($2.99) to unlock unlimited puzzles permanently | StoreKit 2 purchase flow (Code Examples), App Store Connect IAP product creation walkthrough |
| MON-03 | Paywall screen includes a visible "Restore Purchases" button (required by Apple Guideline 3.1.1) | `AppStore.sync()` pattern (Code Examples), StoreKitTest restore simulation via `SKTestSession` |
| MON-04 | Premium unlock status is verified via StoreKit 2 `Transaction.currentEntitlements` on every app launch (no UserDefaults flag as source of truth) | `EntitlementStore` architecture pattern, `.task` on `WindowGroup`, `checkVerified` pattern |
| RET-01 | App tracks and displays a daily streak counter (days in a row with at least one puzzle played) | Streak calculation pattern (Architecture Patterns), SwiftData query for last-played date |
| RET-02 | App shows lifetime stats: total words found, best score, total games played | SwiftData aggregate query patterns (`fetchCount`, sort+fetchLimit for max, manual reduce for sum) |
</phase_requirements>

## Summary

Phase 2 has two independent halves that share only the `@Observable` + `.environment()` wiring pattern established by `WordList` in Phase 1. **SwiftData** handles game history/stats (`PersistenceStore`) and is purely local — no App Store dependency, no network, and it's the most mechanical part of this phase. **StoreKit 2** handles entitlements (`EntitlementStore`) and has a hard external dependency: nothing in this half can be built or even compile-tested meaningfully until the Paid Applications Agreement is accepted and an IAP product exists in App Store Connect, because `Product.products(for:)` needs a real (or StoreKit-Configuration-simulated) product ID to resolve.

Both halves are well-trodden, stable Apple-native APIs (StoreKit 2 since iOS 15, SwiftData since iOS 17, `@Model`/`@Observable` macros unchanged in behavior since introduction). The main planning risks are not "will this work" but sequencing and process pitfalls: (1) App Store Connect setup must happen first and is a manual, human-driven, multi-day-eligible process (agreement acceptance can require banking/tax info); (2) SwiftData has real aggregate-query limitations (no SQL-pushed `SUM`/`AVG`) that change how "lifetime stats" queries should be written; (3) StoreKitTest's `SKTestSession` is documented almost exclusively with `XCTestCase`, and this project's dominant test convention (established in Phase 1) is the new **Swift Testing** framework (`@Test`/`#expect`), not XCTest — the planner needs an explicit decision on which framework hosts the StoreKit tests.

**Primary recommendation:** Do the App Store Connect walkthrough as literally the first task of Phase 2 (before any Swift code), build `PersistenceStore` with SwiftData using `fetchCount` for counts, sort+`fetchLimit(1)` for best score, and a manual reduce over a lightweight fetch for total words found; build `EntitlementStore` with the standard `checkVerified`/`currentEntitlements`/`Transaction.updates` triad; and host StoreKit purchase/restore tests in XCTest (not Swift Testing) since `SKTestSession` setup/teardown and Apple's own documentation assume `XCTestCase` lifecycle hooks — mixing frameworks per-file is normal in Apple projects (this repo already does it for `PerformanceTests.swift`).

## Standard Stack

### Core
| Component | API / Type | Purpose | Why Standard |
|-----------|-----------|---------|---------------|
| SwiftData | `@Model`, `ModelContainer`, `ModelContext`, `@Query`, `FetchDescriptor` | Game history persistence | Apple-native ORM over SQLite, replaces Core Data boilerplate, works with `@Observable` cleanly, already the confirmed choice per CLAUDE.md (2026-08-28 update overriding earlier UserDefaults-only STACK.md recommendation) |
| StoreKit 2 | `Product`, `Transaction`, `VerificationResult`, `AppStore.sync()` | Non-consumable IAP + entitlement check | Apple's Swift-first, async/await-native IAP API; no third-party SDK needed for a single non-consumable |
| StoreKitTest | `SKTestSession` | Automated purchase/restore simulation | Only Apple-supported way to test IAP flows without a sandbox Apple ID; required by D-05/D-06 |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `.storekit` Configuration File | Declares the non-consumable product locally in Xcode | Added once, referenced by both Simulator manual testing (Xcode scheme StoreKit Configuration) and `SKTestSession(configurationFileNamed:)` in tests |
| XCTest (`XCTestCase`) | Hosts StoreKit purchase/restore tests | `SKTestSession` lifecycle (buy, clear transactions, dialogs) is documented and commonly used with XCTest's `setUp()`/`tearDown()`; this repo already uses XCTest for `PerformanceTests.swift` alongside Swift Testing elsewhere |
| Swift Testing (`@Test`, `#expect`) | Hosts SwiftData persistence tests | Matches the dominant convention from Phase 1 (`WordListTests.swift`, `PuzzleGeneratorTests.swift`); no known incompatibility with SwiftData |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData | Core Data directly | More boilerplate, no `@Model` macro convenience; CLAUDE.md already locked SwiftData |
| SwiftData | UserDefaults + Codable struct array | Original STACK.md recommendation; superseded by CLAUDE.md 2026-08-28 update — do not use, would violate current project constraints |
| `SKTestSession` in XCTest | `SKTestSession` in Swift Testing (`@Test`) | Technically possible (it's a plain Swift class, not XCTest-coupled), but Apple's docs, WWDC sessions, and every found tutorial demonstrate it inside `XCTestCase`; using Swift Testing here is unverified territory — MEDIUM/LOW confidence, recommend XCTest for this specific test file to reduce risk |

**Installation:** None — SwiftData, StoreKit 2, and StoreKitTest are all system frameworks bundled with the iOS 17+/Xcode 26 SDK already in this project (deployment target confirmed at iOS 26.5, Xcode 26.6 installed). No SPM packages to add.

**Version verification:** N/A (no package registry versions apply — these are OS-level frameworks tied to the deployment target, which is already iOS 26.5, far above the iOS 17 minimum required for `@Model`/`@Observable`).

## Architecture Patterns

### Recommended Project Structure
```
WordPuzzle/WordPuzzle/
├── PuzzleEngine/              # existing (Phase 1) — untouched
│   ├── WordList.swift
│   ├── PuzzleGenerator.swift
│   └── PuzzleModel.swift
├── Services/                  # NEW — Phase 2 group, sibling to PuzzleEngine/
│   ├── GameRecord.swift       # @Model — SwiftData schema
│   ├── PersistenceStore.swift # @Observable — SwiftData queries
│   └── EntitlementStore.swift # @Observable — StoreKit 2 entitlements
├── WordPuzzleApp.swift        # MODIFIED — instantiate + inject both stores, .task for entitlement check
└── WordPuzzle.storekit        # NEW — StoreKit Configuration File (Xcode: File > New > File > StoreKit Configuration File)

WordPuzzleTests/
├── PersistenceStoreTests.swift   # NEW — Swift Testing (@Test), in-memory ModelContainer
└── EntitlementStoreTests.swift   # NEW — XCTest (XCTestCase), SKTestSession + WordPuzzle.storekit
```

### Pattern 1: SwiftData Model + In-Memory Test Container
**What:** `@Model` class for the schema; separate `ModelConfiguration(isStoredInMemoryOnly:)` for tests vs. on-disk for the real app.
**When to use:** Always split container creation into a factory so both production (`WordPuzzleApp`) and tests can request the same schema with different storage.
**Example:**
```swift
// Source: Apple Developer Documentation (ModelConfiguration), cross-verified via
// hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code
import SwiftData

@Model
final class GameRecord {
    var date: Date
    var score: Int
    var wordsFoundCount: Int

    init(date: Date = .now, score: Int, wordsFoundCount: Int) {
        self.date = date
        self.score = score
        self.wordsFoundCount = wordsFoundCount
    }
}

// Production (WordPuzzleApp.swift):
let container = try! ModelContainer(for: GameRecord.self)

// Test (in-memory, isolated per test run):
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: GameRecord.self, configurations: config)
let context = ModelContext(container)
```

### Pattern 2: SwiftData Aggregate Queries (No SQL Pushdown for SUM)
**What:** SwiftData has no `NSExpression`-style pushdown for `SUM`/`AVG` (unlike Core Data). `COUNT` works efficiently via `fetchCount(_:)`; `MAX`/`MIN` work efficiently via sort + `fetchLimit`; `SUM` must be fetched and reduced in Swift.
**When to use:** All three "lifetime stats" queries in RET-02.
**Example:**
```swift
// Source: Apple Developer Forums (SwiftData Aggregation thread), Use Your Loaf
// "SwiftData Expressions" — cross-verified, MEDIUM-HIGH confidence (multiple sources agree)

// Total games played — COUNT, pushed to SQLite, does not instantiate models
func totalGamesPlayed(in context: ModelContext) throws -> Int {
    try context.fetchCount(FetchDescriptor<GameRecord>())
}

// Best score — MAX via sort + fetchLimit(1), pushed to SQLite ORDER BY / LIMIT
func bestScore(in context: ModelContext) throws -> Int {
    var descriptor = FetchDescriptor<GameRecord>(sortBy: [SortDescriptor(\.score, order: .reverse)])
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first?.score ?? 0
}

// Total words found — SUM, NOT pushed to SQLite; fetch a lightweight projection and reduce.
// For a mobile game's realistic record count (hundreds to low thousands of sessions),
// fetching all wordsFoundCount values and summing in Swift is acceptable.
func totalWordsFound(in context: ModelContext) throws -> Int {
    try context.fetch(FetchDescriptor<GameRecord>())
        .reduce(0) { $0 + $1.wordsFoundCount }
}

// "Today's count" — filter with #Predicate on a date range (startOfDay...startOfNextDay)
func puzzlesPlayedToday(in context: ModelContext, calendar: Calendar = .current) throws -> Int {
    let startOfDay = calendar.startOfDay(for: .now)
    guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
    let descriptor = FetchDescriptor<GameRecord>(
        predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
    )
    return try context.fetchCount(descriptor)
}
```

### Pattern 3: Daily Streak Calculation
**What:** Compare the most recent `GameRecord.date` to "today" using `Calendar.isDate(_:inSameDayAs:)`, not raw date subtraction (avoids DST/timezone edge cases).
**When to use:** RET-01 streak increment/reset logic. Store the running streak count as a derived value computed from the most recent record(s), OR as a persisted counter updated on each new game — planner's discretion per CONTEXT.md, but the **derivation approach below avoids a second source of truth** and is recommended.
**Example:**
```swift
// Source: pattern cross-verified against blog.lukeroberts.co "Designing and
// Implementing a Daily Streak System in Swift" + Apple Calendar documentation.
// MEDIUM confidence (blog is not an Apple source, but the underlying Calendar
// APIs — isDate(_:inSameDayAs:), date(byAdding:) — are official and stable).

enum StreakOutcome { case continuesOrStarts, alreadyCountedToday, broken }

func streakOutcome(lastPlayedDate: Date?, today: Date = .now, calendar: Calendar = .current) -> StreakOutcome {
    guard let lastPlayedDate else { return .continuesOrStarts }
    if calendar.isDate(today, inSameDayAs: lastPlayedDate) {
        return .alreadyCountedToday
    }
    if let dayAfterLast = calendar.date(byAdding: .day, value: 1, to: lastPlayedDate),
       calendar.isDate(today, inSameDayAs: dayAfterLast) {
        return .continuesOrStarts // streak += 1
    }
    return .broken // streak = 1
}
```
Use **local timezone** (`Calendar.current`, the default) per CONTEXT.md discretion note — this matches user expectation ("did I play today, in my day") over UTC.

### Pattern 4: StoreKit 2 Entitlement Check (checkVerified + currentEntitlements + updates)
**What:** The three-part StoreKit 2 idiom: a `checkVerified` helper that unwraps `VerificationResult`, an eager `currentEntitlements` scan on launch, and a long-lived `Transaction.updates` listener for changes that happen while the app is running (e.g., Ask to Buy approval, or a purchase completing on another device).
**When to use:** `EntitlementStore` — this is the canonical Apple pattern (WWDC21 "Meet StoreKit 2", still current as of iOS 26/Xcode 26).
**Example:**
```swift
// Source: Apple's StoreKit 2 sample pattern (WWDC21 "Meet StoreKit 2"), cross-verified
// via multiple 2025-2026 tutorials (theswift.dev, swiftwithmajid.com). HIGH confidence —
// this exact triad (checkVerified / currentEntitlements / updates) is the unanimous
// standard pattern across every source checked.
import StoreKit
import Observation

enum StoreError: Error { case failedVerification }

@Observable
final class EntitlementStore {
    private(set) var isPremium: Bool = false
    private let unlimitedProductID = "com.patrickhoughton.wordpuzzle.unlimited"
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
    }

    deinit { updatesTask?.cancel() }

    /// D-08: called from .task on WindowGroup — authoritative on every launch.
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == unlimitedProductID {
                unlocked = true
            }
        }
        isPremium = unlocked
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        if case .success(let verification) = result {
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    /// MON-03: Restore Purchases button calls this — NOT the deprecated
    /// SKPaymentQueue.restoreCompletedTransactions().
    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
}
```

```swift
// WordPuzzleApp.swift — D-08: .task on WindowGroup, runs before first view renders content meaningfully
@main
struct WordPuzzleApp: App {
    @State private var persistenceStore = PersistenceStore()
    @State private var entitlementStore = EntitlementStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(persistenceStore)
                .environment(entitlementStore)
                .task {
                    await entitlementStore.refreshEntitlements()
                }
        }
    }
}
```

### Pattern 5: StoreKitTest Automated Purchase + Restore
**What:** `SKTestSession` loaded from the `.storekit` configuration file, used to simulate a full purchase and a restore without any Apple ID.
**When to use:** `EntitlementStoreTests.swift` — covers D-06 (MON-03 restore + MON-04 purchase-driven entitlement).
**Example:**
```swift
// Source: swiftwithmajid.com "StoreKit testing in Swift" (2024, pattern unchanged
// through 2026), cross-verified against Apple StoreKitTest framework existence
// and WWDC23 "What's new in StoreKit 2 and StoreKit Testing in Xcode".
// MEDIUM confidence: exact method signatures (buyProduct, disableDialogs) verified
// via secondary source; recommend confirming against Xcode's live autocomplete
// during implementation since StoreKitTest API surface has grown across Xcode versions.
import XCTest
import StoreKitTest
@testable import WordPuzzle

final class EntitlementStoreTests: XCTestCase {
    var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "WordPuzzle")
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDown() {
        session.clearTransactions()
    }

    func testPurchaseUnlocksPremium() async throws {
        let store = EntitlementStore()
        try await session.buyProduct(identifier: "com.patrickhoughton.wordpuzzle.unlimited")
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPremium)
    }

    func testRestoreUnlocksPremiumAfterFreshInstall() async throws {
        // Simulate a prior purchase, then a "fresh install" by creating a new store instance
        try await session.buyProduct(identifier: "com.patrickhoughton.wordpuzzle.unlimited")
        let freshStore = EntitlementStore() // simulates reinstall — no local flag carried over
        try await freshStore.restore()
        XCTAssertTrue(freshStore.isPremium)
    }
}
```
**Note on framework choice:** This file uses `XCTestCase`, not Swift Testing (`@Test`), diverging from this project's Phase 1 convention. This is intentional — see Common Pitfalls below.

### Anti-Patterns to Avoid
- **UserDefaults flag as premium source of truth:** MON-04 explicitly forbids this. `isPremium` must be a live computed/refreshed value from `Transaction.currentEntitlements`, never cached to UserDefaults and trusted without re-verification.
- **`SKPaymentQueue.restoreCompletedTransactions()`:** Deprecated StoreKit 1 API. Use `AppStore.sync()` for StoreKit 2 restore.
- **Fetching all `GameRecord`s to compute `puzzlesPlayedToday()`:** Use `fetchCount(_:)` with a date-range predicate instead of `fetch(_:).count` — avoids instantiating model objects you don't need.
- **Storing the streak as an independently-incremented counter with no relationship to actual play dates:** Creates drift risk (counter says 5, but user hasn't played in 3 days). Prefer deriving "is streak still alive" from the last `GameRecord.date` each time it's displayed, or updating the persisted counter transactionally in the same write as the new `GameRecord`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transaction receipt verification | Custom JWS/receipt parsing | `VerificationResult` + `checkVerified` pattern | StoreKit 2 does cryptographic verification internally; reinventing this is a security liability and unnecessary — the API already gives you a verified/unverified result |
| Restore purchases flow | Custom "check server for past purchases" | `AppStore.sync()` | This is a device-to-App-Store sync call; no backend exists in this app (per project constraints — no backend) and none is needed |
| SUM/AVG aggregate SQL | Custom raw SQLite queries alongside SwiftData | Fetch + `reduce` in Swift for SUM; `fetchCount`/sort+`fetchLimit` for COUNT/MAX | Mixing raw SQLite access with a SwiftData-managed store risks corrupting the store's internal state; the reduce-in-Swift cost is negligible at this app's realistic data volume (a mobile word game producing at most a few games/day) |
| Simulated purchases without StoreKitTest | Mock `EntitlementStore` protocol/fake object | `SKTestSession` + `.storekit` config file | Apple explicitly built StoreKitTest so real `Product`/`Transaction` types flow through actual StoreKit code paths in tests — a hand-rolled mock would test your mock, not your integration with StoreKit |

**Key insight:** Every "hand-roll" temptation in this phase (verification, restore, aggregate SQL, purchase mocking) has an Apple-native answer that is both less code and more correct than a custom implementation. The phase's actual engineering work is wiring, not building primitives.

## Runtime State Inventory

Not applicable — this is a greenfield phase (new `Services/` group, new SwiftData store, new StoreKit product). No rename/refactor/migration involved. Skipping this section per the greenfield exemption.

## Common Pitfalls

### Pitfall 1: Paid Applications Agreement Blocks All IAP Work — and Is Not Instant
**What goes wrong:** Developer starts writing `Product.products(for:)` code, discovers it returns nothing, and spends hours debugging "why won't StoreKit find my product" — when the actual blocker is that the Paid Applications Agreement was never accepted, or was accepted but banking/tax info is still pending.
**Why it happens:** This step lives in App Store Connect's business settings, not Xcode, and its completion state isn't visible from the code editor at all.
**How to avoid:** Do this as literally Step 1 of Phase 2, before opening Xcode for any StoreKit code. Note: accepting the agreement itself is instant once you click "Agree," but if banking/tax info is incomplete, product creation may still be blocked — allow buffer time for this administrative step, potentially outside pure coding time.
**Warning signs:** `Product.products(for:)` returns an empty array with no error, or the IAP product doesn't appear as creatable in App Store Connect's Monetization tab.

### Pitfall 2: IAP Product ID Does Not Need to Match the Bundle ID
**What goes wrong:** This project's bundle ID is `com.patrickhoughton.WordPuzzle` (capital W and P, confirmed in `project.pbxproj`), while the locked IAP product identifier is `com.patrickhoughton.wordpuzzle.unlimited` (lowercase "wordpuzzle"). CONTEXT.md's specific-ideas section states the product ID "must match the bundle ID used in Xcode exactly" — **this is not an Apple technical requirement** for a standard (non-hosted-content) IAP. Apple's own documentation confirms Product IDs do not need to follow the bundle ID at all for IAPs without App-Store-hosted content, which this app has (no hosted content, D-04 confirms the ID as final).
**Why it happens:** Reverse-DNS naming convention is common practice, and people conflate "convention" with "requirement."
**How to avoid:** Do NOT rename the bundle ID or the IAP product ID to force a case-match — this is unnecessary work and out of scope. Instead, the verification step in Phase 2 plans should confirm the exact string `com.patrickhoughton.wordpuzzle.unlimited` is used **consistently** in three places: (1) the App Store Connect product record, (2) the `.storekit` configuration file, (3) the string literal in `EntitlementStore.swift`. Consistency across these three, not matching the bundle ID, is what actually matters.
**Warning signs:** None currently — flagging proactively so the planner doesn't invent unnecessary bundle-ID-alignment work.

### Pitfall 3: SwiftData Has No SUM/AVG Pushdown — Don't Assume Core Data Parity
**What goes wrong:** Developer writes (or asks an LLM for) a `#Predicate`/`FetchDescriptor` expecting to compute `SUM(wordsFoundCount)` the way Core Data's `NSExpressionDescription` could. SwiftData's `#Expression` macro (iOS 18+) does not support `map()`/`reduce()`-style transformations needed for true aggregate pushdown; only `COUNT` (via `fetchCount`) and filtering are efficiently pushed to SQLite.
**Why it happens:** SwiftData's API surface looks declarative and SQL-like, creating an expectation of full aggregate support that doesn't exist yet.
**How to avoid:** Use `fetchCount(_:)` for counts, sort + `fetchLimit(1)` for max/min, and fetch-then-`reduce` in Swift for sums. At this app's realistic data scale (a personal game history, not a multi-tenant dataset), the in-memory reduce has no meaningful performance cost.
**Warning signs:** Compiler errors inside `#Predicate` or `#Expression` blocks mentioning unsupported methods like `map`.

### Pitfall 4: Test Framework Split — SKTestSession vs. This Project's Swift Testing Convention
**What goes wrong:** Phase 1 established Swift Testing (`import Testing`, `@Test`, `#expect`) as the dominant test convention (`WordListTests.swift`, `PuzzleGeneratorTests.swift`), with XCTest used only for `PerformanceTests.swift` (because `measure {}` needs XCTest). Every discovered tutorial and Apple's own StoreKitTest documentation demonstrates `SKTestSession` exclusively inside `XCTestCase` with `setUp()`/`tearDown()` lifecycle hooks. There is no confirmed, verified example of `SKTestSession` used inside a Swift Testing `@Suite`.
**Why it happens:** StoreKitTest predates Swift Testing (StoreKitTest: iOS 14+/Xcode 12; Swift Testing: WWDC24). Apple hasn't published Swift-Testing-specific StoreKitTest guidance.
**How to avoid:** Host `EntitlementStoreTests.swift` in XCTest, matching this repo's existing precedent of mixing frameworks per test concern (as already done for `PerformanceTests.swift`). Host `PersistenceStoreTests.swift` in Swift Testing, matching the dominant convention (SwiftData has no XCTest-specific coupling). Document this framework split explicitly in the plan so it isn't mistaken for inconsistency during review.
**Warning signs:** Attempting `@Suite`/`@Test` with `SKTestSession` compiles fine (it's just a Swift object) but has no verified test-lifecycle guarantees around `setUp`/`tearDown` timing — if something behaves unexpectedly, try XCTest first before debugging further.

### Pitfall 5: `.storekit` Configuration File Must Be Attached to the Scheme AND Referenced by Name in Tests
**What goes wrong:** Developer creates the `.storekit` file and it works when manually testing in Simulator (because Xcode's scheme editor has a "StoreKit Configuration" dropdown that auto-detects it), but automated tests fail because `SKTestSession(configurationFileNamed:)` needs the exact file name (without extension) and the file must be part of the test target's bundle resources, not just the app target's.
**Why it happens:** Two different "attachment" mechanisms exist — scheme-level (for manual Simulator runs) and target-membership (for `SKTestSession` to find the file at test runtime) — and they're easy to conflate.
**How to avoid:** When adding the `.storekit` file in Xcode, check target membership for BOTH the app target and the test target. Reference it by its base filename (e.g., `"WordPuzzle"` for `WordPuzzle.storekit`) in `SKTestSession(configurationFileNamed:)`.
**Warning signs:** `SKTestSession(configurationFileNamed:)` throws at test runtime even though the file exists and works in manual Simulator testing.

### Pitfall 6: `@Observable` EntitlementStore + `Transaction.updates` Retain Cycle / Task Leak
**What goes wrong:** The long-lived `Transaction.updates` listener `Task` is started in `init()` and never cancelled, or captures `self` strongly, keeping the store (and its `Task`) alive indefinitely or causing test-teardown issues (tasks bleeding into the next test).
**Why it happens:** `for await` loops over `AsyncSequence` run until the sequence ends or the task is cancelled — `Transaction.updates` never ends on its own.
**How to avoid:** Capture `self` weakly in the detached task (see Pattern 4 example) and cancel the task in `deinit`. In tests, ensure each `EntitlementStore` instance created for a test is allowed to `deinit` (don't hold a class-level singleton reference across tests) or explicitly manage cancellation.
**Warning signs:** Test suite hangs or shows unexpected entitlement state bleeding between test cases.

## Code Examples

See Architecture Patterns section above — all five patterns include verified, sourced code:
1. SwiftData Model + In-Memory Test Container
2. SwiftData Aggregate Queries
3. Daily Streak Calculation
4. StoreKit 2 Entitlement Check (checkVerified + currentEntitlements + updates)
5. StoreKitTest Automated Purchase + Restore

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| StoreKit 1 (`SKPaymentQueue`, `SKProductsRequest`) | StoreKit 2 (`Product`, `Transaction`, async/await) | iOS 15 (2021), now the unanimous recommendation | This project should never touch StoreKit 1 APIs; `SKPaymentQueue.restoreCompletedTransactions()` specifically must NOT be used (superseded by `AppStore.sync()`) |
| UserDefaults/`@AppStorage` for game history | SwiftData `@Model` | CLAUDE.md updated 2026-08-28 (this session) | Original STACK.md (2026-08-27) recommended UserDefaults; superseded one day later by explicit CLAUDE.md decision — plans must follow SwiftData, not the older STACK.md guidance |
| Core Data `NSExpressionDescription` for SUM/AVG pushdown | No SwiftData equivalent yet | SwiftData introduced iOS 17 (2023), gap persists through iOS 18/26 SDKs checked in this research | Sum-type aggregates must be computed in Swift after fetch, not pushed to SQL |

**Deprecated/outdated:**
- `SKPaymentQueue` / StoreKit 1: superseded by StoreKit 2, do not use.
- UserDefaults-only persistence for game history: explicitly superseded by the CLAUDE.md 2026-08-28 update; STACK.md's original persistence table is stale for this phase.

## Open Questions

1. **Does `SKTestSession` work correctly inside a Swift Testing `@Suite`, or must it stay in XCTest?**
   - What we know: Every tutorial and Apple's own WWDC demos use `XCTestCase`. `SKTestSession` itself is a plain Swift class with no XCTest-specific base type requirement.
   - What's unclear: Whether `setUp()`/`tearDown()` timing guarantees (needed for `clearTransactions()` between tests) have an equivalent, verified pattern in Swift Testing (`init()`/`deinit` on a `@Suite` class, as this project already does in `PuzzleGeneratorTests.swift`).
   - Recommendation: Default to XCTest for `EntitlementStoreTests.swift` per Pitfall 4. If the planner or implementer wants Swift Testing consistency, treat migrating this one file as a stretch goal, not a phase blocker — the risk of debugging an unverified interaction during a phase focused on external App Store Connect dependencies is not worth it.

2. **Should the streak counter be a stored, incrementally-updated field or a value derived at read-time from `GameRecord` dates?**
   - What we know: CONTEXT.md leaves this to planner discretion. A derived approach (Pattern 3) avoids a second source of truth but requires a query across potentially all historical dates if not bounded carefully (e.g., "how many consecutive days back from today").
   - What's unclear: Whether derivation should walk backward day-by-day querying SwiftData each day (simple, but N queries for an N-day streak) or fetch a bounded recent window (e.g., last 400 records) and compute in memory.
   - Recommendation: For a mobile game with realistic streak lengths (rarely beyond a few hundred days), fetch distinct play-dates within the last ~400 days in one query, then walk backward in memory. This bounds the query cost and avoids N round-trips to SwiftData.

3. **Is a manual sandbox purchase test (real Apple ID, physical device or Simulator with sandbox account) still required if StoreKitTest automated tests pass?**
   - What we know: D-06 explicitly requires a manual sandbox test before marking the phase complete, in addition to automated tests as the primary verification path.
   - What's unclear: Nothing — this is already locked. Including here only to make sure the planner adds an explicit manual-test task (not just automated XCTest) to the phase plan, since it's easy to treat "tests pass" as sufficient and skip the manual step.
   - Recommendation: Add a distinct, non-automatable task: "Manual sandbox purchase + restore test on device/Simulator with a sandbox Apple ID" as the final verification task of the phase, separate from the automated StoreKitTest tasks.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | All Phase 2 work | Yes | 26.6 (Build 17F113) | — |
| iOS SDK / Simulator | SwiftData + StoreKit testing | Yes | Deployment target iOS 26.5 (project setting) | — |
| App Store Connect account access | Paid Applications Agreement, IAP product creation | Unknown — could not be verified from this environment (requires web login) | — | None — this is a hard external dependency; must be confirmed by Patrick as the literal first task of the phase (per D-03 and Pitfall 1) |
| Apple Developer Program membership ($99/year) | Any App Store Connect access at all | Unknown — could not be verified from this environment | — | None — if not yet enrolled, this blocks everything else in this phase; STATE.md does not confirm enrollment status |
| Sandbox Apple ID (for manual test, D-06) | Manual purchase/restore verification at end of phase | Unknown — not needed until the final manual verification task | — | Automated StoreKitTest covers the primary verification path; sandbox Apple ID only needed at phase-end, not for development |

**Missing dependencies with no fallback:**
- App Store Connect account state (Developer Program enrollment + Paid Applications Agreement acceptance) cannot be verified from the local filesystem/repo. The plan's first task must include a verification/confirmation step with Patrick before any StoreKit code is written, per D-03.

**Missing dependencies with fallback:**
- Sandbox Apple ID is only needed for the final manual test task (D-06); automated StoreKitTest development can proceed without one.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | **Split**: Swift Testing (`import Testing`, `@Test`, `#expect`) for `PersistenceStoreTests.swift`; XCTest (`XCTestCase`) for `EntitlementStoreTests.swift` — see Pitfall 4 |
| Config file | None — no `.swift-testing` or pytest-equivalent config; tests run via the existing `WordPuzzleTests` target in the Xcode project (`WordPuzzle/WordPuzzle.xcodeproj`) |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/PersistenceStoreTests` |
| Full suite command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` |

Note: Simulator target confirmed as **iPhone 17** per STATE.md decision log ("Xcode 26/iOS 26.5 has no iPhone 16 simulator" — carried forward from Phase 1).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RET-01 | Streak increments on consecutive days, resets after a missed day | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/PersistenceStoreTests/testStreakIncrementsOnConsecutiveDays` | ❌ Wave 0 |
| RET-01 | Streak resets after a missed day | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/PersistenceStoreTests/testStreakResetsAfterMissedDay` | ❌ Wave 0 |
| RET-02 | Lifetime stats accumulate correctly (total words, best score, total games) | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/PersistenceStoreTests/testLifetimeStatsAccumulate` | ❌ Wave 0 |
| RET-02 / SC-1 | `puzzlesPlayedToday()` correct after simulated sessions, persists across restart | integration | `xcodebuild test ... -only-testing:WordPuzzleTests/PersistenceStoreTests/testPuzzlesPlayedTodayPersistsAcrossRestart` | ❌ Wave 0 |
| MON-04 / SC-4 | `EntitlementStore.isPremium` reads `currentEntitlements`, correct after sandbox purchase | integration | `xcodebuild test ... -only-testing:WordPuzzleTests/EntitlementStoreTests/testPurchaseUnlocksPremium` | ❌ Wave 0 |
| MON-03 / MON-04 / SC-4 | `isPremium` correct after restore | integration | `xcodebuild test ... -only-testing:WordPuzzleTests/EntitlementStoreTests/testRestoreUnlocksPremiumAfterFreshInstall` | ❌ Wave 0 |
| SC-5 | Sandbox IAP product created and attached in App Store Connect | manual-only (justification: App Store Connect is a web UI, not automatable from this codebase) | N/A — verification is a screenshot/confirmation step in the plan | ❌ Wave 0 (process task, not code) |

### Sampling Rate
- **Per task commit:** Run the specific new test file (`-only-testing:WordPuzzleTests/PersistenceStoreTests` or `EntitlementStoreTests`)
- **Per wave merge:** Full suite command above (includes Phase 1's existing `WordListTests`, `PuzzleGeneratorTests`, `PerformanceTests` — regression check that Phase 2 additions don't break Phase 1)
- **Phase gate:** Full suite green, plus the manual sandbox purchase/restore test (Open Question 3) completed and confirmed before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `WordPuzzleTests/PersistenceStoreTests.swift` — covers RET-01, RET-02, SC-1 (in-memory `ModelContainer`, Swift Testing `@Suite`)
- [ ] `WordPuzzleTests/EntitlementStoreTests.swift` — covers MON-03, MON-04, SC-4 (XCTest `XCTestCase`, `SKTestSession`)
- [ ] `WordPuzzle/WordPuzzle.storekit` — StoreKit Configuration File; must exist before `EntitlementStoreTests.swift` can run at all
- [ ] `WordPuzzle/WordPuzzle/Services/GameRecord.swift`, `PersistenceStore.swift`, `EntitlementStore.swift` — no existing `Services/` group; net-new
- [ ] App Store Connect: Paid Applications Agreement acceptance + IAP product `com.patrickhoughton.wordpuzzle.unlimited` created — prerequisite to all of the above, not a code artifact but a Wave 0 process gap

## Sources

### Primary (HIGH confidence)
- [Apple Developer: sign-and-update-agreements](https://www.developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements) — exact menu path for Paid Applications Agreement
- [Apple Developer: create-consumable-or-non-consumable-in-app-purchases](https://www.developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases) — IAP product creation steps
- StoreKit 2 `checkVerified`/`currentEntitlements`/`Transaction.updates` pattern — Apple's own WWDC21 "Meet StoreKit 2" pattern, stable and unanimous across all sources checked
- Local codebase inspection (`WordList.swift`, `PuzzleGeneratorTests.swift`, `PerformanceTests.swift`, `project.pbxproj`) — confirmed `@Observable` convention, Swift Testing vs. XCTest split precedent, bundle ID, deployment target (iOS 26.5), Xcode version (26.6)

### Secondary (MEDIUM confidence)
- [SwiftData Aggregate — Swift Forums](https://forums.swift.org/t/swiftdata-aggregate/66968) and [Apple Developer Forums: SwiftData Aggregation](https://developer.apple.com/forums/thread/736401) — confirms no SUM/AVG pushdown, cross-verified across two independent forum threads
- [SwiftData Expressions - Use Your Loaf](https://useyourloaf.com/blog/swiftdata-expressions/) — `#Expression` limitations
- [How to write unit tests for your SwiftData code - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code) — in-memory `ModelConfiguration` pattern
- [StoreKit testing in Swift | Swift with Majid](https://swiftwithmajid.com/2024/01/09/storekit-testing-in-swift/) — `SKTestSession` code pattern
- [StoreKit Entitlements: currentEntitlements vs updates | The Swift Dev](https://www.theswift.dev/posts/storekit-current-entitlements-vs-updates/) — confirms `updates` as complementary long-lived listener, not a replacement for `currentEntitlements`
- [Designing and Implementing a Daily Streak System in Swift](https://blog.lukeroberts.co/posts/streak-system/) — streak calculation pattern, cross-checked against Apple's `Calendar` API (official, stable)
- [IAP Product ID reverse-DNS requirement discussion](https://copyprogramming.com/howto/does-an-in-app-purchase-s-product-id-have-to-begin-with-a-reverse-dns) — confirms product ID/bundle ID independence for non-hosted-content IAP

### Tertiary (LOW confidence)
- WWDC23 "What's new in StoreKit 2 and StoreKit Testing in Xcode" — referenced via search result titles only, not directly fetched; recommend the implementer watch/skim this session if `SKTestSession` behaves unexpectedly, since it may cover API additions beyond what secondary sources describe

## Metadata

**Confidence breakdown:**
- Standard stack (SwiftData, StoreKit 2 core APIs): HIGH — stable, unchanged Apple-native APIs, cross-verified across 3+ independent sources each
- StoreKitTest + Swift Testing interop: MEDIUM — no direct verified example found combining the two; recommendation (use XCTest) is a risk-reduction choice, not a confirmed requirement
- SwiftData aggregate query limits: MEDIUM-HIGH — confirmed via two independent forum threads plus a blog post; no official Apple documentation page was directly fetchable (403s), but community consensus is strong and consistent
- App Store Connect walkthrough steps: HIGH — Apple's own help pages fetched directly, cross-verified against 2026-dated third-party guides describing the same UI

**Research date:** 2026-08-28
**Valid until:** 30 days for App Store Connect UI specifics (Apple periodically redesigns App Store Connect navigation); 90+ days for StoreKit 2/SwiftData API patterns (stable core frameworks, unlikely to change within a single Xcode major version)
