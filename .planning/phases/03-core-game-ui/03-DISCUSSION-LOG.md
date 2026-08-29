# Phase 3: Core Game UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-29
**Phase:** 3-core-game-ui
**Areas discussed:** Letter grid & interaction, Word input & submission, Feedback & scoring display, Round structure & missed-word reveal

---

## Letter Grid & Interaction

### Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Honeycomb hex grid | Center hex visually distinguished, 6 hexes around it — matches NYT Spelling Bee look and CLAUDE.md's stack recommendation | ✓ |
| Circle of letter buttons | Simpler circular buttons instead of hex shapes | |

**User's choice:** Honeycomb hex grid (recommended option).

### Input method

| Option | Description | Selected |
|--------|-------------|----------|
| Tap only | Tap letters in sequence to append to the current word | |
| Tap + swipe/drag | Support both tapping and NYT-style drag-to-connect across letters | ✓ |

**User's choice:** Tap + swipe/drag — chosen despite the flagged extra gesture-handling complexity for a first iOS project.

### Shuffle

| Option | Description | Selected |
|--------|-------------|----------|
| Animated shuffle | Tapping Shuffle animates the 6 outer letters into new random positions | ✓ |
| Instant shuffle | Positions update immediately with no animation | |

**User's choice:** Animated shuffle (recommended option).

---

## Word Input & Submission

### Word display position

| Option | Description | Selected |
|--------|-------------|----------|
| Above the grid | Large text display directly above the hex grid | ✓ |
| Below the grid | Between the grid and a row of action buttons | |

**User's choice:** Above the grid (recommended option).

### Delete/clear

| Option | Description | Selected |
|--------|-------------|----------|
| Delete button + tap word to clear | Backspace button removes last letter; tapping the word clears it entirely | ✓ |
| Delete button only | Single backspace button, hold/repeat to clear | |

**User's choice:** Delete button + tap word to clear (recommended option).

### Submission method

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit Submit/Enter button | Dedicated button confirms submission | |
| Auto-submit on max length/pause | Word submits automatically without a button | |
| *(free text)* Two-finger pinch gesture | User's initial custom proposal | superseded |
| *(free text)* Swipe/drag word downward | User's revised choice after discussion | ✓ |

**User's choice:** Free text, in two steps. First proposed "two finger gesture pinch" to submit. Claude asked for clarification (whether pinch was the only path, one-handed play concern). User then replaced it entirely: "what if the user just pulls the word down to submit." Final locked decision: swipe/drag the assembled word downward submits it; no Submit button exists.
**Notes:** This was the one area where the user rejected both offered options in favor of a custom gesture, iterating on it live.

---

## Feedback & Scoring Display

### Invalid word feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Shake + generic message | Shake animation + generic "Not a valid word" | ✓ |
| Shake + specific reasons | Distinguishes "Already found"/"Too short"/"Missing center letter"/"Not in word list" | |

**User's choice:** Shake + generic message (recommended option). Specific reasons explicitly deferred, not dropped — see CONTEXT.md deferred section.

### Valid word feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Brief highlight/pop + points earned | Word display flashes/scales and shows "+N", then clears | ✓ |
| Silent | No visual flourish beyond haptic | |

**User's choice:** Brief highlight/pop + points earned (recommended option).

### Score/progress display

| Option | Description | Selected |
|--------|-------------|----------|
| Plain numeric score + found-word count | Simple Text display | |
| Rank/tier system (Beginner → Genius) | NYT-style progress bar with named rank thresholds | ✓ |

**User's choice:** Rank/tier system.
**Follow-up:** Claude asked whether to use NYT's standard tier names/thresholds (Beginner 0%, Good Start 2%, Moving Up 5%, Good 8%, Solid 15%, Nice 25%, Great 40%, Amazing 50%, Genius 70%, Queen/King Bee 100%) vs. a simpler 4-5 tier version. User selected the standard NYT tiers (recommended option).

---

## Round Structure & Missed-Word Reveal

### Round end trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Manual "Finish" button | User taps Finish/End Round whenever they choose | ✓ |
| Auto-end when all words found | Round ends automatically on 100% completion, still needing a manual fallback | |

**User's choice:** Manual "Finish" button (recommended option).

### Missed-words screen content

| Option | Description | Selected |
|--------|-------------|----------|
| Simple list of missed words | Plain scrollable list plus final score | |
| Grouped by length, pangrams highlighted | Missed words grouped by word length with missed pangrams called out | ✓ |

**User's choice:** Grouped by length, with pangrams highlighted.

### Post-round flow

| Option | Description | Selected |
|--------|-------------|----------|
| New puzzle starts immediately | "New Puzzle"/"Play Again" generates a fresh puzzle and returns to gameplay | ✓ |
| Return to a start/menu screen | User lands on a separate start screen | |

**User's choice:** New puzzle starts immediately (recommended option).

---

## Claude's Discretion

- Exact hex tile sizing/spacing and color palette for center vs. outer letters
- Exact wording of the "+N" points popup and the generic invalid-word message
- Swipe-down gesture distance/velocity threshold, and any "armed to submit" visual cue
- Whether `persistenceStore.record()` is called before or after the missed-words screen renders
- Whether `UITextChecker` is actually needed in Phase 3 given the ENABLE word list already excludes proper nouns
- `GameViewModel` structure and state ownership (following CLAUDE.md's MVVM + `@Observable` pattern)

## Deferred Ideas

- Per-reason invalid-word messaging ("already found", "too short", "missing center letter", "not in word list") — considered during the invalid-word-feedback discussion, deferred past Phase 3 rather than dropped.
