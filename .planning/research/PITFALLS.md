# Pitfalls Research — iOS Word Puzzle Game

**Project:** Word Puzzle iOS (Spelling Bee-style unscramble game)
**Researched:** 2026-08-27
**Developer context:** First-time iOS developer, solo, free + one-time $2.99 IAP

---

## App Store Pitfalls

### CRITICAL: Guideline 4.3 — Spam / Duplicate App Rejection

**What goes wrong:** Apple rejects apps that it considers too similar to existing apps in concept and functionality without meaningful differentiation. Word games are a saturated category. The Spelling Bee mechanic specifically has multiple App Store clones already. Apple's guideline reads: "don't create multiple apps that duplicate the concept of other apps."

**Why it happens:** Reviewers apply 4.3 subjectively. A clone with thin differentiation (different colors, different word list) can be flagged even when the app is genuinely independent.

**Consequences:** App rejected pre-launch. Appeal process can take weeks. Risk of Developer Program removal for repeat offenses.

**Warning signs:** Your app description and screenshots read identically to a competitor's. No differentiation is visible in the first 30 seconds of use.

**Prevention:**
- Lead with the algorithmic generation angle in screenshots and description — this is the real differentiator vs. curated puzzle games
- Do not use the phrase "Spelling Bee" in your app name, subtitle, or keywords (trademark risk + 4.3 risk)
- Make the UI visually distinct — do not copy the NYT honeycomb hex layout pixel-for-pixel
- In your App Review notes, explicitly state what makes this app different (unlimited algorithmic puzzles, offline-first, no subscription)

**Phase to address:** Before any submission — design phase. Solve this in copy and UI before you touch Xcode.

---

### CRITICAL: Privacy Manifest Missing for Third-Party SDKs

**What goes wrong:** Every third-party SDK that uses "required reason APIs" (UserDefaults, file timestamp APIs, disk space APIs, etc.) must include a `PrivacyInfo.xcprivacy` manifest. If any included library is missing one, the binary is automatically rejected — before a human reviewer ever sees the app.

**Why it happens:** Developers add a convenience library (e.g., RevenueCat, Firebase Analytics, Crashlytics) without checking whether it has a current privacy manifest. The requirement has been enforced since May 2024 and tightened in 2025.

**Consequences:** Automated rejection on upload. No human review. No visible rejection message describing the specific SDK — you have to diagnose it yourself.

**Warning signs:** You are using any third-party SDK you did not write yourself.

**Prevention:**
- Audit every dependency before integrating — check the SDK's GitHub releases for a `PrivacyInfo.xcprivacy` file
- Prefer zero-dependency or Apple-native implementations where possible (StoreKit 2 natively, no RevenueCat required for a simple one-time IAP)
- If you use RevenueCat or similar, verify their current privacy manifest status before integrating
- Run `xcprivacy-check` tooling or Xcode's privacy report before every submission

**Phase to address:** Dependency selection phase, before any third-party SDK is added to the project.

---

### HIGH: Metadata Accuracy Violations (Guideline 2.3)

**What goes wrong:** Screenshots, description, or preview video show features that are not in the submitted build, or show a different UI than what ships. Reviewers test the app and compare it to metadata.

**Why it happens:** Screenshots are often made early in development and not updated before submission.

**Consequences:** Rejection for metadata misrepresentation. Must resubmit with corrected screenshots.

**Warning signs:** Screenshots were made more than a few weeks before submission. They show UI that has since changed.

**Prevention:**
- Take final screenshots from the final TestFlight build, not from a development build
- Screenshot required device sizes: iPhone 6.9" (required), iPhone 6.5" (required for older device support)
- Do not show features in screenshots that are not in the free tier without labeling them as premium

**Phase to address:** Pre-submission checklist.

---

### MODERATE: Age Rating and Word Content

**What goes wrong:** Your word list contains profanity, vulgar terms, or sexual words. If a reviewer happens to find (or players report) obscene words in puzzle output, it can trigger a content violation. Even censored profanity counts toward a higher age rating.

**Why it happens:** Public word lists (ENABLE, TWL06, SOWPODS) include profanity and vulgar terms. They are not curated for a general audience.

**Consequences:** Forced age rating of 17+ (kills family audience), or content removal request, or rejection.

**Prevention:**
- Run your word list against a profanity blocklist and remove all matches before bundling
- Also remove offensive proper nouns, slurs, and sexually explicit terms
- Default your app to "4+" content rating — appropriate for a word game with no other content risks
- Keep a log of what you removed and why, in case Apple asks

**Phase to address:** Dictionary preparation — before bundling the word list.

---

### MODERATE: App Store Review Submission Errors

**What goes wrong:** Rejecting/resubmitting the build too quickly after rejection (resets queue position), removing the build instead of addressing the rejection, or fixing the wrong issue and triggering another full review cycle.

**Why it happens:** First-time developers misread rejection notices and act on instinct rather than reading the exact guideline cited.

**Consequences:** Extended review delays. 40-60% of first-time submissions are rejected — most are fixable, but mishandling adds weeks.

**Warning signs:** You are feeling panicked and want to "just fix it and resubmit fast."

**Prevention:**
- Read the exact guideline number in the rejection (e.g., 3.1.1, 4.3, 5.1.1)
- Look up that guideline on developer.apple.com before touching anything
- Use the Resolution Center to ask clarifying questions before resubmitting
- Withdrawing a submission that has no identified issue resets your queue — do not do this
- Run TestFlight beta first to catch review-blockers before production submission

**Phase to address:** First submission.

---

### LOW: Xcode / SDK Version Requirement

**What goes wrong:** As of April 28, 2026, all App Store submissions must be built with Xcode 26 and the iOS 26 SDK. Builds from older Xcode versions are automatically rejected.

**Prevention:**
- Keep Xcode updated — check developer.apple.com/news for SDK requirement announcements before any submission
- macOS Sequoia 15.6+ is required to run Xcode 26

**Phase to address:** Before first submission and before any future update submission.

---

## IAP Implementation Pitfalls

### CRITICAL: Missing Restore Purchases Button

**What goes wrong:** App Store Review Guideline 3.1.1 requires all apps with IAP to implement a "Restore Purchases" mechanism. Missing this button causes rejection.

**Why it happens:** Developers assume StoreKit 2's automatic transaction sync makes a manual restore button unnecessary. It does not — Apple requires an explicit UI affordance regardless of automatic restoration behavior.

**Consequences:** Rejection for failing to implement restore. No workaround — must add the button.

**Warning signs:** You built a paywall screen without a "Restore Purchase" button.

**Prevention:**
- Include a visible "Restore Purchase" link/button on every paywall screen
- The button should call `AppStore.sync()` in StoreKit 2 (not the old `SKPaymentQueue.restoreCompletedTransactions()`)
- Test restore behavior in sandbox: buy, delete app, reinstall, tap restore — confirm the unlock is restored
- Do not hide the restore button in a settings menu — it must be accessible from the paywall

**Phase to address:** Paywall implementation sprint.

---

### CRITICAL: IAP Product Not Attached at Submission

**What goes wrong:** When submitting an app with IAP for the first time, the IAP product must be created in App Store Connect and attached to the app version before submission. If it's missing or not yet approved, the reviewer cannot test the purchase flow.

**Why it happens:** Developers create the IAP product in App Store Connect but forget to link it to the app version, or submit before the product reaches "Ready to Submit" status.

**Consequences:** Rejection because the reviewer cannot test the purchase. Common first-time mistake.

**Warning signs:** You haven't tested your IAP product in sandbox yet. The product status in App Store Connect is not "Ready to Submit."

**Prevention:**
- Create the IAP product in App Store Connect at the start of IAP development, not at submission time
- Verify product status is "Ready to Submit" before submitting the app
- Test the full purchase flow in sandbox: buy, close app, restore — all must work
- Provide the reviewer with sandbox credentials in the App Review notes (required if your app has a free tier gating)

**Phase to address:** IAP implementation sprint, well before submission.

---

### CRITICAL: Paid Applications Agreement Not Accepted

**What goes wrong:** IAP cannot be submitted until the account holder has accepted Apple's Paid Applications Agreement in App Store Connect under Agreements, Tax, and Banking. If this is not done, IAP product creation is blocked and the app cannot have IAP.

**Why it happens:** It's a one-time setup step that first-time developers often miss because it's not in Xcode — it's in App Store Connect's business settings.

**Consequences:** Cannot create IAP products at all. Discovered late, it delays the entire submission.

**Warning signs:** You have never done this step. Check now.

**Prevention:** Complete this step before writing any StoreKit code. It also requires bank account and tax information.

**Phase to address:** Project setup, before IAP development begins.

---

### HIGH: Paywall Design Triggering Guideline 3.1.2

**What goes wrong:** Apple rejects paywalls that use dark patterns — pre-selecting the most expensive tier, hiding free trial terms, using vague CTA text like "Continue" that doesn't indicate a purchase, or showing a misleading monthly price for something billed annually.

**Why it happens:** Developers optimize for conversion without realizing Apple's reviewers are looking for manipulation.

**Specific patterns that cause rejection:**
- Toggle that hides free trial by default (explicitly called out by Apple in recent reviews)
- "$X/month" displayed large when the actual charge is annual upfront
- "Continue" or "Enter" button that initiates a purchase without making it clear
- No pricing shown until after tapping a CTA

**Prevention:**
- Show exact price prominently before the purchase CTA
- CTA text must match the action: "Unlock for $2.99" not "Get Started"
- For one-time IAP (this project): show "$2.99 one-time" clearly on the paywall
- Include Privacy Policy and Terms links on the paywall screen (even if just tappable text links)
- Include the Restore Purchases button (see above)

**Phase to address:** Paywall design and implementation.

---

### HIGH: Thin Free Tier Violating Guideline 4.2

**What goes wrong:** If the free tier offers essentially no usable value — effectively a login screen or demo that immediately blocks the user — Apple can reject under Guideline 4.2 (Minimum Functionality). The free experience must be genuinely functional.

**Why it happens:** Developers set the free tier limit so low (e.g., 1 puzzle) that it reads as a bait-and-switch.

**Consequences:** Rejection requiring redesign of the free tier.

**Prevention:**
- 3 free puzzles per day is a reasonable free tier — provides real value without giving away the whole product
- The free experience must feel like a complete game, not a demo
- Do not artificially degrade quality in the free tier (e.g., showing ads on every word submission)

**Phase to address:** Free tier design, before submission.

---

### MODERATE: External Payment Link Violations

**What goes wrong:** Any link to an external website for payment, any mention of a lower price elsewhere, or any "subscribe on our website" button for digital goods causes immediate rejection under Guideline 3.1.1.

**Prevention:**
- No external payment links anywhere in the app
- No "cheaper on our website" language in any in-app text
- No "purchase on [website]" prompts

**Phase to address:** UI/copy review before submission.

---

## Puzzle Generation Pitfalls

### CRITICAL: Letter Sets That Produce Too Few Valid Words

**What goes wrong:** Your generation algorithm picks a random 7-letter set, and after filtering the dictionary, only 3-5 valid words exist. Players solve the puzzle in 60 seconds and feel cheated.

**Why it happens:** Word density in English is highly uneven across letter combinations. Common letters (E, A, R, S, T) produce dense word sets; uncommon combinations produce sparse ones. Random selection without a quality gate will produce bad puzzles frequently.

**Warning signs:** No minimum word count check in the generator. No playtesting across 100+ generated puzzles.

**Prevention:**
- Enforce a minimum word count threshold (e.g., at least 15 valid words per puzzle, ideally 25+)
- Reject letter sets that don't meet the threshold and generate a new one — this is fast computationally
- Track the distribution: run 1,000 simulated puzzles offline and graph word counts to find your floor
- Consider avoiding the letter S as the NYT does — it eliminates plural trivially derived words and keeps quality higher

**Phase to address:** Puzzle engine development, before any playtest.

---

### CRITICAL: No Pangram Guarantee

**What goes wrong:** A Spelling Bee-style puzzle with no pangram (a word using all 7 letters) feels hollow. Players expect one. Without it, the puzzle has no "peak moment" and feels incomplete.

**Why it happens:** Generator picks letter sets randomly without verifying a pangram exists in the dictionary.

**Warning signs:** Generator does not explicitly search for a pangram word before accepting a letter set.

**Prevention:**
- Use a pangram-first generation strategy: select a word from the dictionary that uses exactly 7 distinct letters, extract those letters as your set, designate the center letter, then find all valid words
- This guarantees a pangram by construction rather than by luck
- Store a precomputed index of all pangram-eligible words (7 distinct letters, common enough to be satisfying) to make generation fast

**Phase to address:** Core algorithm design — this is an architectural decision, not an optimization.

---

### HIGH: Center Letter Selection Producing Unsolvable Puzzles

**What goes wrong:** You pick a valid 7-letter set with a pangram, but then pick the wrong center letter — one that appears in very few words. Result: technically valid puzzle, extremely sparse word list, frustrating player experience.

**Why it happens:** Center letter is chosen randomly after letter set is selected.

**Prevention:**
- After selecting a 7-letter set, evaluate each of the 7 letters as a potential center letter
- Count valid words for each candidate center letter
- Select the center letter that maximizes valid word count (or pick from candidates above your minimum threshold)
- This adds negligible computation time

**Phase to address:** Puzzle engine development.

---

### HIGH: Inappropriate or Offensive Words in Puzzle Output

**What goes wrong:** A valid word in your dictionary is a slur, profanity, or sexually explicit term. It appears in a puzzle. A player sees it. This generates 1-star reviews, reports to Apple, and potential content violation.

**Why it happens:** Public word lists (ENABLE, TWL, SOWPODS) include profane and vulgar words because they are valid Scrabble words.

**Prevention:**
- Maintain a separate blocklist of words to exclude from puzzle display (separate from the validation dictionary — you may want to accept them as valid player submissions without displaying them as answers)
- Run your word list through an established profanity filter list (e.g., LDNOOBW or similar) before bundling
- Manually review the most common short words (4-5 letters) in your dictionary — these appear most often

**Phase to address:** Dictionary preparation, before puzzle engine is built on top of it.

---

### MODERATE: Duplicate Puzzle Problem

**What goes wrong:** With a small dictionary or naive generation, the same letter set appears twice within a session or across sessions close together. Players notice.

**Why it happens:** No deduplication or history check in the generator.

**Prevention:**
- Track recently played letter sets (store hashed letter set in UserDefaults)
- Exclude recently seen sets from generation for at least N puzzles (e.g., last 30)
- The combinatorial space for 7-letter sets from a large dictionary is large enough that this is easy to implement

**Phase to address:** Puzzle engine development.

---

### MODERATE: Puzzle Difficulty Not Calibrated

**What goes wrong:** All generated puzzles are either too hard (obscure letter sets, few common words) or all easy (common letters, word count > 100). No range = players either give up or breeze through with no challenge.

**Prevention:**
- Categorize generated puzzles by word count and common-word ratio before presenting them
- Consider a difficulty scoring system and present a mix across sessions
- Playtest across at least 20 different generated puzzles before launch

**Phase to address:** Puzzle engine refinement before launch.

---

## Performance Pitfalls

### HIGH: Blocking Main Thread on Dictionary Load

**What goes wrong:** App loads the full word list synchronously at launch on the main thread. iPhone freezes for 1-3 seconds on cold start. iOS may terminate the app if launch takes too long (watchdog timer).

**Why it happens:** The simplest implementation reads the file and builds data structures synchronously in `@main` or `init()`.

**Warning signs:** App feels slow to first interaction. Instruments shows main thread CPU spike at launch.

**Prevention:**
- Load the dictionary on a background thread using `Task { }` or `DispatchQueue.global()`
- Show a brief loading state if needed (rare for well-optimized dictionaries)
- Measure actual load time on an older device (iPhone 12 or earlier) — not just the simulator or a new iPhone

**Phase to address:** Dictionary loading implementation.

---

### HIGH: Wrong Data Structure for Word Lookup

**What goes wrong:** Dictionary is stored as an `[String]` array. Validation checks `array.contains(word)`, which is O(n) — scanning 170,000 words every submission. On older iPhones, this causes perceptible lag on every word submission.

**Why it happens:** Array is the obvious first choice.

**Prevention:**
- Store validated words in a `Set<String>` for O(1) lookup — this is the correct structure for this use case
- For puzzle generation (prefix matching, anagram enumeration), consider a Trie — O(k) where k is word length, efficient for generating all words from a letter set
- Benchmark on real hardware: submit 50 words rapidly and measure response time

**Phase to address:** Dictionary data structure design — before any game logic is built on top of it.

---

### MODERATE: App Bundle Size Bloat

**What goes wrong:** Bundling a large word list as plain text (one word per line) inflates the app download size unnecessarily. A 170,000-word list is ~1.7MB as plain text — not catastrophic, but not optimal.

**Prevention:**
- Use a binary format or compressed text (zlib/gzip) for the dictionary file — iOS can read from compressed bundles
- A DAWG (Directed Acyclic Word Graph) reduces a 170,000-word list to roughly 300KB in RAM and a similarly small file
- Alternatively, a sorted plain-text file compressed with gzip is ~400KB and decompresses fast on device
- Target total app size under 50MB to qualify for cellular download without Wi-Fi prompt

**Phase to address:** Dictionary preparation and bundling.

---

### MODERATE: Memory Spike During Puzzle Generation

**What goes wrong:** Puzzle generator creates many intermediate word sets (arrays, copies) without releasing them, causing memory to spike. On low-memory iPhones, iOS terminates the app in the background.

**Why it happens:** Naive puzzle generation enumerates all permutations or creates many temporary collections.

**Prevention:**
- Use generators/sequences instead of materializing large intermediate arrays
- Profile with Instruments (Allocations template) during a generation cycle
- Target < 50MB peak memory for the entire app on an iPhone 12

**Phase to address:** Puzzle engine optimization, before launch.

---

### LOW: Slow Startup on Older iPhones (Launch Time Watchdog)

**What goes wrong:** iOS kills apps that take too long to become responsive after launch. Apple's threshold is approximately 20 seconds, but user experience degrades after 2-3 seconds.

**Prevention:**
- Defer all non-critical work (puzzle pre-generation, analytics init) to after first frame renders
- Lazy-load the dictionary: show the game UI shell immediately, load dictionary in background
- Profile launch time with Instruments (Time Profiler) on an iPhone 12 or older

**Phase to address:** Performance pass before submission.

---

## First-Time Developer Pitfalls

### CRITICAL: Scope Creep Before First Launch

**What goes wrong:** Developer adds features (daily challenge mode, leaderboards, stats screen, custom themes, hints system, tutorial) before shipping. App never launches because "it's not ready."

**Why it happens:** Each feature feels essential in isolation. Without a shipping deadline, there's always one more thing.

**Consequences:** The app that generates $0 forever is the one that never ships. Post-launch feedback is the only valid source of truth for what features matter.

**Warning signs:** You are building features that are explicitly listed as "Out of Scope" in PROJECT.md. You are refactoring code you wrote last week.

**Prevention:**
- Treat the Out of Scope list as a contract — features there require explicit renegotiation to add
- Set a concrete launch date and work backward to cut scope, not extend dates
- Define "done" for each feature before starting it — if it doesn't have a done condition, it's not a feature, it's a direction
- The simplest version of each requirement ships first; polish comes in v1.1

**Phase to address:** Every phase. This never goes away.

---

### HIGH: Perfection Paralysis on SwiftUI / Swift Idioms

**What goes wrong:** First-time iOS developer spends days researching the "right" way to architect a SwiftUI app (MVVM vs. TCA vs. MV pattern), watching WWDC videos, and rewriting working code to be more idiomatic. Game logic is correct but is never finished.

**Why it happens:** iOS has many architectural options and strong opinions in the community. New developers feel they need to understand all of them before committing.

**Prevention:**
- Pick one pattern and ship with it — MVVM with `@ObservableObject` is the most documented for SwiftUI and appropriate for this app's complexity
- Do not refactor architecture mid-project unless a concrete bug requires it
- "Good enough to ship" is an engineering value, not a compromise

**Phase to address:** Architecture decision — make it once, early, and do not revisit it.

---

### HIGH: Not Testing on Real Hardware

**What goes wrong:** Developer tests exclusively on the iOS Simulator. Ships an app that:
- Crashes on iPhone 12 due to memory pressure (simulator has much more RAM)
- Has layout issues on actual screen sizes
- Has keyboard behavior that differs from simulator
- Has performance that is 3x worse than simulator suggests

**Why it happens:** Simulator is convenient and requires no provisioning setup.

**Prevention:**
- Get a physical test device working via USB within the first week of development
- Test on at least one "older" device (iPhone 12 is a good minimum target for 2026)
- Run every feature on device before considering it done
- TestFlight beta on your own device before any App Store submission

**Phase to address:** Development setup, first week.

---

### HIGH: Provisioning Profile / Signing Certificate Confusion

**What goes wrong:** Developer cannot get the app to build for a physical device, cannot create a distribution archive, or cannot upload to App Store Connect because of signing misconfigurations. This is the #1 time sink for first-time iOS developers that has nothing to do with the app itself.

**Why it happens:** Apple's code signing system (certificates, provisioning profiles, bundle IDs, entitlements) is complex and poorly documented for beginners. Xcode's automatic signing helps but breaks in non-obvious ways.

**Consequences:** Can block TestFlight and App Store submission entirely. Takes hours to diagnose if you don't know what you're looking for.

**Prevention:**
- Use Xcode's automatic signing for development — do not manually manage provisioning profiles
- For distribution, use "Automatically manage signing" in the archive scheme as well
- Verify your Apple Developer account is active and the $99/year fee is paid
- Do a test archive and upload to App Store Connect with a placeholder app early in development — before you need it for a real submission

**Phase to address:** Development setup, before you need it. Do not wait until submission day.

---

### HIGH: Missing Demo Credentials for App Review

**What goes wrong:** Your app has a "free tier" (3 puzzles/day). The reviewer opens the app, plays 3 puzzles, hits the paywall, and cannot proceed to test the IAP — because they can't easily simulate a fresh sandbox account in the review environment. Reviewer cannot complete their testing. Rejection for "unable to evaluate app."

**Why it happens:** Developers forget that reviewers cannot buy IAP without sandbox credentials and cannot bypass paywalls without a demo path.

**Prevention:**
- Provide sandbox test account credentials in the App Review Notes field during submission
- Consider adding a hidden "reviewer mode" or at minimum ensure your sandbox IAP works correctly and you've documented it
- Test your sandbox IAP end-to-end from a fresh simulator/device before submission

**Phase to address:** Pre-submission checklist.

---

### MODERATE: SwiftUI State Management Complexity

**What goes wrong:** Game state (current puzzle, found words, score, premium status) scattered across multiple `@State`, `@EnvironmentObject`, and `@AppStorage` variables that get out of sync. Hard to debug mid-game state bugs.

**Prevention:**
- Define a single `GameState` observable object early
- Premium unlock status stored in one place only — `@AppStorage` backed by `UserDefaults`, verified against StoreKit transaction state on launch
- Do not duplicate state — if `foundWords` is stored in two places, they will eventually diverge

**Phase to address:** Core architecture, before game logic is built.

---

### MODERATE: Ignoring Annual iOS Update Cycle

**What goes wrong:** App ships and works. Six months later, iOS X releases and something breaks — a deprecated API, a SwiftUI behavior change, a UI regression. Developer has "limited post-launch time" and doesn't notice for weeks. App gets 1-star reviews.

**Prevention:**
- Subscribe to Apple Developer news for API deprecation notices
- Run your app against iOS beta when it releases each June — takes an afternoon
- Avoid deprecated APIs from the start: check the Xcode deprecation warnings as you code
- Build the app with zero Xcode warnings before shipping

**Phase to address:** Ongoing. Budget a few hours annually for OS update compatibility.

---

### LOW: Over-Engineering the Word List

**What goes wrong:** Developer spends weeks debating which word list to use (TWL06 vs. ENABLE vs. SOWPODS vs. custom), building elaborate NLP pipelines, adding word frequency weighting, removing obscure words, adding definitions. None of this affects the v1 player experience.

**Prevention:**
- Use ENABLE (170,930 words, public domain, no license issues) as your starting point
- Clean it (remove profanity, very short words < 4 letters, proper nouns)
- Ship. Iterate the word list based on player feedback about unfair words or missing common words

**Phase to address:** Dictionary preparation. Time-box to 2 days maximum.

---

## Prevention Summary

Prioritized by impact on launch success. Address in this order.

### Before Writing Any Code

1. **Accept Paid Applications Agreement** in App Store Connect (required for IAP — blocks all IAP work if missing)
2. **Zero-dependency first pass** — prefer Apple-native APIs (StoreKit 2, UserDefaults, SwiftUI) to avoid privacy manifest issues
3. **Profanity-filter your word list** — cannot be fixed post-launch without an update; affects age rating and content violations

### During Core Development

4. **Pangram-first puzzle generation** — this is an architectural decision; changing it later requires rebuilding the engine
5. **Minimum word count gate** — enforce before any playtest; bad puzzles poison early feedback
6. **Set<String> for word lookup** — set the data structure before game logic is built on top of it
7. **Background thread dictionary load** — if you load on main thread, performance is baked in and hard to fix

### Before TestFlight Beta

8. **Test on real hardware** — simulator gives false confidence; find a physical iPhone 12 or older
9. **Restore Purchases button** — must be on the paywall; rejection otherwise
10. **IAP product created in App Store Connect** — must be "Ready to Submit" status; takes time to set up

### Before App Store Submission

11. **Final screenshots from final build** — must match what the reviewer sees
12. **Sandbox IAP end-to-end test** — buy, delete, reinstall, restore — all must work
13. **Privacy manifest audit** — if you added any third-party SDK, verify its manifest exists
14. **App Review Notes with sandbox credentials** — reviewer cannot test past the paywall otherwise
15. **Guideline 4.3 differentiation check** — your description must clearly articulate what makes this app different from existing Spelling Bee clones

### Ongoing After Launch

16. **Annual iOS update compatibility check** — a few hours every June when beta drops
17. **Scope control** — every "small" feature addition costs time that does not compound toward passive income; protect your time budget ruthlessly

---

## Sources

- [App Store Rejection Reasons 2026 — QAwerk](https://qawerk.com/blog/app-store-rejection-reasons/)
- [App Store Review Guidelines — Apple Developer](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Manifest Files — Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Implement Proactive In-App Purchase Restore — WWDC22](https://developer.apple.com/videos/play/wwdc2022/110404/)
- [StoreKit 2 Restore Purchases — tanaschita.com](https://tanaschita.com/20231009-restore-in-app-purchases-storekit/)
- [How to Design an iOS Paywall — Adapty](https://adapty.io/blog/how-to-design-ios-paywall/)
- [Common iOS Paywall Rejections — RevenueFlo](https://revenueflo.com/blog/common-ios-paywall-rejections-and-the-fixes-that-work/)
- [Guideline 4.3 Spam — Apple Developer Forums](https://developer.apple.com/forums/thread/652386)
- [What Shipping Real iOS Apps Taught Me — Nerdbot](https://nerdbot.com/2026/07/29/what-shipping-real-ios-apps-taught-me-that-no-course-could/)
- [The Spelling Bee Minimum Word Count — SpellingBeeTimes](https://spellingbeetimes.com/2026/06/06/the-spelling-bee-minimum-word-count-why-some-puzzles-have-fewer-valid-words-than-others/)
- [Trie Data Structure in Swift — Kodeco](https://www.kodeco.com/books/data-structures-algorithms-in-swift/v4.0/chapters/18-tries)
- [Effective Memory Optimization — MoldStud](https://moldstud.com/articles/p-effective-memory-optimization-strategies-for-handling-large-data-sets-in-swift)
- [iOS 26 SDK Mandatory — DEV Community](https://dev.to/arshtechpro/ios-26-sdk-is-now-mandatory-here-is-what-actually-changes-for-your-app-39m4)
- [Scope Creep: Silent Killer of Solo Indie Development — Wayline](https://www.wayline.io/blog/scope-creep-solo-indie-game-development)
- [Top 5 ASO Mistakes — ScaleBay](https://www.scalebay.io/blog/avoid-these-5-major-aso-mistakes-from-poor-keyword-use-to-weak-icons-and-start-converting-more-users-from-the-app-stores-today)
- [Age Ratings Values and Definitions — Apple Developer](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
