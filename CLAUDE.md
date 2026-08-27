<!-- GSD:project-start source:PROJECT.md -->
## Project

**Word Puzzle iOS**

A Spelling Bee-style word unscramble game for iPhone. Players are presented with a set of letters and must find as many valid words as possible using those letters, with algorithmically-generated puzzles so there is always something new to play. The app is free to download with a one-time in-app purchase to unlock unlimited gameplay.

**Core Value:** Endless, fresh word puzzles that generate algorithmically from a local dictionary — no internet, no content team, no ongoing maintenance.

### Constraints

- **Platform**: iOS only — SwiftUI, no game engine (SpriteKit/Unity), native approach
- **Backend**: None — all puzzle logic and word lists are local to the app
- **Solo developer**: No team, scope must be shippable by one person
- **App Store**: Must comply with Apple Review Guidelines for games and IAP
- **No ongoing content**: Puzzle generation must be fully algorithmic
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

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
## Architecture Pattern
### Why MVVM + @Observable
- A `GameViewModel` owning puzzle state (letters, found words, score, time)
- A `PurchaseManager` (or `StoreManager`) owning IAP state
- Simple SwiftUI views consuming both
### Why NOT TCA (The Composable Architecture)
- A steep learning curve (reducers, effects, stores, testing infrastructure)
- Slower compile times at scale
- A dependency on a third-party package that must be kept current
- Far more code than the problem warrants
## Key APIs & Frameworks
### StoreKit 2 — Non-Consumable IAP
### SwiftUI — Word Game UI
- Hex tile letters: custom `Shape` or styled `ZStack` with hexagonal clip
- Letter input display: `HStack` of `Text` showing assembled word
- Word list: `ScrollView` + `LazyVStack` (not `List` — avoid row separators and extra chrome)
- Score/progress: simple `Text` + `ProgressView`
### Word List & Validation
### Persistence
| Data | Storage | Why |
|------|---------|-----|
| IAP unlock state | `@AppStorage("isPremium")` | Simple Bool, auto-synced with UserDefaults |
| Daily puzzle count | `@AppStorage("dailyCount")` + date key | Reset logic is a handful of lines |
| Current puzzle seed | `@AppStorage("puzzleSeed")` | Deterministic puzzle from seed = easy save/resume |
| Found words this round | In-memory `[String]` | Not worth persisting mid-round; user can restart |
| Historical scores | `@AppStorage` with encoded Data | If you add history, encode a small Codable struct |
### Analytics — TelemetryDeck
## App Store Connect — What to Know for First Submission
### Developer Program
- $99/year Apple Developer Program membership required before submission
- Enroll at developer.apple.com — allow 24–48 hours for approval
### IAP Setup in App Store Connect
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
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
