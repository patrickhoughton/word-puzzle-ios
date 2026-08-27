# Architecture Research — iOS Word Puzzle Game

**Researched:** 2026-08-27
**Confidence:** HIGH (Stack and StoreKit patterns), MEDIUM (puzzle generation thresholds), HIGH (storage recommendations)

---

## Component Map

Five components cover the entire app. Each has a single, clear job.

### 1. WordList (data layer, read-only)
- Loads the bundled word file once on app startup
- Exposes a `Set<String>` for O(1) word validation
- Exposes a filtered subset of "pangram candidates" (words with exactly 7 distinct letters, 4+ chars, no proper nouns)
- Has no awareness of the current puzzle or game state
- Owns nothing except the in-memory word set

### 2. PuzzleGenerator (pure logic, no state)
- Takes the `WordList` as input
- Selects a letter set and center letter using the generation algorithm (see below)
- Returns a `Puzzle` value type (struct) containing: 7 letters, center letter, solution word set, pangram set, maximum possible score
- Is stateless — called fresh each time a puzzle is needed
- Has no UI, no storage, no StoreKit awareness

### 3. GameSession (in-session state, ephemeral)
- Holds the active `Puzzle` and all mutable in-game state: words found, current input, score
- Exposes actions: `submitWord(_:)`, `shuffleLetters()`, `resetInput()`
- Validates submissions against `puzzle.solutions` (Set lookup)
- Does not persist itself — when a session ends its state is summarized and handed off
- Implemented as an `@Observable` class, injected via SwiftUI environment

### 4. PersistenceStore (durable state)
- Stores completed game summaries (date, score, word count, puzzle ID) using SwiftData
- Stores daily puzzle usage counter (date + count) for free-tier enforcement
- Does NOT store the active session — sessions are ephemeral
- Exposes a query: `puzzlesPlayedToday() -> Int`
- Exposes a write: `recordCompletedGame(_ summary: GameSummary)`

### 5. EntitlementStore (IAP and unlock status)
- Wraps StoreKit 2
- Checks `Transaction.currentEntitlements` on every app activation (scene phase `.active`)
- Listens to `Transaction.updates` stream for deferred purchases
- Publishes a single `@Published var isPremium: Bool`
- Does NOT write isPremium to UserDefaults or SwiftData — StoreKit is the source of truth; the published value is a runtime cache only
- Owns the purchase action: `purchase() async throws`

---

## Data Flow

```
App Launch
  └─ WordList.load()           # synchronous, startup
  └─ EntitlementStore.refresh() # async, checks currentEntitlements

User requests a new puzzle
  └─ PuzzleGate checks:
       EntitlementStore.isPremium == false?
         └─ PersistenceStore.puzzlesPlayedToday() >= 3?
              └─ Show paywall (stop here)
  └─ PuzzleGenerator.generate(from: wordList) -> Puzzle
  └─ GameSession.start(puzzle: puzzle)

User types and submits a word
  └─ GameSession.submitWord(input)
       └─ puzzle.solutions.contains(normalized) -> Bool   # O(1)
       └─ if valid: update score, foundWords, emit feedback
       └─ if already found: emit duplicate feedback

Puzzle completed (all words found or user quits)
  └─ PersistenceStore.recordCompletedGame(summary)
  └─ PersistenceStore.incrementDailyCount()
  └─ GameSession reset

User taps "Unlock Unlimited"
  └─ EntitlementStore.purchase()
       └─ Product.purchase() -> VerificationResult<Transaction>
       └─ transaction.payloadValue (verifies Apple signature)
       └─ transaction.finish()
       └─ isPremium = true
```

---

## Puzzle Generation Algorithm

The approach is pangram-first: start from a word that uses all 7 letters, then find every other valid word those letters can form. This guarantees the puzzle always has a pangram and a well-bounded letter set.

**Confidence:** MEDIUM — The MATHLAB blog post provides a verified implementation of this approach; quality thresholds from NYT internal standards (via Hacker News) are confirmed but not Apple-documented.

### Pseudocode

```
func generatePuzzle(from wordList: WordList) -> Puzzle {

    // 1. Find pangram candidates
    //    A pangram candidate: 4+ chars, exactly 7 distinct letters,
    //    no S (avoids trivial plurals — optional but recommended),
    //    letters are not all vowels
    let candidates = wordList.pangramCandidates  // precomputed at load time

    // 2. Loop until a quality puzzle is found
    repeat {

        // 3. Pick a random pangram as the seed
        let seed = candidates.randomElement()!
        let letters = Set(seed)  // exactly 7 distinct letters

        // 4. Find all valid words for this letter set
        let solutions = wordList.words.filter { word in
            word.count >= 4 &&
            Set(word).isSubset(of: letters)
        }

        // 5. Select center letter
        //    Use the letter that appears in the fewest solution words
        //    (makes the center letter feel intentional; harder to brute-force)
        let centerLetter = letters.min {
            solutions.filter { $0.contains($0) }.count <
            solutions.filter { $1.contains($1) }.count
        }!

        // 6. Filter to words that include the center letter
        let finalSolutions = solutions.filter { $0.contains(centerLetter) }

        // 7. Quality gate
        //    Reject and retry if puzzle is too thin or too dense
        let wordCount = finalSolutions.count
        let pangrams = finalSolutions.filter { Set($0).count == 7 }
        guard wordCount >= 20,           // minimum for a satisfying puzzle
              wordCount <= 100,          // cap runaway letter sets
              !pangrams.isEmpty          // always at least one pangram
        else { continue }

        // 8. Compute max score
        //    4-letter words = 1 pt, longer words = letter count pts, pangram +7
        let maxScore = finalSolutions.reduce(0) { score, word in
            let base = word.count == 4 ? 1 : word.count
            let bonus = Set(word).count == 7 ? 7 : 0
            return score + base + bonus
        }

        // 9. Return the puzzle
        return Puzzle(
            letters: Array(letters),
            centerLetter: centerLetter,
            solutions: Set(finalSolutions),
            pangrams: Set(pangrams),
            maxScore: maxScore
        )

    } while true
}
```

### Performance notes
- Pangram candidates are filtered once at `WordList.load()`, not on every generation call
- The inner filter (step 4) runs over ~170K words but is a simple `isSubset` check — takes <50ms on device even unoptimized
- Generation can be moved to a background Task if perceived latency is an issue
- Seeding from a random pangram means collisions are rare; the quality gate loop almost never runs more than 1–2 iterations on a clean word list

### Word list recommendation for generation
Use the ENABLE (Enhanced North American Benchmark LExicon) word list: 172,820 words, public domain, used by Words With Friends, well-curated, no proper nouns. Stored as a newline-delimited plain text file. At approximately 1.8 MB, it is negligible in an iOS app bundle.

**Do not** use SOWPODS (international Scrabble) — it includes too many obscure letter combinations that produce puzzles with words players have never heard of. ENABLE is more player-friendly.

Optional: pre-filter the word list to remove words that are unlikely to be recognized by casual players (medical terms, highly technical words). This can be done by running against a frequency corpus before shipping.

---

## Storage Strategy

| Data | Storage | Reason |
|------|---------|--------|
| Word list | App bundle, plain text file (.txt), loaded into `Set<String>` at launch | Simple, no query needed — just membership checks |
| Pangram candidates | Derived in-memory from word list at load time | No need to persist; computed once, fast |
| Active game session | In-memory only (`GameSession` @Observable) | Ephemeral; losing it is acceptable, not a purchase |
| Completed game history | SwiftData (`GameSummary` model) | Queryable, typed, iOS 17+ native, fits solo dev workflow |
| Daily play count | SwiftData (`DailyUsage` model with date field) | Query by today's date; reset is automatic (new record each day) |
| IAP unlock status | StoreKit 2 `currentEntitlements` (source of truth), `@Published var isPremium` (runtime cache) | Do not write to UserDefaults or SwiftData; StoreKit handles persistence, restoration, and cross-device sync |
| App settings/preferences | `@AppStorage` (UserDefaults wrapper) | Sound on/off, haptics on/off — trivially small key-value data |

### Why not SQLite for the word list?
A `Set<String>` in memory gives O(1) lookups with no disk I/O per query. SQLite adds query overhead and file handle management for zero benefit — there are no relational queries, filters at runtime, or writes needed. The full ENABLE list fits in ~20–30 MB of RAM, which is entirely acceptable for a word game.

### Why not CoreData?
SwiftData is the modern replacement (WWDC 2023). For a solo developer starting fresh on iOS 17+, SwiftData has a cleaner API, requires less boilerplate, and integrates directly with SwiftUI via `@Model` macros and the `@Query` property wrapper. CoreData is the right choice only when targeting iOS 16 or older.

### SwiftData models needed

```swift
@Model class GameSummary {
    var date: Date
    var puzzleID: String      // hash of the letter set
    var score: Int
    var maxScore: Int
    var wordsFound: Int
    var totalWords: Int
}

@Model class DailyUsage {
    var date: Date            // store as start-of-day
    var puzzleCount: Int
}
```

### StoreKit 2 entitlement check pattern

```swift
@MainActor
@Observable class EntitlementStore {
    var isPremium: Bool = false

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue,
               transaction.productID == "com.yourapp.unlimited" {
                isPremium = true
                return
            }
        }
        isPremium = false
    }
}

// In App root:
.task(id: scenePhase) {
    if scenePhase == .active {
        await entitlementStore.refresh()
    }
}
```

Do not cache `isPremium` in UserDefaults. If the user deletes and reinstalls, StoreKit restores non-consumables automatically via `currentEntitlements` — a UserDefaults cache becomes stale and can cause access bugs.

---

## Build Order

Dependencies flow downward. Build from the bottom up.

```
Layer 0 — Data Foundation (no dependencies)
  1. WordList           Build and test the loader, Set construction, pangram candidate filter
  2. Puzzle (struct)    Define the value type: letters, center, solutions, pangrams, maxScore

Layer 1 — Pure Logic (depends only on Layer 0)
  3. PuzzleGenerator    Generation algorithm + quality gate; unit-testable with no UI
  4. Scoring logic      Point calculation function; pure, unit-testable

Layer 2 — Persistence (depends on Puzzle struct, no UI)
  5. SwiftData models   GameSummary + DailyUsage; set up the model container
  6. PersistenceStore   daily count queries, record writes

Layer 3 — Entitlements (standalone StoreKit wrapper)
  7. EntitlementStore   StoreKit 2 setup; testable with Xcode StoreKit test config

Layer 4 — Game State (depends on Puzzle, PersistenceStore)
  8. GameSession        Submit word, track found words, score, input state

Layer 5 — UI (depends on everything above)
  9. Game board UI      Hexagonal letter display, input area, found words list
  10. Score/rank UI     Score display with rank thresholds
  11. Paywall UI        Product fetch, purchase button, restore button
  12. History UI        Past games list from SwiftData query
```

### Why this order?
- WordList and PuzzleGenerator can be built and fully unit-tested with zero UI code
- GameSession can be tested by calling its methods directly before any views exist
- EntitlementStore is isolated — it has no dependency on game logic, so it can be stubbed easily during UI development
- UI is last because it's the hardest to test automatically and benefits from stable underlying logic

---

## Architecture Diagram (ASCII)

```
+----------------------------------------------------------+
|                        SwiftUI Views                     |
|  GameBoardView   PaywallView   HistoryView   SettingsView|
+---+------------------+----------------+-----------------++
    |                  |                |                 |
    v                  v                v                 v
+----------+    +---------------+  +----------+  +-----------+
|GameSession|   |EntitlementStore|  |Persistence|  |@AppStorage|
|@Observable|   |  @Observable  |  |   Store   |  |(settings) |
+----+------+   +-------+-------+  +-----+-----+  +-----------+
     |                  |                |
     v                  v                v
+----------+    +---------------+  +-----------+
|  Puzzle  |    |  StoreKit 2   |  |  SwiftData|
|  (struct)|    | (Apple SDK)   |  | container |
+----+-----+    +---------------+  +-----------+
     |
     v
+------------------+    +----------+
| PuzzleGenerator  +--->| WordList |
|  (pure logic)    |    | Set<Str> |
+------------------+    +----+-----+
                              |
                              v
                     +------------------+
                     | words.txt        |
                     | (app bundle)     |
                     | ~172K words      |
                     | ~1.8 MB          |
                     +------------------+
```

### Component isolation rules
- `WordList` and `PuzzleGenerator` have zero imports beyond Swift standard library
- `GameSession` does not import StoreKit or SwiftData
- `EntitlementStore` does not import game logic
- `PersistenceStore` does not import StoreKit
- Views talk to components via `@Environment` injection, not singletons or globals

---

## Open Questions / Flags for Later Phases

- **Word list curation**: ENABLE works, but you may want to filter out medical/technical words that confuse casual players. This needs a play-test pass, not engineering work.
- **Puzzle deduplication**: If a user plays many sessions, letter sets may repeat. Consider storing a hash of recent letter sets in SwiftData and skipping them during generation.
- **App Store review**: Apple may ask to demo IAP in review. Have a test configuration with a sandbox account ready. The StoreKit testing config in Xcode makes this straightforward.
- **Minimum iOS version**: SwiftData requires iOS 17. Targeting iOS 17+ means skipping ~10–15% of devices as of 2025, but simplifies persistence substantially. Confirm this tradeoff at project setup.
- **Generation performance**: Tested to be fast for ENABLE-sized word lists, but should be measured on a real device (not simulator) before shipping. If >500ms, move to a background Task and show a spinner.

---

## Sources

- MATHLAB Blog — Algorithmic Spelling Bee (pangram-first generation): https://blogs.mathworks.com/community/2023/04/06/an-algorithmic-spelling-bee/
- Swift with Majid — Mastering StoreKit 2: https://swiftwithmajid.com/2023/08/01/mastering-storekit2/
- The Swift Dev — StoreKit currentEntitlements vs updates: https://www.theswift.dev/posts/storekit-current-entitlements-vs-updates/
- Donny Wals — Set vs Array in Swift: https://www.donnywals.com/how-to-decide-between-a-set-and-array-in-swift/
- Kodeco — Data Structures: Tries in Swift: https://www.kodeco.com/books/data-structures-algorithms-in-swift/v4.0/chapters/18-tries
- Bleeping Swift — @AppStorage vs UserDefaults vs SwiftData: https://bleepingswift.com/blog/appstorage-vs-userdefaults-vs-swiftdata
- Hacker News — NYT Spelling Bee minimum word count (20 words): https://news.ycombinator.com/item?id=39735153
- DEV Community — SwiftUI Data Persistence 2025: https://dev.to/swift_pal/swiftui-data-persistence-in-2025-swiftdata-core-data-appstorage-scenestorage-explained-with-5g2c
- ENABLE word list via GitHub (MagicOctopusUrn/wordListsByLength): https://github.com/MagicOctopusUrn/wordListsByLength
