# Phase 10: Double-Tap Shuffle - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 10-double-tap-shuffle
**Areas discussed:** What counts as empty, Shuffle button fate, Feedback on gesture, Edge states

---

## What counts as empty

| Question | Options | Selected |
|----------|---------|----------|
| Gaps/corners inside grid square? | Yes, gaps count / No, outside grid only | Yes, gaps count |
| Word display area? | Exclude / Include | Exclude |
| Spacers / top padding / margins? | All counts / Only near grid | All counts |

## Shuffle button fate

| Question | Options | Selected |
|----------|---------|----------|
| Button with gesture? | Keep unchanged / Remove / Keep + hint | Keep unchanged |
| VoiceOver custom action? | Button is enough / Add custom action | Button is enough |

## Feedback on gesture

| Question | Options | Selected |
|----------|---------|----------|
| Haptic? | Light haptic both paths / Gesture only / Animation only | Light haptic both paths |
| Sound? | No sound / Subtle whoosh | No sound |

## Edge states

| Question | Options | Selected |
|----------|---------|----------|
| When active? | Only .playing / Also roundOver | Only .playing |
| In-progress word? | Keep / Clear | Keep |
| During celebration? | Yes, same as button / Block | Yes |

## Claude's Discretion

- Gesture composition approach, tile-then-gap tap handling, haptic weight, test strategy.

## Deferred Ideas

- One-time "double-tap to shuffle" hint → Phase 12.
