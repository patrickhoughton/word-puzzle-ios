# Phase 6: Differentiated Invalid-Word Messaging - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 06-differentiated-invalid-word-messaging
**Areas discussed:** Which reasons get a message, Message wording & tone, Duplicate feel, Precedence when several fail

---

## Which reasons get a message

| Option | Description | Selected |
|--------|-------------|----------|
| 4 messages | Too short / Missing center letter / Already found / Not in word list (outside letter folded in) | ✓ |
| 5 messages | Adds a separate bad-letter message (can't happen with current input) | |
| 3 messages (as roadmap) | Missing center letter also shows "Not a word" | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, enum reason | `SubmissionOutcome.rejected(reason:)`, testable per reason | ✓ |
| You decide | | |

## Message wording & tone

| Option | Description | Selected |
|--------|-------------|----------|
| Short & plain | Too short / Missing center letter / Already found / Not in word list | |
| Explains the rule | Words need 4+ letters / Must use the center letter / ... | |
| Playful | Too tiny! / Forgot the middle! / Got that one already / Hmm, not a word | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, show the letter | "Missing center letter R" | |
| No, fixed text | Center tile already highlighted on screen | ✓ |

## Duplicate feel

| Option | Description | Selected |
|--------|-------------|----------|
| Gentler | No shake, single light haptic, no reject sound, neutral color | ✓ |
| Same as other rejections | Only text differs | |
| Partly softened | Keep shake + sound, lighter haptic, neutral color | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep other three as-is | Only text changes | ✓ |
| Soften "too short" too | | |

## Precedence when several fail

| Option | Description | Selected |
|--------|-------------|----------|
| Rule order | Too short → missing center → not a word (matches existing guard order) | ✓ |
| Center letter first | | |
| You decide | | |

## Claude's Discretion

- Enum/case naming, counter/trigger structure for the duplicate path, neutral color token, light haptic choice, display duration, VoiceOver announcement.

## Deferred Ideas

- 999.10 rejected-word logging can reuse the reason enum later.
