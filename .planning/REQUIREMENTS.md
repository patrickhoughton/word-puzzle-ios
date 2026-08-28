# Requirements: Word Puzzle iOS

**Defined:** 2026-08-27
**Core Value:** Endless, fresh word puzzles that generate algorithmically from a local dictionary — no internet, no content team, no ongoing maintenance.

## v1 Requirements

### Core Game

- [ ] **GAME-01**: User can view a set of 7 letters (with one highlighted required center letter) and submit words using those letters
- [ ] **GAME-02**: App validates submitted words against a bundled local dictionary with immediate feedback (accepted or rejected)
- [ ] **GAME-03**: User can see their score and found-word count update in real-time during a round
- [ ] **GAME-04**: User can see all words they missed revealed at the end of each round

### Puzzle Engine

- [x] **PUZZ-01**: App generates puzzles algorithmically using a pangram-first approach from the ENABLE word list
- [x] **PUZZ-02**: Word list is filtered for profanity and inappropriate content before puzzle generation
- [x] **PUZZ-03**: Each puzzle guarantees a minimum of 20 valid words and at least one pangram (word using all 7 letters)
- [ ] **PUZZ-04**: User can shuffle the displayed letters to help spot new words

### Retention

- [x] **RET-01**: App tracks and displays a daily streak counter (days in a row with at least one puzzle played)
- [x] **RET-02**: App shows lifetime stats: total words found, best score, total games played
- [ ] **RET-03**: App provides haptic feedback when a correct word is submitted

### Monetization

- [ ] **MON-01**: Free users can play 3 puzzles per day; a paywall gate appears after the 3rd puzzle ends
- [x] **MON-02**: User can purchase a one-time non-consumable IAP ($2.99) to unlock unlimited puzzles permanently
- [ ] **MON-03**: Paywall screen includes a visible "Restore Purchases" button (required by Apple Guideline 3.1.1)
- [ ] **MON-04**: Premium unlock status is verified via StoreKit 2 `Transaction.currentEntitlements` on every app launch (no UserDefaults flag as source of truth)

### Polish & Compliance

- [ ] **UX-01**: All game features work fully offline — no network connection required
- [ ] **UX-02**: User can toggle sound effects on/off in a settings screen
- [ ] **UX-03**: App supports Dynamic Type — all text scales correctly with system font size settings
- [ ] **UX-04**: App has a polished custom icon and App Store screenshots that communicate the core value prop
- [ ] **UX-05**: Privacy nutrition label is complete and accurate; app does not collect personal data

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
| NYT-style hex honeycomb layout | App Store Guideline 4.3 clone risk; use alternative letter arrangement |
| OAuth / social login | No user accounts needed; everything is local |
| In-app hint system | Scope risk; word shuffle covers discoverability need |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PUZZ-01 | Phase 1 | Complete |
| PUZZ-02 | Phase 1 | Complete |
| PUZZ-03 | Phase 1 | Complete |
| MON-02 | Phase 2 | Complete |
| MON-03 | Phase 2 | Pending |
| MON-04 | Phase 2 | Pending |
| RET-01 | Phase 2 | Complete |
| RET-02 | Phase 2 | Complete |
| GAME-01 | Phase 3 | Pending |
| GAME-02 | Phase 3 | Pending |
| GAME-03 | Phase 3 | Pending |
| GAME-04 | Phase 3 | Pending |
| PUZZ-04 | Phase 3 | Pending |
| RET-03 | Phase 3 | Pending |
| MON-01 | Phase 4 | Pending |
| UX-01 | Phase 5 | Pending |
| UX-02 | Phase 5 | Pending |
| UX-03 | Phase 5 | Pending |
| UX-04 | Phase 5 | Pending |
| UX-05 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-08-27*
*Last updated: 2026-08-27 after roadmap creation*
