# Features Research — iOS Word Puzzle Game

**Domain:** Spelling Bee-style iOS word puzzle, free + one-time IAP
**Researched:** 2026-08-27
**Confidence:** MEDIUM — ecosystem findings verified across multiple sources; specific conversion benchmarks LOW confidence due to wide variance in real-world data

---

## Table Stakes (Must Have)

Missing any of these causes 1-star reviews or immediate uninstall. Treat as non-negotiable before App Store submission.

| Feature | Why It's Expected | Complexity | Notes |
|---------|-------------------|------------|-------|
| Instant word validation with clear feedback | Players expect immediate, unambiguous signal on valid/invalid words — visual color change + haptic + sound | Low | Failure here is the #1 UX frustration cited in reviews across spelling bee alternatives |
| Readable, tap-friendly letter tiles | Buttons too close together is a top-cited cause of negative reviews; tap targets must be generous | Low | 44pt minimum tap target per Apple HIG; test on small (SE-size) screens |
| Score display updated in real time | Players track progress continuously; a static score is confusing | Low | Show running score + word count during play |
| Word list visible after round ends | Players want to see what words they missed — this is the "aha" moment | Low | Show all valid words with definitions if possible; drives replay desire |
| Offline-first, no login required | Players install word games during commutes, flights, low signal; requiring a network or account kills reviews | Low | You already planned this — confirm it works in Airplane Mode before submission |
| Visually clean, distraction-free UI | Word puzzle players skew older and literacy-focused; they hate visual noise, busy animations, gratuitous effects | Low-Med | Simple is a feature, not a compromise |
| Stable, no crashes | Performance issues destroy a game faster than bad design; a single crash during a session earns a 1-star review | Low | Crash-free launch is table stakes; use Xcode Organizer or Firebase Crashlytics from day one |
| Consistent puzzle solvability | Every generated puzzle must have valid solutions, including the required-center-letter words | Med | Validate your generation algorithm thoroughly; unsolvable puzzles are heavily criticized |
| Clear IAP value proposition | Players must understand what the free tier gets them and what they're buying before the IAP prompt | Low | Transparent paywalls earn trust; surprise paywalls earn refund requests |
| Rating prompts at natural moments | App Store rating is critical for discoverability; apps below 4.0 stars see dramatically fewer downloads | Low | Use SKStoreReviewRequest at peak satisfaction moments (solved a hard word, finished a round) — never on first launch |

---

## Differentiators (Competitive Advantage)

These features separate successful word games from the dozens that go unnoticed. For a solo developer, pick one or two to execute well rather than all of them.

| Feature | Why It Converts | Complexity | Priority for This Project |
|---------|-----------------|------------|--------------------------|
| Truly unlimited puzzle generation | The NYT Spelling Bee is one puzzle/day behind a subscription. Alternatives like Spellsbee and WordGa offer "unlimited mode" as their primary selling point. This is your core value prop — lean into it hard in marketing and App Store copy. | Med | HIGH — already planned, must be front-and-center in screenshots and description |
| No ads whatsoever (free tier is ad-free) | 42% of mobile gamers now filter for "no ads" before installing. An ad-free free tier is a genuine differentiator and earns trust before the IAP prompt. Revenue comes from the unlock, not ad impressions. | Low | HIGH — lean into this; "no ads, ever" is a marketing line that converts |
| Progress summary / word discovery moment | Showing users the words they missed, especially rare or surprising ones, creates a shareable "I can't believe that's a word" moment. This is retention-critical and drives organic word-of-mouth. | Low-Med | HIGH — high payoff, low cost |
| Difficulty-aware puzzle selection | Offer a difficulty setting (or auto-grade puzzles by letter combination complexity). Players want a mental workout calibrated to their level. | Med | MEDIUM — adds scope but meaningfully increases satisfaction |
| Streak tracking with loss-aversion mechanics | Apps combining streak + milestone mechanics see 40-60% higher DAU. A 7-day streak makes players 2.3x more likely to open the app daily. This is the single highest-ROI retention feature for a word game. | Low-Med | HIGH — implement even for v1; the code cost is low, the retention return is enormous |
| Satisfying, polished word submission animation | The "oddly satisfying" moment of a word snapping into place or tiles shuffling is cited frequently in positive reviews of Wordscapes and similar games. Players share screenshots of these moments. | Med | MEDIUM — invest here if time allows; skip if it blocks launch |
| Pangram / bonus word highlight | NYT Spelling Bee's "pangram" mechanic (using all letters) creates a memorable achievement goal. Having one special target per puzzle dramatically increases session length. | Low | HIGH — low complexity, creates a clear goal that keeps players engaged |
| Hint system (freemium-friendly) | A limited hint-per-day system serves two purposes: (1) reduces frustration for stuck players, (2) creates a natural upsell moment ("get unlimited hints with Premium"). | Low-Med | MEDIUM — good IAP complement but adds scope |

---

## Anti-Features (Avoid)

These features appear in competitor apps and consistently generate negative reviews, lower ratings, or lost revenue. Treat this list as a constraint.

| Anti-Feature | Why It Hurts | What to Do Instead |
|--------------|--------------|-------------------|
| Interstitial video ads in the free tier | Ads cause screen glitches, crashes, and are the #1 cited reason for 1-star reviews in word games. Ad revenue on a small install base is negligible; the reputational damage is permanent. | Use the IAP as your only revenue stream. An ad-free experience is itself a selling point. |
| Aggressive IAP prompts on first launch | Showing the purchase screen before the player has experienced value causes immediate dismissal and conditions them to ignore future prompts. 25% of first IAP conversions happen by Day 2 — the player needs to feel the hook first. | Show the paywall when the player hits the daily free puzzle limit naturally, not before. |
| Requiring an account or login | Word game players expect to pick up and play. Any friction before gameplay — especially account creation — causes abandonment. No login required is a feature. | Store all state locally. If you ever add cloud sync, make it optional. |
| Subscription model (for a solo dev) | Subscriptions require ongoing content/value to justify renewal. You have no content team. A recurring charge for an algorithmically-generated puzzle game feels exploitative and earns refund requests. | Stick with the one-time unlock. "Pay once, play forever" is an honest, trustworthy value prop that fits the product. |
| Random, frequent haptic feedback | Poorly calibrated haptics feel like bugs, not features. Vibration on every letter tap becomes annoying within one session. | Use haptics sparingly: valid word submission, invalid word shake, round completion. Let users turn haptics off in Settings. |
| Copying too many NYT Spelling Bee UI patterns | Being visually derivative invites comparison — and you'll lose. Players who want the NYT version will go use the NYT version. | Develop your own visual identity. Different color palette, different tile shape. Compete on "unlimited + free" not "looks like NYT." |
| Daily puzzle only (no replay / unlimited mode) | The alternatives to NYT Spelling Bee exist specifically because players want more than one puzzle per day. Locking to daily-only defeats your differentiator. | Make unlimited mode the core product; the daily limit is only the free tier constraint. |
| Obscure or inconsistent word dictionary | Players will submit real words and be rejected. Every invalid rejection of a legitimate word causes frustration and reviews. The flip side: accepting made-up words breaks trust. | Use a well-known, comprehensive word list (ENABLE, TWL, or SOWPODS). Be transparent in the App Store description about which dictionary you use. |
| Punishing invalid word attempts | Some games deduct points or end the session for wrong guesses. Word game players are explorers — they test words. Punishment kills the playful mood. | Silent rejection (shake animation, no score deduction) is the correct pattern. |
| Complex onboarding tutorial | Word puzzle game players understand the genre. A mandatory 5-screen tutorial before first play causes abandonment. | Show rules inline on first launch only — a single dismissible overlay. Let them play immediately. |

---

## IAP Conversion Insights

**Price point:** $2.99 is appropriate. It is below the psychological "thinking too hard about it" threshold for a casual game, and it is a standard one-time unlock price in the App Store word game category. Do not go below $1.99 — it signals low quality. Do not go above $4.99 — the NYT Games subscription competes at that level.

**What actually triggers the purchase:**

1. Hitting the free tier limit at peak engagement. The player is mid-flow, enjoying themselves, and encounters the daily limit. This is the highest-converting moment. Do not show the paywall until this moment occurs naturally — not before.

2. Clear, honest value communication. "Unlock unlimited puzzles, forever. No subscription. No ads." These three sentences answer every question a player has about the purchase. Use them verbatim or close to it.

3. Social proof at the paywall. If you have ratings, show them. "4.8 stars, 2,400 ratings" on the paywall screen increases conversion. This means getting ratings early matters.

4. Loss aversion framing. "You've solved 3 puzzles today. Unlock unlimited play to keep going." Surfacing what they'll lose (the session momentum) is more effective than listing what they'll gain.

**Timing rules:**
- Never prompt on first session
- Never prompt on the second puzzle (too early)
- Prompt when the third free puzzle ends — the player has demonstrated commitment
- Re-surface the paywall once per day if not purchased; no more
- 77% of IAP conversions happen within the first two weeks — if a player doesn't convert in two weeks, more prompts will not change that

**Conversion rate expectations:** Real-world indie free-to-IAP games see 0.67%–5% conversion of active users. For planning purposes: assume 1.5–2%. At $2.99 with Apple's 30% cut, each conversion nets ~$2.09. To hit $100/month you need roughly 48 purchases per month. That is achievable with a modest active user base if retention is strong.

**What does not work:**
- Time-limited "sale" pressure on a permanent one-time purchase feels manipulative
- Offering the IAP as a bundle with consumable items complicates the value prop; keep it clean
- In-game currency systems create psychological overhead that the target audience (casual, literacy-focused) will disengage from

---

## ASO & Discovery

**Search behavior insight:** Word game players search by feeling, mechanic, and comparison ("like NYT spelling bee," "word puzzle offline," "word game no internet"). They do not search by technical feature.

**High-value keywords for this app:**
- Primary: "word puzzle," "spelling bee," "word game offline"
- Secondary: "word unscramble," "brain game," "vocabulary game"
- Long-tail (lower competition): "spelling bee unlimited," "word puzzle no wifi," "word game no subscription"

**App Store title and subtitle strategy:**
- Title: Include "word puzzle" or "word game" in the app name itself — this is the highest-weighted keyword field
- Subtitle (30 chars): Use for a mechanic descriptor, e.g., "Unlimited Letter Puzzles"
- Keyword field: Do not repeat words already in title/subtitle; fill with complementary terms

**Screenshot strategy (high impact for zero marketing budget):**
- Screenshot 1: Show the gameplay board in progress — letters arranged, one word just found. Caption: "Find words from the letters." Do not show menus or splash screens.
- Screenshot 2: Show the end-of-round word discovery — all the words they could have found. Caption: "Discover words you didn't know."
- Screenshot 3: Show the streak or progress tracker. Caption: "Build your daily streak."
- Screenshot 4: Show the unlimited mode or puzzle count. Caption: "Unlimited puzzles. Play anytime."
- Screenshot 5: "No ads. No subscription. One-time unlock." — Use text-heavy screenshot with clean background.

Apple now uses OCR on screenshot caption text for keyword indexing (confirmed change in early 2026). The text in your screenshot captions is indexed — treat it as keyword-rich copy, not decoration.

**Retention signals now affect ranking:** As of 2026, Apple's algorithm weights Day 7 retention above raw download counts. Apps with strong early retention rank above competitors with more downloads but weaker engagement. Building the streak mechanic and daily return hook is not just a product decision — it directly affects organic discoverability.

**Review velocity matters:** New reviews signal freshness to the algorithm. Use SKStoreReviewRequest after the player completes their first full session and after they unlock a satisfying achievement. Target the review prompt at the "pangram found" or "personal best score" moment.

---

## Competitive Landscape

**Market context:** Word games are the second-largest category in mobile gaming by MAU. The category is large and competitive, but the competition is mostly large studios with ad-heavy models — not indie one-time-purchase apps. That gap is your opening.

**Direct competitors (Spelling Bee mechanic):**

| App | Model | Gap / Weakness |
|-----|-------|----------------|
| NYT Spelling Bee | Subscription ($17/month for NYT Games) | One puzzle per day, expensive subscription, no unlimited mode |
| Spellsbee / WordGa | Free, ad-supported | Ads interrupt play; UI quality is low; no clear premium path |
| Spelling Bee - Fun Word Game (App Store) | Free with IAP | Mixed reviews; audio bugs; limited puzzle variety cited |
| Wortendo | Free | Mostly web-based; native app experience is secondary |

**Broader word game market (context, not direct competition):**

Wordscapes earns $170M+ annually — it dominates through hybrid ads + IAP + daily engagement loops. You are not competing with Wordscapes. You are competing for the player who wants a clean, ad-free, unlimited spelling bee experience that does not require a NYT subscription.

**Positioning opportunity:** "The unlimited spelling bee without the subscription" is an open position. NYT charges $17/month for all their games; you charge $2.99 once. Players searching for "spelling bee" alternatives are explicitly looking for what you are building. This positioning should be front-and-center in your App Store description.

**Category competition level:** MEDIUM-HIGH for generic terms ("word game," "word puzzle"). LOW-MEDIUM for specific positioning terms ("spelling bee unlimited," "letter puzzle offline"). Start with the long-tail, niche-specific keywords where you can rank before competing for broad terms.

**The solo developer structural advantage:** Large studios need ads to justify their cost structure. You do not. An app that is genuinely ad-free with a one-time unlock is structurally differentiated from 80% of the competition without building any additional features. Your cost structure is your moat.

---

## Sources

- [AppFollow: App Store Optimization for Games 2026](https://appfollow.io/blog/app-store-optimization-for-games)
- [Udonis: Word Game Marketing & User Acquisition](https://www.blog.udonis.co/mobile-marketing/mobile-games/word-game-marketing)
- [GameRefinery: Best Practices for Targeted IAP Offers](https://www.gamerefinery.com/best-practice-and-strategies-for-targeted-iap-offers-in-mobile-games/)
- [Mistplay: Puzzle Game Trends & Player Behavior](https://business.mistplay.com/resources/puzzle-game-trends)
- [Crosswordle: Games Like Spelling Bee](https://crosswordle.com/blog/games-like-spelling-bee)
- [Plotline: Streaks and Milestones for Mobile Gamification](https://www.plotline.so/blog/streaks-for-gamification-in-mobile-apps)
- [Pushwoosh: Game App Retention Strategies](https://www.pushwoosh.com/blog/user-retention-strategies-mobile-games/)
- [ASO World: The Golden Timing of In-App Purchases](https://asoworld.com/blog/mobile-game-market-insight-the-golden-timing-of-in-app-purchases/)
- [FoxData: App Store Algorithm Changes 2026](https://foxdata.com/en/blogs/app-store-algorithm-changes-in-2026-what-you-need-to-know/)
- [Liftoff: 2025 Casual Gaming Apps Report](https://liftoff.ai/2025-casual-gaming-apps-report/)
- [GDevelop: 5 Mobile UX Mistakes That Cost Players](https://gdevelop.io/blog/mobile-ux-mistakes)
