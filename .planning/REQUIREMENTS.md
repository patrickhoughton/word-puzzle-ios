# Requirements: Word Puzzle iOS

**Defined:** 2026-08-27
**Core Value:** Endless, fresh word puzzles that generate algorithmically from a local dictionary — no internet, no content team, no ongoing maintenance.

## v1 Requirements

### Core Game

- [x] **GAME-01**: User can view a set of 7 letters (with one highlighted required center letter) and submit words using those letters
- [x] **GAME-02**: App validates submitted words against a bundled local dictionary with immediate feedback (accepted or rejected)
- [x] **GAME-03**: User can see their score and found-word count update in real-time during a round
- [x] **GAME-04**: User can see all words they missed revealed at the end of each round

### Puzzle Engine

- [x] **PUZZ-01**: App generates puzzles algorithmically using a pangram-first approach from the ENABLE word list
- [x] **PUZZ-02**: Word list is filtered for profanity and inappropriate content before puzzle generation
- [x] **PUZZ-03**: Each puzzle guarantees a minimum of 20 valid words and at least one pangram (word using all 7 letters)
- [x] **PUZZ-04**: User can shuffle the displayed letters to help spot new words

### Retention

- [x] **RET-01**: App tracks and displays a daily streak counter (days in a row with at least one puzzle played)
- [x] **RET-02**: App shows lifetime stats: total words found, best score, total games played
- [x] **RET-03**: App provides haptic feedback when a correct word is submitted

### Monetization

- [x] **MON-01**: Free users can play 3 puzzles per day; a paywall gate appears after the 3rd puzzle ends
- [x] **MON-02**: User can purchase a one-time non-consumable IAP ($2.99) to unlock unlimited puzzles permanently
- [x] **MON-03**: Paywall screen includes a visible "Restore Purchases" button (required by Apple Guideline 3.1.1)
- [x] **MON-04**: Premium unlock status is verified via StoreKit 2 `Transaction.currentEntitlements` on every app launch (no UserDefaults flag as source of truth)

### Polish & Compliance

- [x] **UX-01**: All game features work fully offline — no network connection required
- [x] **UX-02**: User can toggle sound effects on/off in a settings screen
- [x] **UX-03**: App supports Dynamic Type — all text scales correctly with system font size settings
- [x] **UX-04**: App has a polished custom icon and App Store screenshots that communicate the core value prop
- [x] **UX-05**: Privacy nutrition label is complete and accurate; app does not collect personal data

### Onboarding (Phase 11)

- [ ] **TUT-01**: A new player is taught every core mechanic on a scripted practice puzzle (DOLPHIN, center P) with strict guided steps, one guided center-letter miss, and free play after the last step
- [ ] **TUT-02**: The practice puzzle is free and unrecorded: it never records a round start or a GameRecord, never counts toward the 3 free puzzles a day, and never shows the paywall or the missed-words screen
- [ ] **TUT-03**: The tutorial shows automatically only on a new install with no game history; an interrupted tutorial restarts from step 1 on next launch; existing players never see it automatically
- [ ] **TUT-04**: "Skip tutorial" is always visible and Finish Round in the tutorial both mark the tutorial seen and start the first real puzzle through the normal round path
- [ ] **TUT-05**: Settings has a "How to Play" row that replays the tutorial from step 1 without costing a free puzzle or touching the in-progress real round
- [ ] **TUT-06**: The tutorial banner and highlight work at Dynamic Type AX5, respect Reduce Motion, and announce each step to VoiceOver with Skip reachable
- [ ] **TUT-07**: Existing UI tests and the App Store screenshot automation keep passing (they launch with -hasSeenTutorial YES)

## v2 Requirements

### Discovery

- **DISC-01**: Daily challenge mode — one shared puzzle per day, shareable score card
- **DISC-02**: Game Center integration for high score leaderboard

### Social

- **SOCL-01**: Share score / found words via iOS Share Sheet after a round
- **SOCL-02**: Word-of-the-day notification to drive return visits

### Depth

- **DEPTH-01**: Multiple difficulty levels (letter set size or word length minimum)
- **DEPTH-02**: Themed puzzle packs (curated letter sets around topics)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multiplayer / real-time competition | Backend complexity; no passive income benefit without significant user base |
| Android version | Focus iOS first; cross-platform before product-market fit is premature |
| Subscription model | One-time IAP is simpler to implement, easier to convert, no churn tracking |
| Backend / cloud save | Eliminates server costs; local-only is a feature (works offline) |
| OAuth / social login | No user accounts needed; everything is local |
| In-app hint system | Scope risk; word shuffle covers discoverability need |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PUZZ-01 | Phase 1 | Complete |
| PUZZ-02 | Phase 1 | Complete |
| PUZZ-03 | Phase 1 | Complete |
| MON-02 | Phase 2 | Complete |
| MON-03 | Phase 2 | Complete |
| MON-04 | Phase 2 | Complete |
| RET-01 | Phase 2 | Complete |
| RET-02 | Phase 2 | Complete |
| GAME-01 | Phase 3 | Complete |
| GAME-02 | Phase 3 | Complete |
| GAME-03 | Phase 3 | Complete |
| GAME-04 | Phase 3 | Complete |
| PUZZ-04 | Phase 3 | Complete |
| RET-03 | Phase 3 | Complete |
| MON-01 | Phase 4 | Complete |
| UX-01 | Phase 5 | Complete |
| UX-02 | Phase 5 | Complete |
| UX-03 | Phase 5 | Complete |
| UX-04 | Phase 5 | Complete |
| UX-05 | Phase 5 | Complete |
| TUT-01 | Phase 11 | Pending |
| TUT-02 | Phase 11 | Pending |
| TUT-03 | Phase 11 | Pending |
| TUT-04 | Phase 11 | Pending |
| TUT-05 | Phase 11 | Pending |
| TUT-06 | Phase 11 | Pending |
| TUT-07 | Phase 11 | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0

---
*Requirements defined: 2026-08-27*
*Last updated: 2026-10-04 after Phase 11 planning (added TUT-01..TUT-07)*
