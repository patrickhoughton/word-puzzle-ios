# Project Research Summary

**Project:** Word Puzzle iOS (Spelling Bee-style)
**Domain:** iOS word puzzle game, free tier + one-time IAP
**Researched:** 2026-08-27
**Confidence:** HIGH

---

## Executive Summary

This is a SwiftUI-native iOS word puzzle game with Spelling Bee mechanics — players find words from a 7-letter set with a required center letter. The right way to build it is with MVVM + Swift's `@Observable` macro, StoreKit 2 for a single non-consumable IAP, the ENABLE word list bundled as a plain text file, and SwiftData for light game history. No game engine, no third-party IAP wrapper, no ad SDK, and no backend are needed. The entire app can be built with Apple-native frameworks, which is both the simplest approach and the one with the fewest App Store compliance risks.

The market position is clear and open: "the unlimited Spelling Bee without the NYT subscription." The NYT charges $17/month for all its games and gives one puzzle per day. The competition (Spellsbee, WordGa) is ad-heavy and low quality. An ad-free, one-time-unlock app with algorithmically generated unlimited puzzles has a genuine structural advantage that costs nothing extra to execute — the cost structure itself is the moat.

The highest risks are not technical. They are App Store compliance (Guideline 4.3 duplicate-app rejection, missing Restore Purchases button, unprepared IAP product at submission time) and scope creep (the app that never ships). The puzzle generation algorithm must be pangram-first with a minimum word count gate — these are architectural decisions that are expensive to change later. Get the word list cleaned of profanity before building anything on top of it.

---

## Key Findings

### Recommended Stack

Build entirely on Apple-native frameworks. SwiftUI targets iOS 17+ to get the `@Observable` macro, which replaces `ObservableObject` with less boilerplate and better render performance. StoreKit 2 handles the non-consumable IAP purchase, verification, and restoration without any third-party SDK. SwiftData handles game history and daily usage tracking. TelemetryDeck (Swift SPM, privacy-first, 100K signals/month free) handles analytics without a consent popup. The ENABLE word list (~173K words, public domain) is bundled as a plain text file and loaded into a `Set<String>` at launch for O(1) word validation.

**Core technologies:**
- SwiftUI + iOS 17 target — native UI, `@Observable` macro, no game engine needed
- MVVM with `@Observable` — correct scope for a solo developer on a single-mechanic game; avoid TCA
- StoreKit 2 — Apple's Swift-first IAP API; no RevenueCat or Adapty needed for one non-consumable product
- ENABLE word list (bundled .txt) — public domain, 173K words, loads into `Set<String>` for O(1) lookup
- SwiftData — typed persistence for game history and daily play count; correct iOS 17+ replacement for CoreData
- `@AppStorage` / UserDefaults — settings (sound, haptics); not for IAP state
- TelemetryDeck (SPM) — privacy-first analytics, no consent popup, free tier sufficient

**Do not use:** TCA, RevenueCat, Firebase Analytics, CoreData, SpriteKit, Game Center, subscription IAP, UITextChecker as sole validator, SOWPODS word list.

### Expected Features

**Must have (table stakes) — required before App Store submission:**
- Instant word validation with clear visual + haptic feedback (color change + shake on invalid)
- Tap-friendly letter tiles with 44pt+ tap targets, tested on SE-size screens
- Real-time score display during play
- End-of-round word discovery screen showing all words the player missed
- Offline-first, zero login required — must work in Airplane Mode
- Clean, distraction-free UI (word puzzle players actively dislike visual noise)
- Consistent puzzle solvability — every generated puzzle must have valid solutions
- Transparent IAP — free tier value is clear before the paywall appears
- Rating prompt at peak satisfaction moments (never on first launch)
- Crash-free launch

**Should have (competitive differentiators) — prioritized for v1:**
- Unlimited puzzle generation — this is the core value proposition; lead with it in screenshots and App Store copy
- Ad-free free tier — "no ads, ever" is a genuine differentiator and a marketing line that converts
- Pangram mechanic — one "use all 7 letters" word per puzzle creates a clear peak goal; low complexity, high engagement
- Streak tracking with loss-aversion mechanics — 40-60% higher DAU; implementation cost is low
- Post-round word discovery with surprising finds — drives replay and organic word-of-mouth

**Defer to v2+:**
- Difficulty-aware puzzle selection or difficulty settings
- Hint system (good IAP complement but adds scope)
- Polished word submission animations (invest if time allows; skip if it blocks launch)
- Puzzle deduplication history across many sessions (basic deduplication is v1; deep history tracking is v2)

**Anti-features to avoid:** interstitial video ads, aggressive IAP prompts on first launch, subscription model, daily-puzzle-only mode, punishing invalid word attempts, required login, complex onboarding tutorial.

**IAP trigger strategy:** Show the paywall when the third free puzzle ends — not before. "Unlock unlimited puzzles, forever. No subscription. No ads." Answer all three questions a player has. Assume 1.5-2% conversion; to hit $100/month requires ~48 purchases. At modest install volumes with strong retention this is achievable.

### Architecture Approach

Five components with clear, single responsibilities cover the entire app. Build bottom-up: data foundation (WordList, Puzzle struct) first, then pure logic (PuzzleGenerator, scoring), then persistence (SwiftData models, PersistenceStore), then entitlements (EntitlementStore wrapping StoreKit 2), then game state (GameSession), and finally all SwiftUI views. Components are isolated: WordList and PuzzleGenerator have zero imports beyond Swift standard library; GameSession has no StoreKit or SwiftData imports; EntitlementStore has no game logic; views talk to components via `@Environment` injection, not singletons.

**Major components:**
1. **WordList** — loads bundled word file once at startup into `Set<String>`; exposes word validation and pangram candidates; read-only, no game state awareness
2. **PuzzleGenerator** — stateless pure logic; takes WordList as input; returns a `Puzzle` struct (7 letters, center letter, solution set, pangrams, max score); uses pangram-first generation with a minimum-word-count quality gate
3. **GameSession** — `@Observable` class holding active puzzle and all mutable in-game state (found words, input, score); ephemeral, not persisted
4. **PersistenceStore** — SwiftData; stores completed game summaries and daily usage count; exposes `puzzlesPlayedToday()` query for free-tier enforcement
5. **EntitlementStore** — `@Observable` StoreKit 2 wrapper; checks `Transaction.currentEntitlements` on every scene activation; publishes `isPremium: Bool`; StoreKit is the source of truth — do not cache isPremium in UserDefaults

**Puzzle generation algorithm:** Pangram-first. Select a random word with exactly 7 distinct letters as the seed; extract the letter set; find all valid words using that set with the center letter required; reject and retry if word count is below 20 or above 100, or if no pangram exists. This approach guarantees a pangram by construction and is fast (<50ms even unoptimized on the full ENABLE list).

### Critical Pitfalls

1. **Pangram-first generation is an architectural decision, not an optimization** — Choosing letter sets randomly without verifying a pangram exists produces hollow puzzles with no peak moment. Changing the generator after game logic is built on top of it is expensive. Decide before writing any code.

2. **Profanity in the word list causes content violations and forced 17+ age ratings** — ENABLE includes vulgar terms because they are valid Scrabble words. Run a blocklist pass (LDNOOBW or equivalent) and remove profane words before bundling the file. This cannot be fixed post-launch without an app update.

3. **Missing Restore Purchases button causes rejection** — Guideline 3.1.1 requires an explicit "Restore Purchases" UI element on every paywall screen regardless of StoreKit 2's automatic restoration behavior. Must call `AppStore.sync()`, not the deprecated SKPaymentQueue method. Absence is grounds for rejection with no workaround.

4. **Paid Applications Agreement must be accepted before any IAP work begins** — This is an App Store Connect business settings step (Agreements, Tax, and Banking) that blocks IAP product creation if skipped. First-time developers frequently discover this at submission time. Do it before writing any StoreKit code.

5. **Scope creep is the highest-risk pitfall for a solo first-time iOS developer** — Every unshipped feature has a real cost. The out-of-scope list is a contract. Launch a working v1 and iterate based on actual player feedback; post-launch data is the only valid source of truth for which features matter.

**Also watch:** Guideline 4.3 duplicate-app rejection (lead with algorithmic unlimited generation as the differentiator; do not use "Spelling Bee" in the app name); dictionary loading on main thread (use background Task); `Array` vs `Set` for word lookup (O(n) vs O(1) — use Set); test on real hardware not just Simulator (memory and performance diverge significantly).

---

## Implications for Roadmap

### Phase 1: Foundation — Word Engine and Puzzle Generation

**Rationale:** Everything else depends on the word list being clean, the data structures being correct, and the puzzle generator being reliable. These decisions are expensive to change later. The generator must be pangram-first with a quality gate from day one — not retrofitted after game logic is built.

**Delivers:** A working puzzle generator that can be unit-tested with no UI; a validated, profanity-filtered word list; confirmed O(1) lookup data structure.

**Addresses:** Core gameplay reliability (table stakes); puzzle solvability guarantee (table stakes); pangram mechanic (high-priority differentiator).

**Avoids:** Pangram-missing puzzle pitfall; too-few-words pitfall; O(n) array lookup pitfall; word list profanity pitfall.

**Research flag:** Standard patterns — no additional research needed. ARCHITECTURE.md provides verified pseudocode and quality gate thresholds.

---

### Phase 2: Persistence and Entitlements

**Rationale:** SwiftData models and the StoreKit 2 entitlement check must be set up before any UI or game session logic is built on top of them. The free-tier gate (daily puzzle count) and the IAP unlock check are the business logic of the app.

**Delivers:** Working SwiftData container with `GameSummary` and `DailyUsage` models; `PersistenceStore` with daily count query; `EntitlementStore` with `Transaction.currentEntitlements` check and `isPremium` published state; sandbox IAP product created in App Store Connect.

**Addresses:** Free tier gating; IAP unlock state management; Restore Purchases foundation.

**Avoids:** Paid Applications Agreement not accepted (accept during this phase, before writing any StoreKit code); IAP product not attached at submission (create product now, not at submission time); UserDefaults caching of isPremium.

**Research flag:** Standard patterns — StoreKit 2 patterns are well-documented with verified code in STACK.md and ARCHITECTURE.md.

---

### Phase 3: Game Session and Core UI

**Rationale:** With the word engine and persistence layer proven, `GameSession` can be built and immediately connected to real SwiftUI views. This phase produces a playable game on a real device.

**Delivers:** `GameSession` observable managing in-game state; `GameBoardView` with hex letter tiles, word input display, found words list; real-time score display; word submission feedback (haptic + animation); end-of-round word discovery screen.

**Addresses:** Instant word validation with feedback (table stakes); tap-friendly tiles (table stakes); real-time score (table stakes); post-round word discovery (table stakes + high-priority differentiator); clean UI (table stakes).

**Avoids:** 44pt minimum tap target requirement; SwiftUI state scattered across multiple sources; testing only on Simulator — install on physical device during this phase.

**Research flag:** Hex tile layout in SwiftUI is achievable but implementation details vary. If layout blocks progress, reference isowords (GitHub: pointfreeco/isowords) as an open-source SwiftUI word game.

---

### Phase 4: Paywall, IAP Flow, and Free Tier Gate

**Rationale:** IAP requires its own focused phase because Apple scrutinizes paywalls carefully and the submission requirements are specific. Building this wrong is a rejection.

**Delivers:** Paywall screen with price shown prominently, "Unlock for $2.99" CTA, Restore Purchases button, Privacy Policy link; `PuzzleGate` logic enforcing 3-free-puzzles-per-day limit; IAP purchase and restore flows fully tested end-to-end in sandbox.

**Addresses:** Transparent IAP value proposition (table stakes); IAP conversion at the natural free-tier limit moment.

**Avoids:** Missing Restore Purchases button (rejection); paywall dark patterns triggering Guideline 3.1.2; thin free tier triggering Guideline 4.2; demo credentials missing from Review Notes.

**Research flag:** Standard patterns — rejection patterns and required paywall elements thoroughly covered in PITFALLS.md.

---

### Phase 5: Retention, Analytics, and App Store Polish

**Rationale:** Streak tracking, TelemetryDeck integration, rating prompts, and App Store metadata are the difference between a game that retains players and one that loses them after one session. Apple's 2026 algorithm weights Day 7 retention above raw downloads — retention features directly affect organic discoverability.

**Delivers:** Streak tracking with loss-aversion display; `SKStoreReviewRequest` at pangram-found and personal-best moments; TelemetryDeck tracking key events; final App Store screenshots from final TestFlight build; privacy nutrition label completed; ASO keyword fields optimized.

**Addresses:** Streak mechanic (high-priority differentiator); rating prompt timing (table stakes for discoverability); ASO for "spelling bee unlimited," "word puzzle offline," "word game no subscription."

**Avoids:** Rating prompt on first launch; screenshots taken from development build (metadata accuracy rejection); using "Spelling Bee" in app name (trademark + Guideline 4.3 risk); Xcode/SDK version too old for submission (must use Xcode 26 + iOS 26 SDK as of April 2026).

**Research flag:** Standard patterns — screenshot strategy and ASO keyword guidance are in FEATURES.md; analytics setup is in STACK.md.

---

### Phase Ordering Rationale

- Word engine first because every other component depends on it and the algorithmic decisions are architectural — they cannot be changed cheaply after game logic and UI are built on top.
- Persistence and entitlements before game session because `GameSession` needs to call `PersistenceStore` and `EntitlementStore`; building them in isolation keeps them unit-testable.
- Game session and core UI third because playability on a real device is the primary validation of the product.
- Paywall fourth because players must experience the game hook before seeing the paywall — the IAP conversion research is explicit on this.
- Retention and polish last because it makes a working game better, but the game must work first.

### Research Flags

Phases with standard patterns (no additional research needed):
- Phase 1 (Word Engine): verified algorithm pseudocode in ARCHITECTURE.md; ENABLE word list confirmed public domain
- Phase 2 (Persistence + Entitlements): StoreKit 2 patterns fully documented with working code
- Phase 4 (Paywall): rejection patterns and required elements thoroughly covered in PITFALLS.md
- Phase 5 (Retention + Polish): ASO strategy and analytics setup covered in FEATURES.md and STACK.md

Phases that may benefit from quick reference during planning:
- Phase 3 (Core UI): hex tile layout implementation — isowords open-source repo is a reference if needed

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All choices are Apple-native; patterns verified against official docs and multiple community sources; no third-party dependencies with uncertain futures |
| Features | MEDIUM-HIGH | Table stakes and anti-features have strong consensus; IAP conversion benchmarks (1.5-2%) are directional only — wide variance in real-world data |
| Architecture | HIGH | Component boundaries are clean; data flow is unambiguous; build order has clear dependency rationale; puzzle generation algorithm verified against known implementations |
| Pitfalls | HIGH | App Store rejection patterns sourced from current guidelines and 2026 developer post-mortems; IAP requirements are Apple-documented |

**Overall confidence:** HIGH

### Gaps to Address

- **Word list curation depth:** ENABLE works as a starting point but may include medical and technical words that frustrate casual players. Time-box the profanity filter to 2 days; do a manual review of common 4-5 letter words; iterate on obscure word removal based on post-launch player feedback rather than pre-launch over-engineering.
- **Puzzle difficulty calibration:** The quality gate (20-100 words per puzzle) ensures playability but does not guarantee consistent difficulty. Playtesting 20+ generated puzzles before launch is required; difficulty scoring can be a v1.1 feature if calibration proves hard.
- **Generation performance on real hardware:** Estimated at <50ms but must be measured on an iPhone 12 or older in production conditions (not Simulator). If it exceeds 500ms, move generation to a background Task with a loading indicator.
- **App Store review policy drift:** Policies cited here are current as of 2026-08-27. Verify against live App Review Guidelines at developer.apple.com before any submission, particularly Guideline 4.3 and 3.1.1.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — StoreKit 2, SwiftData, `@Observable`, App Review Guidelines
- MATHLAB Blog — verified pangram-first generation algorithm
- Hacking with Swift — UITextChecker, word scramble patterns
- ENABLE word list (Puzzle Cottage / MagicOctopusUrn GitHub) — public domain status confirmed

### Secondary (MEDIUM confidence)
- AppFollow, FoxData, Liftoff — ASO and retention benchmarks (2026)
- GameRefinery, ASO World — IAP conversion timing and rate benchmarks
- Swift community sources (Create With Swift, Swift with Majid, Donny Wals, BleepingSwift) — StoreKit 2 and SwiftData patterns
- QAwerk, RevenueFlo, Adapty — App Store rejection patterns and paywall design

### Tertiary (directional only)
- IAP conversion rate benchmarks (0.67-5%) — wide variance; use 1.5-2% for planning only
- Day 7 retention weighting in App Store algorithm (FoxData 2026) — directional; Apple does not publish algorithm details

---
*Research completed: 2026-08-27*
*Ready for roadmap: yes*
