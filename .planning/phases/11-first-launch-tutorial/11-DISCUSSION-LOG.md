# Phase 11: First-Launch Tutorial - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 11-first-launch-tutorial
**Areas discussed:** Tutorial format, What to teach & when, Free-tier & existing users, Skip & replay

---

## Tutorial format

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted practice puzzle | Fixed letters; prompts wait for the player to do each step | ✓ |
| Coach marks on real puzzle | Tooltip bubbles over the first random round; tap Next | |
| Intro cards before play | 3-5 swipeable cards, then a real round | |

**User's choice:** Scripted practice puzzle (after asking for an explanation of the options)

| Strictness | Selected |
|-----------|----------|
| Guided, wrong taps ignored | ✓ |
| Guided, but free input | |

| Ending | Selected |
|--------|----------|
| Short free play, then real puzzle | ✓ |
| Straight into a real puzzle | |
| Practice board is a full round | |

**Letters:** You decide (Claude)

---

## What to teach & when

| Mechanic | Selected |
|----------|----------|
| Core: build, center, submit | ✓ |
| Delete / clear / drag | ✓ |
| Shuffle + double-tap | ✓ |
| Pangrams + score/Found Words | ✓ |

| Mistakes | Selected |
|----------|----------|
| Yes, one guided miss | ✓ |
| No, keep it all positive | |

| Pacing | Selected |
|--------|----------|
| All in the practice script | ✓ |
| Core in script, rest as later tips | |

**Prompt UI:** You decide (banner + highlight vs. pointing bubbles)

---

## Free-tier & existing users

| Question | Options | Selected |
|----------|---------|----------|
| Counts toward 3 free puzzles? | No, it's free / Yes, it counts | No, it's free |
| Existing players see it on update? | New installs only / Show everyone once | New installs only |
| Finish step behavior | Explains it, tapping starts real puzzle / Mini missed-words reveal | Explains it, tapping starts real puzzle |

---

## Skip & replay

| Question | Options | Selected |
|----------|---------|----------|
| Skippable? | Small Skip link / Skip with confirmation / No skip | Small Skip link |
| Replay? | Settings → How to Play / No replay | Settings → How to Play |
| Interrupted mid-tutorial | Restart from step 1 / Resume step / Treat as seen | Restart from step 1 |

---

## Claude's Discretion

- Practice puzzle letters
- Prompt UI style (banner + highlight vs. bubbles)
- Tutorial copy, state machine structure, sounds/haptics, VoiceOver handling

## Deferred Ideas

- Just-in-time tips during real play (rejected in favor of a single scripted pass)
