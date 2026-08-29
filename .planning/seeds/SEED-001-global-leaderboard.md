---
id: SEED-001
status: dormant
planted: 2026-08-29
planted_during: v1.0 milestone, Phase 3 (core-game-ui) just completed
trigger_when: "After v1.0 ships and there's real usage/demand to justify the backend investment and architecture change"
scope: Large
---

# SEED-001: Global leaderboard so players can see how they rank worldwide

## Why This Matters

Players currently have no way to compare their performance against anyone else — the game is entirely local and single-player. A global leaderboard would add a social/competitive hook that could meaningfully boost retention and word-of-mouth, which matters for a solo-dev app with no marketing budget. It's also a natural next step once lifetime stats exist locally (see SEED's sibling backlog item, Phase 999.1 — player stats screen).

## When to Surface

**Trigger:** After v1.0 ships and there's real usage/demand to justify the backend investment and the architecture change.

This seed should be presented during `/gsd:new-milestone` when the milestone scope matches any of these conditions:
- The milestone explicitly proposes adding a backend/server component
- The milestone discusses social features, leaderboards, or competitive/ranking mechanics
- The milestone reconsiders the "no backend / fully offline" constraint in CLAUDE.md
- Post-launch usage data suggests players want to compare scores (e.g. requested in reviews/feedback)

## Scope Estimate

**Large** — a full milestone, not a phase. This is a significant departure from the current architecture:

- **Direct conflict with existing constraint:** CLAUDE.md's Constraints section states "Backend: None — all puzzle logic and word lists are local to the app." This seed requires reversing that decision, at least partially (leaderboard as an optional online feature; core gameplay should likely remain fully offline-capable per the existing offline requirement).
- Needs: a server (hosting decision), a database, user identity/auth (even lightweight, e.g. anonymous device-linked IDs or Sign in with Apple), a score-submission API, anti-cheat/validation on submitted scores (client-side scores are trivially spoofable), and ranking/query endpoints (global rank, percentile, maybe friends/regional).
- Should be scoped as its own milestone with its own requirements, research, and roadmap — not squeezed into the v1.0 App Store launch milestone.

## Breadcrumbs

Related code and decisions found in the current codebase:

- `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` — local SwiftData store; `bestScore()`, `totalGamesPlayed()`, `totalWordsFound()`, `currentStreak()` are the local stats a leaderboard submission would eventually draw from
- `WordPuzzle/WordPuzzle/Services/GameRecord.swift` — the `@Model` that would need either a sync mechanism or a parallel server-side schema
- `WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift` — current scoring formula (D-02); a server-side leaderboard would need to trust or re-derive this, not just accept a client-submitted number
- `WordPuzzle/WordPuzzle/Game/RankTier.swift` — the existing local 10-tier rank system (D-09); worth considering whether "rank" stays local-only (percentage-of-max) vs. becomes a global-leaderboard-position term — these are two different meanings of "rank" that would need disambiguating in UI copy
- `CLAUDE.md` Constraints section — "Backend: None" is the constraint this seed directly challenges
- Related backlog item: `.planning/phases/999.1-player-stats-screen/` — a local stats screen is a natural prerequisite/companion; it surfaces the same numbers a leaderboard submission would use, without any backend risk

## Notes

Raised by Patrick immediately after Phase 3 (core-game-ui) completed, in the same breath as wanting a local player-stats screen (backlogged separately as Phase 999.1). The two ideas are related but very different in risk/scope: stats screen is a pure UI addition on existing local data; leaderboard is a new architecture layer. Recommend treating the stats screen as near-term backlog and this seed as a genuinely separate, later milestone decision — don't let "just add a stats screen" scope-creep into "also stand up a backend."
