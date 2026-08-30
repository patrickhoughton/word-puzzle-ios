# Roadmap: Word Puzzle iOS

**Milestone:** v1.0 — App Store Launch
**Total phases:** 5
**Requirements covered:** 20/20

---

## Overview

Build bottom-up: a reliable word engine first, then persistence and IAP entitlements, then a playable game UI, then the paywall gate, then everything needed to pass App Review and retain players. Each phase delivers something independently verifiable before the next begins.

## Phases

- [ ] **Phase 1: Word Engine & Puzzle Generation** - Pangram-first puzzle generator with profanity-filtered ENABLE word list; fully unit-testable with no UI
- [x] **Phase 2: Persistence & Entitlements** - SwiftData models for game history and daily usage; StoreKit 2 entitlement check for premium status (completed 2026-08-29)
- [x] **Phase 3: Core Game UI** - Playable game on a real device: letter display, word input, validation feedback, scoring, end-of-round reveal, haptics (completed 2026-08-29)
- [ ] **Phase 4: Paywall & Free Tier Gate** - 3-puzzle daily limit enforced; paywall screen with Restore Purchases; IAP purchase and restore flows sandbox-tested
- [ ] **Phase 5: Polish, Compliance & App Store** - Sound effects, Dynamic Type, offline verification, privacy label, app icon, screenshots, ASO

## Phase Details

### Phase 1: Word Engine & Puzzle Generation
**Goal**: A working puzzle generator that produces valid, pangram-guaranteed puzzles from a clean word list — fully testable without any UI
**Depends on**: Nothing (first phase)
**Requirements**: PUZZ-01, PUZZ-02, PUZZ-03
**Success Criteria** (what must be TRUE):
  1. Calling the generator 100 times produces 100 puzzles, each containing at least 20 valid words and at least one pangram
  2. The word list contains no profanity (verified by running the blocklist against the bundled file)
  3. Word validation returns a result in O(1) — a `Set<String>` lookup, not array iteration
  4. Puzzle generation completes in under 500ms on a physical device (not Simulator)
**Plans**: 3 plans
- [x] 01-01-PLAN.md — Install Xcode, create WordPuzzle project + PuzzleEngine group, bundle profanity-filtered ENABLE list (Wave 0)
- [x] 01-02-PLAN.md — Implement Puzzle model, WordList loader (O(1) Set), pangram-first generator + Swift Testing unit tests (Wave 1)
- [x] 01-03-PLAN.md — XCTest 500ms performance test, verified on a physical iPhone (Wave 2)
**UI hint**: no

### Phase 2: Persistence & Entitlements
**Goal**: Game history and daily usage are stored in SwiftData; premium status is read from StoreKit 2 `Transaction.currentEntitlements` on every app launch
**Depends on**: Phase 1
**Requirements**: MON-02, MON-03, MON-04, RET-01, RET-02
**Success Criteria** (what must be TRUE):
  1. `PersistenceStore.puzzlesPlayedToday()` returns the correct count after simulated play sessions — persists across app restarts
  2. Daily streak counter increments when at least one puzzle is played in a day and resets correctly after a missed day
  3. Lifetime stats (total words found, best score, total games played) accumulate correctly across multiple sessions
  4. `EntitlementStore.isPremium` reads `Transaction.currentEntitlements` — not a UserDefaults flag — and returns the correct value after a sandbox purchase and after a restore
  5. Sandbox IAP product is created and attached in App Store Connect before any StoreKit code is written
**Plans**: 5 plans
Plans:
- [x] 02-01-PLAN.md — App Store Connect setup (agreement, app record, IAP product) + WordPuzzle.storekit configuration file (Wave 1)
- [x] 02-02-PLAN.md — GameRecord @Model, PersistenceStore container/record/puzzlesPlayedToday + lifetime stats (Wave 1)
- [x] 02-03-PLAN.md — ScoreCalculator (D-02 formula) + derived daily streak counter (Wave 2)
- [x] 02-04-PLAN.md — EntitlementStore (currentEntitlements, purchase, AppStore.sync restore) + SKTestSession tests (Wave 2)
- [x] 02-05-PLAN.md — Wire both stores into WordPuzzleApp + manual sandbox purchase/restore verification (Wave 3)
**UI hint**: no

### Phase 3: Core Game UI
**Goal**: A complete, playable round of the game works on a real iPhone — letters displayed, words submitted, feedback given, score updated, and missed words revealed at round end
**Depends on**: Phase 2
**Requirements**: GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03
**Success Criteria** (what must be TRUE):
  1. User can see 7 letters with the center letter visually distinguished, tap any letter to build a word, and submit it
  2. Submitting a valid word updates the score and found-word count immediately; submitting an invalid word shows a rejection animation without crashing
  3. User receives haptic feedback on correct word submission
  4. User can tap a Shuffle button and the non-center letters rearrange
  5. At round end, user sees the complete list of words they did not find during the round
**Plans**: 5 plans
Plans:
- [x] 03-01-PLAN.md — GameTheme tokens + #F5B800 accent, RankTier original 10-tier lookup, GameViewModel round state/validation/scoring/shuffle + Wave 0 tests (Wave 1)
- [x] 03-02-PLAN.md — HexagonShape, HexFlowerLayout geometry, HexTileView, LetterGridView with single unified tap/drag recognizer + shuffle animation (Wave 2)
- [x] 03-03-PLAN.md — WordDisplayView (swipe-down submit, shake/pop, haptics), ScoreBarView, MissedWordsView (Wave 2)
- [x] 03-04-PLAN.md — GameView assembly, WordList + GameViewModel app wiring, EntitlementDebugPanel deletion (Wave 3)
- [x] 03-05-PLAN.md — On-device manual verification checkpoint on a real iPhone (Wave 4)
**UI hint**: yes

### Phase 4: Paywall & Free Tier Gate
**Goal**: Free users can play exactly 3 puzzles per day before hitting a paywall; the paywall has a working purchase flow, a visible Restore Purchases button, and passes Apple Review requirements
**Depends on**: Phase 3
**Requirements**: MON-01
**Success Criteria** (what must be TRUE):
  1. A free user who completes their third puzzle sees the paywall screen — not before, not after a restart
  2. The paywall screen displays the price, a clear unlock CTA, and a "Restore Purchases" button that calls `AppStore.sync()`
  3. A sandbox purchase grants unlimited puzzles immediately and survives an app restart (verified via StoreKit 2, not UserDefaults)
  4. Tapping Restore Purchases on a device with a prior sandbox purchase restores premium status without requiring re-purchase
**Plans**: TBD
**UI hint**: yes

### Phase 5: Polish, Compliance & App Store
**Goal**: The app passes App Review on first submission: fully offline, supports Dynamic Type, has a completed privacy label, and has App Store metadata (icon, screenshots, keywords) that accurately represents the product
**Depends on**: Phase 4
**Requirements**: UX-01, UX-02, UX-03, UX-04, UX-05
**Success Criteria** (what must be TRUE):
  1. All game features work in Airplane Mode — no network calls fail silently or crash the app
  2. User can toggle sound effects on/off from a settings screen and the preference persists across restarts
  3. All text in the app scales correctly when the largest Dynamic Type size is selected in iOS Settings
  4. The privacy nutrition label in App Store Connect accurately reflects zero data collection and the app passes the App Store privacy questionnaire
  5. App Store listing has a custom icon, at least 3 screenshots from the final TestFlight build, and keyword fields targeting "spelling bee unlimited," "word puzzle offline," and "word game no subscription"
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Word Engine & Puzzle Generation | 3/3 | Complete | 2026-08-28 |
| 2. Persistence & Entitlements | 5/5 | Complete   | 2026-08-29 |
| 3. Core Game UI | 5/5 | Complete | 2026-08-29 |
| 4. Paywall & Free Tier Gate | 0/? | Not started | - |
| 5. Polish, Compliance & App Store | 0/? | Not started | - |

## Backlog

### Phase 999.1: Player stats screen (BACKLOG)

**Goal:** [Captured for future planning] — surface `PersistenceStore`'s existing lifetime stats (`totalGamesPlayed`, `bestScore`, `totalWordsFound`, `currentStreak`, `puzzlesPlayedToday`) in a UI the player can actually see. The data has existed since Phase 2; no view currently reads it. Natural fit alongside Phase 5's settings screen.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.2: Found words view (BACKLOG)

**Goal:** [Captured for future planning] — let the player see the words they've already found during the current round, grouped by length (same organizing pattern as `MissedWordsView`'s round-end reveal). Currently `GameViewModel` already tracks found words internally (used to compute the missed-words set at round end), but there's no in-round view surfacing them — the player only sees a running count in `ScoreBarView`, not the actual word list.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.3: Differentiated invalid-word messaging (BACKLOG)

**Goal:** [Captured for future planning] — replace the single generic "Not a valid word" rejection message with distinct feedback for each rejection reason: word too short (< 4 letters), word not in the dictionary/doesn't use valid letters, and word already found this round (duplicate). Currently `GameViewModel.submitCurrentWord()` returns a plain `Bool` and `WordDisplayView` shows one hardcoded string for every failure case, so the player can't tell why a word was rejected.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.4: First-launch tutorial (BACKLOG)

**Goal:** [Captured for future planning] — a first-time-user tutorial/onboarding flow that teaches the core mechanics (tap/drag letters to build a word, center letter is required, swipe down to submit, shuffle, pangrams) before or during their first round. Currently there is no onboarding at all — `ContentView` loads straight into `GameView` for every launch, first-time or not. Needs a "has the user seen this before" flag (likely `@AppStorage`, consistent with the project's existing flags/seeds persistence split) and a decision on format (overlay walkthrough vs. a scripted first puzzle vs. a standalone intro screen).
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.5: Two-finger rotate-to-shuffle gesture (BACKLOG)

**Goal:** [Captured for future planning] — a two-finger twisting/rotation gesture on the honeycomb grid as an alternative (or addition) to the Shuffle button, rotating the 6 outer letters. Non-trivial: `LetterGridView` currently has exactly ONE gesture recognizer by design (a single-touch `DragGesture(minimumDistance: 0)` handling both tap-to-append and drag-to-connect, per Phase 3's RESEARCH Pattern 3 / Pitfall 1 gesture-contention finding). Adding a two-finger `RotationGesture` means composing a second, multi-touch recognizer alongside the existing one without reintroducing that contention risk — will need its own on-device gesture-contention verification pass, same as Phase 3's 03-05 checkpoint.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.6: Double-tap-to-shuffle gesture (BACKLOG)

**Goal:** [Captured for future planning] — a double-tap gesture as an alternative (or addition) to the Shuffle button. **Trigger decided: double-tap any empty area of the screen** (off the honeycomb tiles) — this avoids the conflict where double-tapping a tile is already legitimate input (appends that letter twice, e.g. a double letter in the word being built). Implementation note: `LetterGridView`'s existing single `DragGesture(minimumDistance: 0)` is scoped to the tiles themselves for hit-testing, so an empty-area double-tap recognizer would live on the surrounding container/background view, not compete with the grid's own gesture — should avoid the contention risk that made 999.5 (rotate gesture, tile-scoped) trickier.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.7: Long-press center letter to shuffle (BACKLOG)

**Goal:** [Captured for future planning] — long-press (or "hard press") on the gold center tile as an alternative (or addition) to the Shuffle button. **Hardware note:** true pressure-sensitive 3D Touch was removed from iPhones starting with the XR/11 generation; Apple's replacement, Haptic Touch, is functionally a long-press with a delay + haptic confirmation — so "long press" and "hard press" are the same gesture on all currently-shipping iPhones, not two separate inputs to build. Conflict to resolve at design time: the center tile is currently part of the single unified `DragGesture(minimumDistance: 0)` hit-test area in `LetterGridView` (tapping it appends the center letter), so a long-press recognizer on that same tile needs to coexist with tap-to-append without misfiring — likely resolved via a time threshold (a fast tap still appends; holding past ~0.5s triggers shuffle instead) rather than a fully separate `LongPressGesture`, to avoid the two-recognizer contention risk noted in 999.5.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.8: Bonus for finding all pangrams (BACKLOG)

**Goal:** [Captured for future planning] — an extra scoring bonus for finding every pangram in a puzzle, not just the per-word +7 pangram bonus that already exists. Context: `Puzzle.pangrams` is already a plural array (a puzzle can have more than one pangram, per `PuzzleGenerator`'s `pangrams = validArray.filter { Set($0) == letters }`), and `ScoreCalculator.points(for:isPangram:)` already awards +7 per individual pangram found — but there's currently no reward tied to clearing the *complete set*. Needs: (1) UI/feedback for "you found all N pangrams!" (likely surfaced in `MissedWordsView`'s pangram badge or a distinct end-of-round callout), (2) a bonus formula decision (flat bonus vs. scaled by pangram count), (3) confirming how often multi-pangram puzzles actually occur in practice (worth checking before investing UI work, since a bonus that almost never triggers isn't worth much).
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.9: Word list coverage review (BACKLOG)

**Goal:** [Captured for future planning] — Patrick suspects the bundled word list is missing words players would expect to be valid. Current list is `enable-clean.txt` (~172,678 words, the profanity-filtered ENABLE list, per CLAUDE.md's original tech-stack choice). **Scope constraint:** do NOT source or diff against Words With Friends' official word list — it's proprietary to Zynga/EA, not public domain, same reasoning CLAUDE.md already uses to rule out the official Scrabble/SOWPODS dictionary ("cannot bundle without licensing"). Safe approach instead: cross-reference `enable-clean.txt` against other public-domain or freely-licensed word lists (e.g. SCOWL) to find and fill genuine gaps, and/or gather specific examples of rejected words players expected to work as concrete test cases before changing the list.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.10: Rejected-word logging for word-list gap detection (BACKLOG)

**Goal:** [Captured for future planning] — automatically capture words that get rejected as "not in dictionary" (NOT the too-short or duplicate rejection cases — those aren't list-coverage issues) into a review queue, so 999.9's word-list gap analysis has real data to work from instead of manual note-taking. Two implementation paths to decide between at planning time:
1. **TelemetryDeck analytics event** — CLAUDE.md already selects TelemetryDeck as the project's analytics SDK (privacy-first, no consent popup), but it is NOT YET integrated into the app (no SDK reference anywhere in the codebase as of 2026-08-29). This path captures real rejected words from real players in the field, which is far more valuable than dev-only testing data, but requires standing up the TelemetryDeck integration first (not currently scheduled in any phase).
2. **Local debug-only log** — simpler (no new dependency), but only captures words Patrick personally triggers during his own testing, not real player misses.
Depends conceptually on 999.3 (differentiated invalid-word messaging) since both need to distinguish "not in dictionary" from other rejection reasons at the `GameViewModel` level.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)
