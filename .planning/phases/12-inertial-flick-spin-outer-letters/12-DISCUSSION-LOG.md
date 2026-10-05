# Phase 12: Inertial Flick-to-Spin - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-10-05
**Phase:** 12-inertial-flick-spin-outer-letters
**Areas discussed:** Where a flick starts, Spin feel & landing, Feedback while spinning, Edge cases & tutorial

**Framing clarification from user:** "The purpose of this feature is purely ASMR engagement especially when the user's stumped."

---

## Where a flick starts

| Option | Description | Selected |
|--------|-------------|----------|
| Anywhere off the tiles | Gaps, flower corners, ring just outside outer tiles; no accidental typing | ✓ |
| Also on an outer tile | Fast curved swipe from a tile becomes a spin; letter removed again | |
| Only a ring outside the flower | Dedicated band; clearest rule, smaller target | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, 1:1 like a dial | Ring tracks finger, release speed carries into a coast | ✓ |
| No, flick only | Nothing moves until release | |

## Spin feel & landing

| Question | Options | Selected |
|----------|---------|----------|
| Settle | Soft snap to nearest slot / Bouncy overshoot | Soft snap |
| Spin length | ~2-3s / ~1s / Prize wheel 5s+ | Prize wheel 5s+ |
| Letter tilt | Stay upright / Rotate with ring | Stay upright |
| Lands at start | That's fine / Always nudge | That's fine |

## Feedback while spinning

| Question | Options | Selected |
|----------|---------|----------|
| Haptics | Tick per slot + landing clunk / Ticks only / Single landing haptic | Tick per slot + clunk |
| Sound | Soft click per slot / Silent | Soft click per slot |

## Edge cases & tutorial

| Question | Options | Selected |
|----------|---------|----------|
| Catch | Touch off-tile to grab / Any touch stops / No catch | Touch off-tile to grab |
| Spell mid-spin | Tiles locked until settled / Tap hits what's under finger | Tiles locked |
| Tutorial | Guided step / Mention in Shuffle text / Easter egg | Guided step |
| Reduce Motion | No coast, snap on release / Disable gesture | No coast, snap on release |
| Round state (multi) | Keep word / Only during .playing / Shuffle cancels spin | Keep word, Shuffle cancels spin; .playing-only confirmed in follow-up |

**User note:** "I may want bonus points if the user spins it more than 5 rotations but lands letters in same position, what do you think?"
Claude recommended cosmetic-only: about a 1-in-6 chance per long spin makes it farmable, and bonuses count toward rank and Mythic Grandmaster (Phase 8).

| Option | Description | Selected |
|--------|-------------|----------|
| Cosmetic celebration only | "Full circle!" sparkle + sound/haptic, no points | ✓ |
| Small points, once per round | e.g. +3, counts toward rank | |
| Defer to backlog | | |
| Nothing special | | |

## Claude's Discretion

Physics model and animation driver, spin-zone geometry, haptic/sound specifics and tick rate-limiting, jackpot visual, rotation-count tracking, state ownership, test strategy.

## Deferred Ideas

- Score points for the spin jackpot (its own scoring phase if revisited).
