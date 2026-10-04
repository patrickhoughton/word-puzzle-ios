# Phase 7: Found Words View - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 07-found-words-view
**Areas discussed:** How the player opens it, Order & grouping details, What each row/group shows, Empty state & round-end tie-in

---

## How the player opens it

| Option | Description | Selected |
|--------|-------------|----------|
| Tap score bar → sheet | Whole ScoreBarView is a button opening a dismissable sheet | ✓ |
| Dedicated list button | New icon next to the gear | |
| Inline recent-words strip | NYT-style collapsed strip under score bar | |

Sheet height: **Medium + large detents** ✓ (vs full-height only / you decide)
Affordance: **Small chevron ›** ✓ (vs no cue / chevron + one-time hint)
Interaction: **Modal sheet** ✓ (vs board live at medium detent)

## Order & grouping details

- Group order: **Shortest first** ✓ (vs longest first)
- Word order: **Alphabetical** ✓ (vs most recent first)
- Row layout: **One word per row** ✓ (vs flowing chips / you decide)

## What each row/group shows

| Question | Options | Selected |
|----------|---------|----------|
| Group header | "4 Letters" / "4 Letters · 3" / "4 Letters · 3 of 9" (hint) | "4 Letters · 3 of 9" (hint) |
| Points | None / +N per row | +N per row |
| Sheet header | Title + count / Title + rank + count / Title only | Title + rank + count |
| Empty groups | Show every length / only groups with finds | Show every length |
| Completed group | Checkmark on header / no special treatment | Checkmark on header |
| Pangram count line | No / Yes | No |

**User's notes:** "Show =N per row. I want pangrams identified in the same way they are on the words you missed view" (interpreted "=N" as "+N").

## Empty state & round-end tie-in

- Empty: **Group headers at 0 + nudge line** ✓ (vs headers only / score bar not tappable at 0)
- Dismiss: **Done button + swipe** ✓ (vs swipe only)
- MissedWordsView: **Leave it alone** ✓ (vs share the row component)

## Claude's Discretion

- Nudge-line copy, header separator/checkmark glyph, view-model data shape, Dynamic Type handling of "+N" column, file placement.

## Deferred Ideas

- Shared row component between Found/Missed views
- Pangram count hint (Phase 8 territory)
