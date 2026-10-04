# Phase 8: All-Pangrams Bonus - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 08-all-pangrams-bonus
**Areas discussed:** Bonus formula & rank, Moment of celebration, Pangram progress hint, Huge pangram counts

Pre-discussion: I simulated 20,000 puzzles. 1 pangram = 22.6%, 2 = 17.2%, 3–5 = 24.9%, 6–10 = 17.4%, 11+ ≈ 18% (max 86).

---

## Bonus formula & rank

| Option | Description | Selected |
|--------|-------------|----------|
| Flat +10 | Simple, clear | |
| Scaled: +5 per pangram | Rewards bigger sets | |
| Flat +25 | Big payoff | |
| Other | "Scaled per pangram with an animation of accumulations to give visual reward" | ✓ |

| Per-pangram amount | Selected |
|---|---|
| +5 each | |
| +7 each (doubles pangram value) | ✓ |
| +3 each | |

| 1-pangram puzzles trigger? | Selected |
|---|---|
| No, needs 2+ | |
| Yes, any puzzle | ✓ |

| Count in max score? | Selected |
|---|---|
| Yes, include in max | |
| No, pure bonus on top | ✓ |

| Legend reachable via bonus? | Selected |
|---|---|
| Rank uses word points only | |
| Bonus counts toward rank | |
| Other: "Bonus counts toward rank, progress bar can extend beyond 100% with rewarding visual queue" | ✓ |

| Over 100% handling | Selected |
|---|---|
| Legend + bar overflow glow | |
| New tier above Legend | |
| Other: "both" | ✓ |

**Tier name options:** Mythic / Luminary / Grandmaster. **User's choice:** "Mythic Grandmaster".
**Threshold:** Any amount over 100% (✓) vs 110%+.

## Moment of celebration

| Question | Options | Selected |
|---|---|---|
| Timing | Instantly mid-round / End of round only | Instantly mid-round |
| Feedback | New fanfare + success haptics / Reuse pangram sound | New fanfare + success haptics |
| Copy | "All pangrams! +N" / "Pangram sweep! +N" / You decide | "Pangram sweep! +N" |
| Animation | Pangram-by-pangram tally / Score counter rolls up / You decide | Pangram-by-pangram tally |

## Pangram progress hint

| Option | Selected |
|---|---|
| Counter in Found Words sheet | |
| Always on the board | |
| Both | ✓ |
| Hidden | |

## Huge pangram counts

| Option | Selected |
|---|---|
| Cap in generator | |
| Leave as a rare feat | ✓ |
| Cap the bonus, not the puzzle | |

**Cap amount:** user answered "no cap".

## Length-completion bonus (user-initiated scope addition)

User: "Let's add an additional bonus for completing all words of a given length. The bonus will be points equivalent to the length."

| Question | Options | Selected |
|---|---|---|
| Scope | Fold into Phase 8 / Separate new phase | Fold into Phase 8 |
| Celebration | Lighter version of sweep / Same tally / Quiet points only | Lighter version of sweep |
| Scoring | Same rules as sweep / Include in max score | Same rules as sweep |
| Overlap with sweep | Both, in sequence / Both, one combined callout | Both, in sequence |

## Claude's Discretion

Fanfare clip/tick/haptic choice and tally timing; overflow glow styling; Mythic Grandmaster visual treatment; board counter placement/format/post-sweep state; MissedWordsView sweep mention; outcome modeling; input blocking during tally.

## Deferred Ideas

- Generator pangram cap / sampling-bias fix (declined).
