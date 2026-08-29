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
