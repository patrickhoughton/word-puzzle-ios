# Word Puzzle iOS

## What This Is

A Spelling Bee-style word unscramble game for iPhone. Players are presented with a set of letters and must find as many valid words as possible using those letters, with algorithmically-generated puzzles so there is always something new to play. The app is free to download with a one-time in-app purchase to unlock unlimited gameplay.

## Core Value

Endless, fresh word puzzles that generate algorithmically from a local dictionary — no internet, no content team, no ongoing maintenance.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can play a word puzzle with a set of scrambled letters and a required center letter
- [ ] User can submit words and see them validated against a local dictionary
- [ ] User can see their score and word count for each round
- [ ] App generates unlimited puzzles algorithmically (no curated content)
- [ ] App works fully offline (local dictionary, no network required)
- [ ] Free tier: limited puzzles per day (e.g., 3 free puzzles)
- [ ] Premium unlock: one-time IAP removes daily limit for unlimited play
- [ ] App is available on the iOS App Store

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

## Constraints

- **Platform**: iOS only — SwiftUI, no game engine (SpriteKit/Unity), native approach
- **Backend**: None — all puzzle logic and word lists are local to the app
- **Solo developer**: No team, scope must be shippable by one person
- **App Store**: Must comply with Apple Review Guidelines for games and IAP
- **No ongoing content**: Puzzle generation must be fully algorithmic

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Spelling Bee-style mechanic | Proven mechanic (NYT), simpler than crossword/connections, no curation needed | — Pending |
| Free + one-time IAP | Simpler than subscription for solo dev; honest value exchange; no recurring backend | — Pending |
| SwiftUI (no game engine) | Word game UI is achievable in SwiftUI; no physics/sprites needed; faster to learn | — Pending |
| Local dictionary only | Eliminates backend, server costs, and network dependency | — Pending |
| iOS-only | Focus execution; cross-platform adds complexity before PMF is proven | — Pending |

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
*Last updated: 2026-08-27 after initialization*
