# Stack Research — iOS Word Puzzle Game

**Project:** Word Puzzle iOS (Spelling Bee-style)
**Researched:** 2026-08-27
**Researcher:** GSD Research Agent

---

## Recommended Stack

| Component | Choice | Rationale | Confidence |
|-----------|--------|-----------|------------|
| UI Framework | SwiftUI (iOS 17+ target) | Native, no game engine needed, aligns with project constraint | HIGH |
| Architecture | MVVM with @Observable | Lowest-friction for solo dev, replaces ObservableObject boilerplate, no third-party dependency | HIGH |
| IAP | StoreKit 2 (native) | Apple's current Swift-first API, async/await, no third-party SDK needed | HIGH |
| Word list | ENABLE word list (.txt, bundled) | Public domain, ~173K words, proven in word games, loads into a Swift Set for O(1) lookup | HIGH |
| Word validation | Bundled Set<String> lookup (primary) + UITextChecker (secondary) | Bundled list gives control over valid words; UITextChecker used only for rejecting proper nouns | MEDIUM |
| Persistence | @AppStorage / UserDefaults | Game state is tiny (score, daily count, IAP flag); UserDefaults is correct for under 512KB | HIGH |
| Analytics | TelemetryDeck | Privacy-first, Swift-native SPM package, no consent popup required, 100K signals/month free | HIGH |
| Minimum iOS | iOS 17 | Required for @Observable macro; covers ~90%+ of active devices as of 2025 | HIGH |

---

## Architecture Pattern

**Use MVVM with Swift's @Observable macro. Do not use TCA.**

### Why MVVM + @Observable

iOS 17 introduced the `@Observable` macro (Swift 5.9 Observation framework), which replaces the older `ObservableObject` / `@Published` pattern. It has less boilerplate, better performance (only re-renders views that actually read changed properties), and is Apple's own preferred direction.

For a word game under 10 screens built by one developer, MVVM is the right scope. The game has:
- A `GameViewModel` owning puzzle state (letters, found words, score, time)
- A `PurchaseManager` (or `StoreManager`) owning IAP state
- Simple SwiftUI views consuming both

```swift
// Modern approach — no ObservableObject, no @Published
@Observable
class GameViewModel {
    var foundWords: [String] = []
    var score: Int = 0
    var letters: [Character] = []
    var centerLetter: Character = "A"
    // ...
}
```

Views declare the model as `@State` (if owned by the view) or receive it via `@Environment`.

### Why NOT TCA (The Composable Architecture)

TCA is a third-party framework from Point-Free. It is excellent for large teams and complex apps (Adidas, The Browser Company use it in production). For a solo developer new to iOS building a single-mechanic word game, it introduces:

- A steep learning curve (reducers, effects, stores, testing infrastructure)
- Slower compile times at scale
- A dependency on a third-party package that must be kept current
- Far more code than the problem warrants

Ship with MVVM + @Observable. TCA is a future option if the app grows into multiple complex, interdependent features.

---

## Key APIs & Frameworks

### StoreKit 2 — Non-Consumable IAP

StoreKit 2 is Apple's Swift-first IAP API introduced in iOS 15, now the standard. Use it directly — no RevenueCat, no Adapty, no third-party wrapper needed for a single non-consumable product.

**Core flow:**

```swift
// 1. Fetch product
let products = try await Product.products(for: ["com.yourapp.unlimited"])
let product = products.first!

// 2. Purchase
let result = try await product.purchase()
switch result {
case .success(let verification):
    let transaction = try verification.payloadValue
    await transaction.finish()
    // unlock content
case .userCancelled, .pending:
    break
}

// 3. Restore on app launch (required by Apple guidelines)
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result,
       transaction.productID == "com.yourapp.unlimited" {
        // re-unlock content
    }
}
```

**High-level shortcut:** `ProductView(id:)` from SwiftUI renders a ready-made purchase button with the App Store price. Use it in your paywall screen — it handles loading states and purchase UI automatically.

**Testing:** Use a StoreKit configuration file in Xcode (File > New > StoreKit Configuration). This lets you test purchases in the simulator without hitting the App Store. Test via Xcode Debug menu > StoreKit > Manage Transactions.

**Important:** Apple requires a "Restore Purchases" button anywhere a user might need to re-unlock (e.g., after reinstalling). This is a review requirement, not optional.

### SwiftUI — Word Game UI

No third-party UI library needed. The Spelling Bee hex grid is achievable with SwiftUI shapes and GeometryReader. Key components you'll build:

- Hex tile letters: custom `Shape` or styled `ZStack` with hexagonal clip
- Letter input display: `HStack` of `Text` showing assembled word
- Word list: `ScrollView` + `LazyVStack` (not `List` — avoid row separators and extra chrome)
- Score/progress: simple `Text` + `ProgressView`

Avoid SwiftUI animations that require SpriteKit. Stick to `.animation()`, `.transition()`, and `withAnimation {}` — they are sufficient for a word game.

### Word List & Validation

**Use the ENABLE word list.** It is explicitly public domain (compiled by Mendel Cooper), contains ~172,000 English words, and is the de-facto standard for free Scrabble clones, Words With Friends, and Wordle's allowed-guess pool.

Download: https://puzzlecottage.com/data/ (Puzzle Cottage hosts a clean copy)

**Bundle as a plain .txt file** (one word per line) in your Xcode project. Load once at app startup into a `Set<String>`:

```swift
func loadWordSet() -> Set<String> {
    guard let url = Bundle.main.url(forResource: "enable", withExtension: "txt"),
          let content = try? String(contentsOf: url, encoding: .utf8) else {
        return []
    }
    return Set(content.components(separatedBy: .newlines).map { $0.lowercased() }.filter { !$0.isEmpty })
}
```

`Set<String>` gives O(1) lookups. A 172K-word set occupies roughly 3–5 MB in memory — fine for a mobile game.

**Filtering for the puzzle mechanic:** For Spelling Bee-style games, filter the ENABLE list at puzzle generation time to only words that:
1. Are 4+ letters long
2. Contain the center letter
3. Use only letters from the available 7-letter set

Pre-filter on background thread using `async/await` or a background `DispatchQueue`.

**UITextChecker — use sparingly, not as primary validator.** `UITextChecker.rangeOfMisspelledWord(in:range:startingAt:wrap:language:)` validates against Apple's on-device dictionary, which changes across iOS versions and isn't controlled by you. It's useful for confirming a word isn't a proper noun (Apple's dict excludes most proper nouns). Do not use it as the only validator — you'll get inconsistent results across devices.

### Persistence

| Data | Storage | Why |
|------|---------|-----|
| IAP unlock state | `@AppStorage("isPremium")` | Simple Bool, auto-synced with UserDefaults |
| Daily puzzle count | `@AppStorage("dailyCount")` + date key | Reset logic is a handful of lines |
| Current puzzle seed | `@AppStorage("puzzleSeed")` | Deterministic puzzle from seed = easy save/resume |
| Found words this round | In-memory `[String]` | Not worth persisting mid-round; user can restart |
| Historical scores | `@AppStorage` with encoded Data | If you add history, encode a small Codable struct |

Do not reach for SwiftData or Core Data. The data model for this game is simple enough that UserDefaults handles it comfortably and keeps the code dead simple.

### Analytics — TelemetryDeck

Install via Swift Package Manager: `https://github.com/TelemetryDeck/SwiftSDK`

**Free tier:** 100,000 signals/month — more than enough for an indie game at any realistic download volume.

**No consent popup required.** TelemetryDeck hashes user identifiers so no personal data is collected. This is the correct choice for a game that has no sign-in and wants zero privacy friction.

**Minimal setup:**
```swift
// In your App init
TelemetryDeck.initialize(config: .init(appID: "YOUR-APP-ID"))

// Send events
TelemetryDeck.signal("puzzle.completed", parameters: ["wordCount": "\(count)"])
TelemetryDeck.signal("iap.purchase.initiated")
```

Track: app open, puzzle started, puzzle completed, word submitted (valid/invalid), IAP initiated, IAP completed. That's enough signal to understand retention and conversion.

---

## App Store Connect — What to Know for First Submission

### Developer Program
- $99/year Apple Developer Program membership required before submission
- Enroll at developer.apple.com — allow 24–48 hours for approval

### IAP Setup in App Store Connect
1. Create your app record first
2. Navigate to Monetization > In-App Purchases > Create New
3. Type: **Non-Consumable** (not consumable, not subscription)
4. Product ID: use reverse-DNS convention: `com.yourname.wordpuzzle.unlimited`
5. Price: $2.99 (Tier 3 in Apple's pricing grid)
6. You must submit a screenshot of your paywall for IAP review
7. In the Review Notes field, describe exactly how the reviewer finds and triggers the IAP — reviewers reject apps when they can't locate the purchase

### Privacy Nutrition Label
- Apple requires declaring every data type your app (and any SDK) collects
- TelemetryDeck: declare "Device ID" as "used for analytics," not linked to identity
- If you collect nothing else: most fields are "Not Collected"
- A missing or inaccurate privacy label is one of the most common first-submission rejection reasons

### Common Rejection Triggers to Avoid
- No "Restore Purchases" button (required for non-consumable IAP)
- IAP reviewer cannot find the paywall (add step-by-step in Review Notes)
- Encryption export compliance: set `App Uses Non-Exempt Encryption` to `NO` in Info.plist (standard HTTPS doesn't count as "exempt encryption requiring export review")
- Mac and Vision Pro availability auto-checked — uncheck both unless you've tested there
- Insufficient screenshots (provide all required device sizes — Xcode Simulator can generate them)

### Review Timeline
- First submissions typically take 1–3 days
- Subsequent updates: 24–48 hours
- Submit for "Manual Release" so you control launch timing after approval

---

## What NOT to Use

| Avoid | Why |
|-------|-----|
| **TCA (The Composable Architecture)** | Steep learning curve, overkill for a solo dev's first iOS app with a single game mechanic |
| **RevenueCat / Adapty** | Third-party IAP SDKs add cost and dependency for a single non-consumable; StoreKit 2 handles it natively |
| **Firebase Analytics** | Collects extensive personal data, requires consent popups, complex privacy label — wrong fit for a privacy-simple game |
| **Core Data / SwiftData** | Overkill for game state that fits in UserDefaults; adds schema migration complexity you don't need |
| **UITextChecker as sole word validator** | Apple's dictionary varies by iOS version; gives you no control over word list; Spelling Bee games need a defined word set |
| **SOWPODS / Official Scrabble dictionary** | Copyright-restricted; you cannot bundle it commercially without licensing |
| **SpriteKit / Unity** | Project constraint correctly rules these out; SwiftUI handles all UI needs for this mechanic |
| **Game Center** | Added complexity for leaderboards/achievements the project explicitly excludes |
| **Subscription IAP** | More complex backend logic, App Store review scrutiny, and user resistance — one-time purchase is simpler and more honest |
| **URLSession / network calls** | App must work fully offline; no network dependency should exist |

---

## Confidence Levels

| Area | Confidence | Notes |
|------|------------|-------|
| SwiftUI + @Observable MVVM | HIGH | Well-documented, Apple-recommended direction for iOS 17+; multiple sources agree |
| StoreKit 2 non-consumable | HIGH | Official Apple API; CreateWithSwift and Superwall tutorials verified the pattern |
| ENABLE word list | HIGH | Public domain status confirmed; widely used in commercial word games |
| Bundled Set<String> for lookups | HIGH | Standard Swift pattern; O(1) lookup confirmed; memory footprint is acceptable |
| TelemetryDeck as analytics | HIGH | 100K free signals/month confirmed; no consent popup confirmed; Swift SPM package available |
| UserDefaults/@AppStorage for state | HIGH | Correct tool for this data size; SwiftData would be premature |
| UITextChecker as secondary validator | MEDIUM | Works well but Apple's dictionary is not fixed across OS versions; don't rely on it as primary |
| App Store submission steps | MEDIUM | Based on developer blog checklists and Apple docs; review policies can change; verify against current App Review Guidelines before submitting |

---

## Sources

- [SwiftUI @Observable — iOS 17 Observation Framework (Medium, Better Programming)](https://medium.com/better-programming/ios-17-observable-and-the-observation-framework-152deaf8fc5e)
- [TCA vs MVVM in SwiftUI: Which Architecture Should You Choose? (Medium)](https://medium.com/@chathurikabandara0701/tca-vs-mvvm-in-swiftui-which-architecture-should-you-choose-f4cd21315329)
- [iOS Architecture in 2025 (Medium, MuhammedSwalih)](https://medium.com/@muhammedswalihvh/ios-architecture-in-2025-choosing-between-mvvm-mvc-viper-and-more-for-swift-swiftui-01294bd0771f)
- [Implementing Non-Consumable In-App Purchases with StoreKit 2 (Create With Swift)](https://www.createwithswift.com/implementing-non-consumable-in-app-purchases-with-storekit-2/)
- [Mastering StoreKit 2 in SwiftUI (Medium, Dhruvin Bhalodiya)](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46)
- [Validating words with UITextChecker (Hacking with Swift)](https://www.hackingwithswift.com/books/ios-swiftui/validating-words-with-uitextchecker)
- [Word Scramble: Introduction (Hacking with Swift)](https://www.hackingwithswift.com/books/ios-swiftui/word-scramble-introduction)
- [ENABLE Scrabble Dictionary — Open Data (Puzzle Cottage)](https://puzzlecottage.com/data/)
- [Best iOS Analytics SDKs 2026 (TheSwiftKit)](https://theswiftk.it.com/best/best-ios-analytics-sdks)
- [TelemetryDeck SwiftSDK (GitHub)](https://github.com/TelemetryDeck/SwiftSDK)
- [Best iOS Data Storage Options 2025 (Level Up Coding)](https://levelup.gitconnected.com/best-ios-data-storage-options-2025-userdefaults-swift-data-realm-keychain-more-111e9c85672b)
- [@AppStorage vs UserDefaults vs SwiftData (BleepingSwift)](https://bleepingswift.com/blog/appstorage-vs-userdefaults-vs-swiftdata)
- [My checklist before submitting to App Store Connect (Mert Bulan)](https://mertbulan.com/my-checklist-before-submitting-a-new-app-to-app-store-connect/)
- [iOS App Prelaunch Checklist (ScreenFast)](https://screenfast.app/blog/ios-app-prelaunch-checklist)
- [isowords — open source SwiftUI word game (GitHub, Point-Free)](https://github.com/pointfreeco/isowords)
