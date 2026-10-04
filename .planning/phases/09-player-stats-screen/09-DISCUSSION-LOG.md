# Phase 9: Player Stats Screen - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log keeps the alternatives that were considered.

**Date:** 2026-10-04
**Phase:** 09-player-stats-screen
**Areas discussed:** Entry point, Which stats, Layout & style, Empty & edge states

---

## Entry point

| Question | Options | Selected |
|----------|---------|----------|
| Where stats opens during play | Top-bar icon (rec) / Inside Settings / Both | **Both** |
| End-of-round link | No, leave alone (rec) / Small stats link / Inline mini-summary | **Inline mini-summary** |
| Paywall link | No (rec) / Yes | **No** |
| Presentation | Sheet with Done (rec) / Sheet with detents / Full-screen cover | **Sheet with Done** |
| Settings row behavior | Push inside Settings (rec) / Swap to stats sheet | **Push inside Settings** |
| Mini-summary content | Best + streak (rec) / + games / + New Best callout | **Best + streak** |
| Mini-summary tappable | Yes (rec) / Display only | **Yes, tappable** |

## Which stats

| Question | Options | Selected |
|----------|---------|----------|
| Derived stats (multi) | Average score / Longest streak / Avg words per game / None | **Average score, Longest streak, Avg words per game** |
| New tracked stats (multi) | None (rec) / Best rank / Lifetime pangrams / Pangram sweeps | **Best rank, Lifetime pangrams, Pangram sweeps** |
| Pre-update rounds | Count from now (rec) / "Since update" note / Backfill best rank (not feasible) | **Count from now** |
| Puzzles today | Keep with Today group (rec) / Drop / Keep puzzles-today only | **Keep with Today group** |
| Lifetime pangram source | Finished rounds only (rec) / Every pangram found | **Finished rounds only** |

**Notes:** The user knowingly chose to add tracked stats, which means a GameRecord schema change, even though "None" was recommended to keep migration risk low before v1.0.

## Layout & style

| Question | Options | Selected |
|----------|---------|----------|
| Layout | Hero + tile grid (rec) / Grouped label-value rows / Hero + rows | **Hero + tile grid** |
| Best rank display | Name + accent styling (rec) / Plain text | **Name + accent styling** |
| Motion | Static (rec) / Count-up animation | **Count-up animation** |

## Empty & edge states

| Question | Options | Selected |
|----------|---------|----------|
| Zero games | Full layout, zeros + nudge (rec) / Dedicated empty screen / Just zeros | **Full layout, zeros + nudge** |
| Grace-day streak | "At risk" hint (rec) / Same as normal | **"At risk" hint** |
| Zero streak | Encouraging copy (rec) / Plain "0 day streak" | **Encouraging copy** |
| Average format | Whole numbers (rec) / One decimal | **Whole numbers** |

## Claude's Discretion

Icon choice, tile ordering and styling, exact copy, GameRecord field names, longest-streak algorithm, count-up timing, VoiceOver phrasing, file placement, and the stats snapshot struct.

## Deferred Ideas

- A "New best!" callout on the end-of-round screen (offered but not chosen).
