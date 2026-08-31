# Phase 4: Paywall & Free Tier Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-31
**Phase:** 04-paywall-free-tier-gate
**Areas discussed:** Paywall trigger conditions, Free-puzzle-count visibility, Paywall hard-wall behavior, Paywall screen content & copy

---

## Paywall Trigger Conditions

| Option | Description | Selected |
|--------|-------------|----------|
| Block 'Next Puzzle' + relaunch | Paywall after finishing puzzle #3 AND immediately on later relaunch same day | ✓ |
| Only block 'Next Puzzle' | Only gate right after 3rd round; relaunch creates a gap | |
| Only block on relaunch | Let in-session flow continue after puzzle #3, only gate next fresh launch | |

**User's choice:** Block 'Next Puzzle' + relaunch (recommended option)
**Notes:** None beyond selecting the recommended option.

| Option | Description | Selected |
|--------|-------------|----------|
| No, doesn't count (simplest) | Existing behavior — record() only fires in finishRound() | |
| Yes, should count | Requires tracking 'puzzle started' separately from 'puzzle finished' | ✓ |

**User's choice:** Yes, should count
**Notes:** Deliberate choice to close the abandon-to-avoid-limit loophole, accepting new persistence work.

---

## Free-Puzzle-Count Visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Show a counter | e.g. '2 of 3 free puzzles today' visible during play | ✓ |
| No counter, surprise wall | Nothing shown until 3rd puzzle ends | |

**User's choice:** Show a counter (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| In ScoreBarView | Add to existing top-of-screen status bar | ✓ |
| New dedicated element | Separate badge/label elsewhere | |
| Not applicable | (only if no counter chosen) | |

**User's choice:** In ScoreBarView (recommended)

---

## Paywall Hard-Wall Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| True dead-end | No dismiss/back; only Purchase or Restore; no home screen exists | ✓ (with addition) |
| Dismissible to locked/blurred preview | Peek at locked game screen behind paywall | |

**User's choice:** "True dead end with a count down to next available play" — selected true dead-end but added a specific requirement (live countdown) not in either canned option.
**Notes:** This became D-05 (dead-end) + D-06 (live countdown), captured as two separate decisions in CONTEXT.md.

| Option | Description | Selected |
|--------|-------------|----------|
| Pure sales screen | Price, pitch, Unlock, Restore — no stats | |
| Include today's stats | Show today's puzzles/score summary alongside sales pitch | ✓ |

**User's choice:** Include today's stats

**Follow-up questions asked** (to pin down the "true dead-end + countdown" and "today's stats" answers precisely):

| Option | Description | Selected |
|--------|-------------|----------|
| Live-ticking countdown | Real-time updating, e.g. '2h 14m until next free puzzle' | ✓ |
| Static message | 'Come back tomorrow' — no live updating | |

**User's choice:** Live-ticking countdown (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Puzzles played today | e.g. '3 of 3' — already queryable | ✓ |
| Today's total score | Sum of scores today — NOT currently queryable, new work | ✓ |
| Today's words found | Sum of words found today — NOT currently queryable, new work | ✓ |
| Current streak | Already computed via currentStreak() | ✓ |

**User's choice:** All four selected (multiSelect)

---

## Paywall Screen Content & Copy

| Option | Description | Selected |
|--------|-------------|----------|
| Price prominent, single CTA | Large literal price display, one clear Unlock button | ✓ |
| Value-framed price | De-emphasize raw price with marketing framing | |

**User's choice:** Price prominent, single CTA (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Secondary text link below CTA | Standard pattern, satisfies Guideline 3.1.1 without competing visually | ✓ |
| Equal-weight button | Restore as its own full-weight button | |

**User's choice:** Secondary text link below CTA (recommended)

---

## Claude's Discretion

- Exact copy/wording for sales pitch, Unlock button label, countdown text format
- Visual layout/spacing of the paywall screen (or defer to a dedicated `/gsd:ui-phase 4` pass)
- Exact SwiftData query shape for the two new "sum today" PersistenceStore methods
- Exact schema/mechanism for tracking "puzzle started" vs "puzzle finished"
- Where in GameView/GameViewModel the gate check is intercepted

## Deferred Ideas

None new. Related but distinct backlog items not re-litigated: 999.1 (general player stats screen), 999.3 (differentiated invalid-word messaging), 999.10 (rejected-word logging).
