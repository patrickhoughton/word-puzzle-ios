# Word Puzzle iOS

## What This Is

A Spelling Bee-style word unscramble game for iPhone. Players are presented with a set of letters and must find as many valid words as possible using those letters, with algorithmically-generated puzzles so there is always something new to play. The app is free to download with a one-time in-app purchase to unlock unlimited gameplay.

## Current State

**Shipped:** v1.0 "Word Puzzle Unlimited" is live on the App Store (iPhone + iPad), with the $2.99 Unlimited Puzzles non-consumable IAP. First real purchase made 2026-10-19.
**In review:** v1.0.1 (3), submitted 2026-10-19 with automatic release. It saves the in-progress round across launches, so relaunching no longer consumes a free puzzle (first user-reported bug), and removes `marrano` from the word list.
**Codebase:** ~5,600 Swift LOC app + ~4,500 Swift LOC tests; SwiftUI + @Observable MVVM, SwiftData, StoreKit 2, zero third-party dependencies, zero network calls.

## Next Milestone Goals

Not yet defined. Run `/gsd:new-milestone`. Candidates:
- Close the carried UAT gaps (AX5 on newer screens incl. iPhone 17e clipping, offline re-test of the shipped build, iPad Settings gear)
- Word-list quality: backlog 999.9 (coverage review) and 999.10 (rejected-word logging)
- Swift 6 actor-isolation warnings
- Real-player feedback and sales data once v1.0.1 is out

## Core Value

Endless, fresh word puzzles that generate algorithmically from a local dictionary — no internet, no content team, no ongoing maintenance.

## Requirements

### Validated

- [x] User can play a word puzzle with a set of scrambled letters and a required center letter — Phase 3 (core-game-ui), verified on real iPhone hardware 2026-08-29
- [x] User can submit words and see them validated against a local dictionary — Phase 3 (core-game-ui), verified on real iPhone hardware 2026-08-29
- [x] User can see their score and word count for each round — Phase 3 (core-game-ui), verified on real iPhone hardware 2026-08-29
- [x] App generates unlimited puzzles algorithmically (no curated content) — Phase 1 (word-engine-puzzle-generation) built it; Phase 3 verified Finish Round → Next Puzzle generates a fresh puzzle end-to-end on device
- [x] Free tier: limited puzzles per day (e.g., 3 free puzzles) — Phase 4 (paywall-free-tier-gate), verified end-to-end on Simulator 2026-08-31 (abandoned rounds count toward the limit; paywall triggers on the 4th request, not the 3rd)
- [x] Premium unlock: one-time IAP removes daily limit for unlimited play — Phase 4 (paywall-free-tier-gate), verified via real StoreKit sandbox purchase and restore-after-reinstall on a physical iPhone 15 Pro 2026-08-31
- [x] Rejected words show distinct feedback per reason (too short, missing center letter, not a word, already found; duplicates get gentle, silent feedback) — Phase 6 (differentiated-invalid-word-messaging), verified on a physical iPhone 15 Pro 2026-10-04
- [x] Player can view the words found so far in the current round, grouped by length with per-length progress (tap the score bar) — Phase 7 (found-words-view), verified on a physical iPhone 15 Pro 2026-10-04
- [x] Completion bonuses: finding every pangram awards a sweep bonus (+7 per pangram) and finishing every word of a length awards +L, with celebration pill/tally, sounds, haptics, a pangram counter, an overflow bar past 100% and a hidden "Mythic Grandmaster" tier — Phase 8 (all-pangrams-bonus), verified on a physical iPhone 15 Pro 2026-10-04
- [x] Player can view lifetime and today stats (games played, best score, words found, averages, current/longest streak with at-risk nudge, best rank, pangrams, sweeps) from a top-bar icon, Settings > Stats, and the round-over summary line — Phase 9 (player-stats-screen), SwiftData migration of real history and UI verified on a physical iPhone 15 Pro 2026-10-04
- [x] Player can double-tap any empty area of the game screen to shuffle the outer letters, alongside the Shuffle button, with a light haptic on every real shuffle; double-tapping a tile still enters that letter twice — Phase 10 (double-tap-shuffle), verified on a physical iPhone 15 Pro 2026-10-04
- [x] First-time players get a guided ~2-minute tutorial on a scripted practice board (DOLPHIN, center P) teaching tap/drag, the required center letter, swipe-down submit, delete/clear, shuffle, pangrams and the found-words view; it never records stats or touches the real round, can be skipped, and replays from Settings > How to Play — Phase 11 (first-launch-tutorial), approved on a physical iPhone 15 Pro 2026-10-04
- [x] Player can flick or wind the outer ring of letters like a prize wheel: 1:1 dial tracking from any off-tile touch, inertial coast that settles onto whole slots, per-slot haptic + synthesized peg-wheel tick, grab-to-stop, Shuffle cancels a spin, Reduce Motion snap, cosmetic "Full circle!" jackpot, and a tutorial "Give it a spin" step — Phase 12 (inertial-flick-spin-outer-letters), approved on a physical iPhone 15 Pro 2026-10-05

- [x] App is available on the iOS App Store — v1.0 (build 2) + IAP approved after one Guideline 2.1 Information Needed round; READY_FOR_SALE confirmed 2026-10-19
- [x] App works fully offline (local dictionary, no network required) — Phase 5 (polish-compliance-app-store): Airplane Mode verified on device in 05-06; `scripts/compliance-guards.sh` Guard 1 proves no networking API in the app target
- [x] Sound effects with a persistent on/off toggle, Dynamic Type support, custom icon, Data Not Collected privacy label and App Store listing (screenshots, keywords) — Phase 5 (polish-compliance-app-store), v1.0 build 2 + Unlimited Puzzles IAP submitted to App Review 2026-10-05

### Active

- [ ] Player's in-progress round survives closing the app, and relaunching never consumes a free puzzle — built and device-tested in quick task 261019-o9k; ships with v1.0.1 (in review)

### Out of Scope

- Multiplayer / real-time competition — adds backend complexity, save for v2
- Daily challenge mode (Wordle-style) — could add later, not critical for revenue
- Leaderboards / Game Center — adds complexity, not needed for passive income
- Android version — focus on iOS first, maximize quality before cross-platform
- Subscription model — one-time IAP is simpler and more honest for solo dev
- Backend / sync / cloud save — keep it local-only; no server costs

## Context

- Patrick is new to iOS development (no prior SwiftUI/App Store experience)
- Revenue goal: $100–$500/month from App Store downloads
- Post-launch time budget: a few hours per week for updates/marketing
- The game mechanic is proven (NYT Spelling Bee style) — differentiation comes from unlimited algorithmic generation and clean UX
- No ongoing content creation needed — puzzles generate from a bundled word list
- App Store pricing target: free download + $2.99 one-time unlimited unlock IAP
- Shipped v1.0 on 2026-10-19 after 53 days of development. New developer accounts get a Guideline 2.1 "Information Needed" request on first review (device screen recording + written answers); budget a few extra days for it
- First user feedback came from family testing the live app: players expect progress to persist when the app is closed. The free-tier "abandoned rounds count" rule was correct, but without a saved round every relaunch looked like an abandoned round

## Constraints

- **Platform**: iOS only — SwiftUI, no game engine (SpriteKit/Unity), native approach
- **Backend**: None — all puzzle logic and word lists are local to the app
- **Solo developer**: No team, scope must be shippable by one person
- **App Store**: Must comply with Apple Review Guidelines for games and IAP
- **No ongoing content**: Puzzle generation must be fully algorithmic

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Spelling Bee-style mechanic | Proven mechanic (NYT), simpler than crossword/connections, no curation needed | ✓ Good — shipped; first player feedback positive |
| Free + one-time IAP | Simpler than subscription for solo dev; honest value exchange; no recurring backend | ✓ Good — approved by App Review; revenue still unproven |
| SwiftUI (no game engine) | Word game UI is achievable in SwiftUI; no physics/sprites needed; faster to learn | ✓ Good — handled hex grid, drag input and inertial spin |
| Local dictionary only | Eliminates backend, server costs, and network dependency | ✓ Good — no network code; word-list quality is now the main content lever (999.9) |
| iOS-only | Focus execution; cross-platform adds complexity before PMF is proven | ✓ Good |
| SwiftData for history/stats, UserDefaults for flags | Queryable streaks/lifetime totals; simple flags stay simple | ✓ Good — survived a schema migration of real history (Phase 9) |
| Entitlement re-derived from StoreKit every launch (no local flag) | Avoids a spoofable/stale premium flag | ✓ Good |
| Daily free limit counts round STARTS, not finishes | Stops dodging the limit by abandoning rounds | ⚠️ Revisit — correct rule, but relaunch counted as a start until v1.0.1 added round save/restore |
| Fold backlog features (Phases 6-12) into v1.0 before submitting | Launch with a differentiated feature set | ✓ Good — delayed submission ~1 day, shipped richer |
| Automate App Store Connect via API + XCUITest screenshots | Solo dev, repeatable releases | ✓ Good — v1.0.1 archived, uploaded and submitted in one session |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-10-19 after v1.0 milestone (shipped; v1.0.1 in review)*
