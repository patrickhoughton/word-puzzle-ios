# Roadmap: Word Puzzle iOS

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-10-19) — [archive](./milestones/v1.0-ROADMAP.md)
- 📋 **Next milestone** — not yet defined (`/gsd:new-milestone`)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-12) — SHIPPED 2026-10-19</summary>

- [x] Phase 1: Word Engine & Puzzle Generation (3/3 plans) — completed 2026-08-28
- [x] Phase 2: Persistence & Entitlements (5/5 plans) — completed 2026-08-29
- [x] Phase 3: Core Game UI (5/5 plans) — completed 2026-08-29
- [x] Phase 4: Paywall & Free Tier Gate (4/4 plans) — completed 2026-08-31
- [x] Phase 5: Polish, Compliance & App Store (8/8 plans) — completed 2026-10-06
- [x] Phase 6: Differentiated Invalid-Word Messaging (2/2 plans) — completed 2026-10-04
- [x] Phase 7: Found Words View (3/3 plans) — completed 2026-10-04
- [x] Phase 8: All-Pangrams Bonus (6/6 plans) — completed 2026-10-04
- [x] Phase 9: Player Stats Screen (6/6 plans) — completed 2026-10-05
- [x] Phase 10: Double-Tap Shuffle (3/3 plans) — completed 2026-10-05
- [x] Phase 11: First-Launch Tutorial (6/6 plans) — completed 2026-10-05
- [x] Phase 12: Inertial Flick-to-Spin (9/9 plans) — completed 2026-10-05

Full phase details: [milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)

</details>

## Backlog

### Phase 999.9: Word list coverage review (BACKLOG)

**Goal:** [Captured for future planning] — Patrick suspects the bundled word list is missing words players would expect to be valid. Current list is `enable-clean.txt` (~172,678 words, the profanity-filtered ENABLE list, per CLAUDE.md's original tech-stack choice). **Scope constraint:** do NOT source or diff against Words With Friends' official word list — it's proprietary to Zynga/EA, not public domain, same reasoning CLAUDE.md already uses to rule out the official Scrabble/SOWPODS dictionary ("cannot bundle without licensing"). Safe approach instead: cross-reference `enable-clean.txt` against other public-domain or freely-licensed word lists (e.g. SCOWL) to find and fill genuine gaps, and/or gather specific examples of rejected words players expected to work as concrete test cases before changing the list.
**Probe finding (2026-10-05, during a shelved discuss-phase):** the gaps are mostly modern vocabulary — ENABLE is ~25 years old. Missing: `email, blog, online, website, internet, podcast, emoji, selfie, hashtag, wiki, texted, texting, app/apps, cyber, smartphone, vlog, unfriend, gonna, google, ok`. Present: `okay, yeah, nope, zombie, hacker, download`. Open questions for when this is picked up: source of additions (SCOWL and/or hand-curated list), inclusion bar (slang, brand-derived, abbreviations), whether new words are only accepted vs. also counted toward totals/rank/missed words/pangram pool, and review/verification approach.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)

### Phase 999.10: Rejected-word logging for word-list gap detection (BACKLOG)

**Goal:** [Captured for future planning] — automatically capture words that get rejected as "not in dictionary" (NOT the too-short or duplicate rejection cases — those aren't list-coverage issues) into a review queue, so 999.9's word-list gap analysis has real data to work from instead of manual note-taking. Two implementation paths to decide between at planning time:
1. **TelemetryDeck analytics event** — CLAUDE.md already selects TelemetryDeck as the project's analytics SDK (privacy-first, no consent popup), but it is NOT YET integrated into the app (no SDK reference anywhere in the codebase as of 2026-08-29). This path captures real rejected words from real players in the field, which is far more valuable than dev-only testing data, but requires standing up the TelemetryDeck integration first (not currently scheduled in any phase).
2. **Local debug-only log** — simpler (no new dependency), but only captures words Patrick personally triggers during his own testing, not real player misses.
Depends conceptually on Phase 6 (differentiated invalid-word messaging, promoted from 999.3) since both need to distinguish "not in dictionary" from other rejection reasons at the `GameViewModel` level.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd:review-backlog when ready)
